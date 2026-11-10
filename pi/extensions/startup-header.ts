// Replaces pi's startup header: same logo + key hints, minus the "Press ctrl+o..." and
// "Pi can explain its own features..." lines, plus a [Custom Extensions] section listing
// the local extensions in this directory (npm/git package extensions stay under [Extensions]).
import { existsSync, readdirSync } from "node:fs";
import { getAgentDir, keyHint, keyText, rawKeyHint, VERSION } from "@earendil-works/pi-coding-agent";
import { backgroundAnsi, foregroundAnsi, isAppleTerminalSession, rgbColor } from "@earendil-works/pi-tui";

// Brand colors copied from pi's pi-logo.js (not exported)
const CORAL = rgbColor(228, 138, 122), BLUE = rgbColor(79, 142, 179), YELLOW = rgbColor(234, 182, 93);
const RESET = "\x1b[0m";

function customExtensions(): string[] {
  try {
    const dir = `${getAgentDir()}/extensions`;
    // Skip config-only dirs (e.g. pi-permission-system/config.json): pi loads a dir only with an entry point
    const isExt = (n: string) => ["index.ts", "index.js", "package.json"].some((f) => existsSync(`${dir}/${n}/${f}`));
    return readdirSync(dir, { withFileTypes: true })
      .filter((e) => (e.isDirectory() && isExt(e.name)) || /\.[jt]s$/.test(e.name))
      .map((e) => e.name.replace(/\.[jt]s$/, ""))
      .sort();
  } catch {
    return [];
  }
}

export default function (pi: any) {
  pi.on("session_start", (_e: any, ctx: any) => {
    if (ctx.mode !== "tui") return;
    const exts = customExtensions();
    ctx.ui.setHeader((_tui: any, theme: any) => ({
      invalidate() {},
      render(): string[] {
        const mode = theme.getColorMode();
        const fg = (c: any) => foregroundAnsi(c, mode);
        const hints = [
          keyHint("app.interrupt", "interrupt"),
          rawKeyHint(`${keyText("app.clear")}/${keyText("app.exit")}`, "clear/exit"),
          rawKeyHint("/", "commands"),
          rawKeyHint("!", "bash"),
          keyHint("app.tools.expand", "more"),
        ].join(theme.fg("muted", " · "));
        const version = theme.fg("dim", `v${VERSION}`);
        const lines = isAppleTerminalSession()
          ? [`${fg(CORAL)}P${RESET}${fg(YELLOW)}i${RESET} ${version}`, hints]
          : [
              `${fg(CORAL)}${backgroundAnsi(BLUE, mode)}▀${RESET}${fg(CORAL)}▀█${RESET}  ${version}`,
              `${fg(BLUE)}█▀${RESET} ${fg(YELLOW)}█${RESET} ${hints}`,
            ];
        if (exts.length) lines.push("", theme.fg("mdHeading", "[Custom Extensions]"), theme.fg("dim", `  ${exts.join(", ")}`));
        return lines;
      },
    }));
  });
}
