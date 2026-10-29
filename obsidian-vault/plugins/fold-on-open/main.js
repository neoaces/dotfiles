const { Plugin, MarkdownView } = require("obsidian");

// Folds every heading of a note with `fold: true` in its frontmatter whenever
// it's opened into a pane. Switching back to a tab that already shows the note
// leaves its folds alone. Lists stay unfolded.
module.exports = class FoldOnOpen extends Plugin {
  onload() {
    const shown = new WeakMap(); // leaf → path it last opened

    this.registerEvent(this.app.workspace.on("file-open", (file) => {
      const view = this.app.workspace.getActiveViewOfType(MarkdownView);
      if (!file || view?.file !== file) return;
      if (shown.get(view.leaf) === file.path) return;
      shown.set(view.leaf, file.path);

      const cache = this.app.metadataCache.getFileCache(file);
      if (cache?.frontmatter?.fold !== true || !cache.headings?.length) return;

      // After Obsidian restores the folds it saved for the note.
      window.setTimeout(() => {
        if (view.file !== file) return;
        const lines = view.data.split("\n").length;
        const headings = cache.headings;
        const folds = headings.map((h, i) => {
          const next = headings.slice(i + 1).find((n) => n.level <= h.level);
          return { from: h.position.start.line, to: next ? next.position.start.line - 1 : lines - 1 };
        });
        view.currentMode.applyFoldInfo({ folds, lines });
        view.onMarkdownFold?.();
      }, 50);
    }));
  }
};
