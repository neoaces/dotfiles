// Feeds pi sessions into ponytail's board (~/.config/ponytail/band): one row per session in
// pi-sessions.csv, refreshed after every run. /ponytail-board imports every session and opens the board.
import { spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { basename, dirname, join } from "node:path";

const HOME = homedir();
const AGENT = process.env.PI_CODING_AGENT_DIR || join(HOME, ".pi/agent");
const ROOT = process.env.PI_CODING_AGENT_SESSION_DIR || join(AGENT, "sessions");
const BAND = join(process.env.XDG_CONFIG_HOME || join(HOME, ".config"), "ponytail/band");
const BOARD = join(BAND, "board.html");
// The board and CSV code ship with ponytail; reusing it keeps rows identical to the Claude band's.
const PT = join(AGENT, "npm/node_modules/@dietrichgebert/ponytail/hooks/band");
const IDLE_MS = 30 * 60000; // same cap as ponytail's import: a longer pause is nobody answering

let pt: any;
const load = async () => (pt ??= { ...(await import(join(PT, "board.ts"))), ...(await import(join(PT, "metrics.ts"))) });

const read = (file: string): any[] =>
  readFileSync(file, "utf8").split("\n").flatMap((l) => { try { return l ? [JSON.parse(l)] : []; } catch { return []; } });
const text = (c: any): string =>
  (typeof c === "string" ? c : Array.isArray(c) ? c.filter((b) => b?.type === "text").map((b) => b.text).join("\n") : "").trim();

// pi-subagents runs live under <session>/…/*.jsonl; their usage belongs to the parent row.
const children = (file: string) => {
  const dir = file.slice(0, -".jsonl".length);
  try { return readdirSync(dir, { recursive: true }).map(String).filter((f) => f.endsWith(".jsonl")).map((f) => join(dir, f)); } catch { return []; }
};

// pi-ultracode runs: <dir>/ultracode-runs/session-<sha256(id)[:32]>/<run>.details.json, usage per agent.
const ultracode = (file: string, id: string): any[] => {
  const dir = join(dirname(file), "ultracode-runs", `session-${createHash("sha256").update(id).digest("hex").slice(0, 32)}`);
  let runs: string[] = [];
  try { runs = readdirSync(dir).filter((f) => f.endsWith(".details.json")); } catch {}
  return runs.flatMap((f) => { try { return JSON.parse(readFileSync(join(dir, f), "utf8")).snapshot?.agents ?? []; } catch { return []; } })
    .map((a) => a.usage).filter(Boolean)
    .map((u) => ({ input: u.inputTokens, output: u.outputTokens, cacheRead: u.cacheReadTokens, cacheWrite: u.cacheWriteTokens, cost: { total: u.cost } }));
};

// The main repo's name, as ponytail names Claude sessions; a deleted worktree keeps its own dir name.
const projects = new Map<string, string>();
function projectOf(cwd: string): string {
  if (!projects.has(cwd)) {
    let name: string;
    if (existsSync(cwd)) {
      const git = spawnSync("git", ["-C", cwd, "rev-parse", "--path-format=absolute", "--git-common-dir"], { encoding: "utf8" });
      const common = git.status === 0 ? git.stdout.trim() : "";
      name = /[\\/]\.git$/.test(common) ? basename(dirname(common)) : basename(cwd);
    } else {
      let d = cwd;
      while (!existsSync(dirname(d))) d = dirname(d);
      name = basename(d);
    }
    projects.set(cwd, name);
  }
  return projects.get(cwd)!;
}

// One session as ponytail's Snapshot, or null for one nobody worked in.
function stats(file: string) {
  const entries = read(file);
  const head = entries[0];
  if (head?.type !== "session" || !head.cwd || head.cwd.startsWith(tmpdir()) || head.cwd.startsWith("/tmp")) return null;

  const tokens = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 };
  let cost = 0;
  const add = (u: any) => {
    tokens.input += u.input || 0;
    tokens.output += u.output || 0;
    tokens.cacheRead += u.cacheRead || 0;
    tokens.cacheWrite += u.cacheWrite || 0;
    cost += u.cost?.total || 0;
  };
  for (const f of [file, ...children(file)]) {
    for (const e of f === file ? entries : read(f)) {
      // Assistant replies, plus usage/compaction/branch_summary entries that carry their own usage.
      const u = e.type === "message" ? (e.message?.role === "assistant" ? e.message.usage : undefined) : e.usage;
      if (u) add(u);
    }
  }
  ultracode(file, head.id).forEach(add);

  // A turn runs from a prompt to the last reply or tool result before the next prompt.
  let turns = 0, agentMs = 0, prev = NaN, worked = false, name = "", first = "", level = "", tests = "";
  const models: Record<string, number> = {};
  const testCalls = new Set<string>();
  for (const e of entries) {
    const m = e.type === "message" ? e.message : undefined;
    const role = e.type === "custom_message" ? "user" : m?.role;
    const t = Date.parse(e.timestamp);
    if (e.type === "session_info" && e.name) name = e.name;
    if (e.type === "custom" && e.customType === "ponytail-mode" && e.data?.mode) level = e.data.mode;
    if (role === "user") {
      if (worked) turns++;
      worked = false;
      prev = t;
      const p = e.type === "message" ? text(m.content) : "";
      if (!first && p && !p.startsWith("/") && !p.startsWith("<")) first = p;
    } else if (role === "assistant" || role === "toolResult") {
      if (t > prev && t - prev <= IDLE_MS) agentMs += t - prev;
      if (t > prev) prev = t;
    }
    if (role === "assistant") {
      worked = true;
      if (m.model) models[m.model] = (models[m.model] || 0) + 1;
      for (const b of Array.isArray(m.content) ? m.content : []) {
        if (b?.type !== "toolCall") continue;
        if (b.name === "bash" && pt.isTestCommand(String(b.arguments?.command ?? ""))) testCalls.add(b.id);
        else if ((b.name === "edit" || b.name === "write") && tests && pt.isCode(String(b.arguments?.path ?? ""))) tests = "stale";
      }
    }
    if (role === "toolResult" && testCalls.has(m.toolCallId)) {
      const c = pt.testCounts(text(m.content));
      tests = (m.isError ? `${c.failed ?? ""} failed` : `${c.passed ?? ""} passed`).trim();
    }
  }
  if (worked) turns++;
  if (turns === 0) return null;

  const started = Date.parse(head.timestamp);
  return {
    key: pt.taskKey(head.id, started),
    started: pt.stamp(started),
    project: projectOf(head.cwd),
    name: (name || first.split("\n")[0]).slice(0, 60),
    session: head.id,
    level,
    model: Object.keys(models).sort((a, b) => models[b] - models[a])[0] ?? "",
    cost,
    lastTurn: null,
    turns,
    agentMs,
    tokens,
    reuse: null,
    reused: 0,
    created: 0,
    callersOpen: 0,
    tests,
  };
}

// Upserts the rows into pi-sessions.csv (its own file, so it never races the Claude band's), then rebuilds the board.
function save(rows: any[]) {
  mkdirSync(BAND, { recursive: true });
  const ledger = join(BAND, "pi-sessions.csv");
  let csv = "";
  try { csv = readFileSync(ledger, "utf8"); } catch {}
  for (const r of rows) csv = pt.upsertCsv(csv, r);
  writeFileSync(ledger, csv);
  const texts = readdirSync(BAND).filter((f) => f.endsWith(".csv")).map((f) => readFileSync(join(BAND, f), "utf8"));
  writeFileSync(BOARD, pt.boardHtml(texts.flatMap(pt.tasksFrom), Date.now()));
}

const allSessions = () =>
  readdirSync(ROOT).flatMap((d) => { try { return readdirSync(join(ROOT, d)).filter((f) => f.endsWith(".jsonl")).map((f) => join(ROOT, d, f)); } catch { return []; } });

export default function (pi: any) {
  pi.on("agent_end", async (_e: any, ctx: any) => {
    const file = ctx.sessionManager.getSessionFile();
    // Only top-level sessions (sessions/--cwd--/x.jsonl); subagent runs count toward their parent.
    if (!file || !/^--.*--$/.test(basename(dirname(file)))) return;
    try {
      await load();
      const row = stats(file);
      if (row) save([row]);
    } catch (err: any) {
      ctx.ui.notify(`ponytail board: ${err.message}`, "warning");
    }
  });

  pi.registerCommand("ponytail-board", {
    description: "Import all pi sessions into ponytail's board and open it",
    handler: async (_args: string, ctx: any) => {
      await load();
      const rows = allSessions().map(stats).filter(Boolean);
      save(rows);
      const open = process.platform === "darwin" ? "open" : process.env.DISPLAY || process.env.WAYLAND_DISPLAY ? "xdg-open" : "";
      if (open) spawn(open, [BOARD], { detached: true, stdio: "ignore" }).on("error", () => {}).unref();
      ctx.ui.notify(`ponytail board: ${rows.length} pi sessions → ${BOARD}`, "info");
    },
  });
}
