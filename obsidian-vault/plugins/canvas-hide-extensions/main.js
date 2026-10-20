const { Plugin } = require("obsidian");

const SELECTOR = ".canvas-node-label";

function strip(el) {
  const text = el.textContent;
  const stripped = text.replace(/\.[^./\\]+$/, "");
  if (stripped && stripped !== text) el.textContent = stripped;
}

module.exports = class CanvasHideExtensions extends Plugin {
  onload() {
    const scan = (root) => {
      if (root.matches?.(SELECTOR)) strip(root);
      root.querySelectorAll?.(SELECTOR).forEach(strip);
    };
    this.observer = new MutationObserver((mutations) => {
      for (const m of mutations) {
        if (m.type === "characterData") {
          const label = m.target.parentElement?.closest(SELECTOR);
          if (label) strip(label);
        }
        m.addedNodes.forEach((n) => {
          if (n.nodeType === 1) scan(n);
          else if (n.parentElement?.closest(SELECTOR)) strip(n.parentElement.closest(SELECTOR));
        });
      }
    });
    this.observer.observe(document.body, { childList: true, subtree: true, characterData: true });
    scan(document.body);
  }

  onunload() {
    this.observer?.disconnect();
  }
};
