// Claude plan usage from Anthropic's rate-limit response headers.
// Writes ~/.cache/claude-usage ("5h_used 5h_reset 7d_used 7d_reset", shared with
// tmux/claude-usage.sh and ~/.claude/statusline.sh) and shows "5h N% · 7d N%" in the footer.
import { readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";

const CACHE = `${homedir()}/.cache/claude-usage`;
const H = "anthropic-ratelimit-unified-";
let last = "";

function show(ctx: any, line: string) {
  const [fu, fr, su, sr] = line.trim().split(" ").map(Number);
  if (!sr) return;
  const now = Date.now() / 1000;
  const text = `5h ${fr > now ? fu : 0}% · 7d ${sr > now ? su : 0}%`;
  ctx.ui.setStatus("claude-usage", ctx.ui.theme.fg("dim", text));
}

export default function (pi: any) {
  pi.on("session_start", (_e: any, ctx: any) => {
    try { show(ctx, (last = readFileSync(CACHE, "utf8").trim())); } catch {}
  });

  pi.on("after_provider_response", (e: any, ctx: any) => {
    const h = e.headers ?? {};
    const fu = h[`${H}5h-utilization`], su = h[`${H}7d-utilization`];
    if (fu == null || su == null) return; // not Anthropic subscription auth
    const line = `${Math.round(fu * 100)} ${h[`${H}5h-reset`]} ${Math.round(su * 100)} ${h[`${H}7d-reset`]}`;
    if (line === last) return;
    last = line;
    try { writeFileSync(CACHE, line + "\n"); } catch {}
    show(ctx, line);
  });
}
