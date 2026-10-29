const { Plugin, MarkdownView } = require("obsidian");

// Folds the headings of a note with `fold: <level>` in its frontmatter whenever
// it's opened into a pane: `fold: 2` folds every H2 and deeper, `fold: 1` all. Switching back to a tab that already shows the note
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
      const level = cache?.frontmatter?.fold;
      if (!Number.isInteger(level) || !cache.headings?.length) return;

      // After Obsidian restores the folds it saved for the note.
      window.setTimeout(() => {
        if (view.file !== file) return;
        const lines = view.data.split("\n").length;
        const headings = cache.headings;
        const folds = headings.flatMap((h, i) => {
          if (h.level < level) return [];
          const next = headings.slice(i + 1).find((n) => n.level <= h.level);
          return [{ from: h.position.start.line, to: next ? next.position.start.line - 1 : lines - 1 }];
        });
        view.currentMode.applyFoldInfo({ folds, lines });
        view.onMarkdownFold?.();
      }, 50);
    }));
  }
};
