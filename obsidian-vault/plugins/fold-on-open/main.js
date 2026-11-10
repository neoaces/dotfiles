const { Plugin, MarkdownView } = require("obsidian");

// Folds the headings of a note with `fold: <level>` in its frontmatter whenever
// it's opened into a pane: `fold: 2` folds every H2 and deeper, `fold: 1` all.
// With `daily: true` too, the first of those headings (the newest day) stays
// open, and the cursor goes to the end of its last line, ready to type.
// The note's properties get folded too, and it's scrolled to the very top,
// staying there while blocks that render late (e.g. a Tasks query) grow.
// Switching back to a tab that already shows the note leaves its folds (and
// cursor) alone. Lists stay unfolded.
module.exports = class FoldOnOpen extends Plugin {
  onload() {
    const shown = new WeakMap(); // leaf → path it last opened

    this.registerEvent(this.app.workspace.on("file-open", (file) => {
      const view = this.app.workspace.getActiveViewOfType(MarkdownView);
      if (!file || view?.file !== file) return;
      if (shown.get(view.leaf) === file.path) return;
      shown.set(view.leaf, file.path);

      const cache = this.app.metadataCache.getFileCache(file);
      const level = cache?.frontmatter?.fold;
      if (!Number.isInteger(level) || !cache.headings?.length) return;

      // After Obsidian restores the folds it saved for the note.
      window.setTimeout(() => {
        if (view.file !== file) return;
        const lines = view.data.split("\n").length;
        const headings = cache.headings;
        let open = null; // the heading section left unfolded, if any
        let folds = headings.flatMap((h, i) => {
          if (h.level < level) return [];
          const next = headings.slice(i + 1).find((n) => n.level <= h.level);
          return [{ from: h.position.start.line, to: next ? next.position.start.line - 1 : lines - 1 }];
        });
        if (cache.frontmatter.daily === true && folds.length) {
          // A daily log keeps its newest entry open, along with everything in it.
          open = folds[0];
          folds = folds.filter((f) => f.from > open.to);
        }
        view.currentMode.applyFoldInfo({ folds, lines });
        view.onMarkdownFold?.();

        if (open) {
          // End of the section's last non-blank line (the heading itself if it's empty).
          const editor = view.editor;
          let line = open.to;
          while (line > open.from && !editor.getLine(line).trim()) line--;
          const pos = { line, ch: editor.getLine(line).length };
          editor.setCursor(pos);
        }
        view.metadataEditor?.setCollapse?.(true);
        pinToTop(view);
      }, 50);
    }));
  }
};

// Keep the note scrolled to the top while its content settles. CodeMirror holds
// its scroll anchor steady when something above it changes height, so a Tasks
// block that renders late would push the top of the note out of view. The pin
// lets go as soon as you scroll, click, type or touch, or after PIN_MS.
const PIN_MS = 10000;
const USER_INPUT = ["wheel", "pointerdown", "keydown", "touchstart"];

function pinToTop(view) {
  const cm = view.editor?.cm;
  const scroller = cm?.scrollDOM;
  if (!scroller) return view.editor?.scrollTo(null, 0);

  const toTop = () => {
    if (scroller.scrollTop !== 0) scroller.scrollTop = 0;
  };
  const resized = new ResizeObserver(toTop);
  const release = () => {
    window.clearTimeout(timer);
    resized.disconnect();
    scroller.removeEventListener("scroll", toTop);
    for (const type of USER_INPUT) window.removeEventListener(type, release, true);
  };

  resized.observe(cm.contentDOM);
  scroller.addEventListener("scroll", toTop);
  for (const type of USER_INPUT) window.addEventListener(type, release, { capture: true, passive: true });
  const timer = window.setTimeout(release, PIN_MS);
  toTop();
}
