const { Plugin, Notice } = require("obsidian");

const GRID = 20; // canvas grid spacing at normal zoom
const LINK_KEY = "captionFor"; // stored on the caption node in the .canvas file
const IMAGE_EXT = new Set(["png", "jpg", "jpeg", "gif", "bmp", "svg", "webp", "avif"]);

const snapUp = (v) => Math.max(GRID, Math.round(v / GRID) * GRID);
const snapTo = (v) => Math.round(v / GRID) * GRID;
const isImage = (node) => !!node?.file && IMAGE_EXT.has(node.file.extension?.toLowerCase());

module.exports = class CanvasImageCaptions extends Plugin {
  onload() {
    this.patched = new Map(); // canvas -> { markMoved, setData, removeNode }
    this.lastRect = new WeakMap(); // node -> rect seen last time we touched it
    this.busy = false;

    this.addCommand({
      id: "add-caption",
      name: "Add note below selected image",
      checkCallback: (checking) => {
        const canvas = this.activeCanvas();
        const sel = canvas ? Array.from(canvas.selection) : [];
        const node = sel.length === 1 ? sel[0] : null;
        if (!isImage(node) || this.captionOf(canvas, node)) return false;
        if (!checking) this.addCaption(canvas, node);
        return true;
      },
    });

    this.registerEvent(
      this.app.workspace.on("canvas:node-menu", (menu, node) => {
        if (!isImage(node) || this.captionOf(node.canvas, node)) return;
        menu.addItem((item) =>
          item
            .setTitle("Add note below image")
            .setIcon("captions")
            .onClick(() => this.addCaption(node.canvas, node))
        );
      })
    );

    // Double-click an image: add its note, or jump into the note it already has.
    this.registerDomEvent(
      document,
      "dblclick",
      (evt) => {
        const target = evt.target;
        if (!(target instanceof Element) || !target.closest(".canvas-node")) return;
        for (const canvas of this.patched.keys()) {
          if (canvas.readonly) continue;
          const node = Array.from(canvas.nodes.values()).find((n) => n.nodeEl.contains(target));
          if (!isImage(node)) continue;
          evt.preventDefault();
          evt.stopPropagation();
          const caption = this.captionOf(canvas, node);
          if (caption) {
            canvas.selectOnly(caption);
            caption.startEditing();
          } else {
            this.addCaption(canvas, node);
          }
          return;
        }
      },
      true
    );

    const patchAll = () => {
      for (const leaf of this.app.workspace.getLeavesOfType("canvas")) {
        const canvas = leaf.view?.canvas;
        if (canvas) this.patch(canvas);
      }
    };
    this.app.workspace.onLayoutReady(patchAll);
    this.registerEvent(this.app.workspace.on("layout-change", patchAll));
    this.registerEvent(this.app.workspace.on("active-leaf-change", patchAll));
  }

  onunload() {
    for (const [canvas, orig] of this.patched) {
      Object.assign(canvas, orig);
      for (const node of canvas.nodes.values()) {
        node.nodeEl.removeClass("neo-captioned-image", "neo-caption");
      }
    }
    this.patched.clear();
  }

  activeCanvas() {
    const view = this.app.workspace.activeLeaf?.view;
    return view?.getViewType?.() === "canvas" ? view.canvas : null;
  }

  patch(canvas) {
    if (this.patched.has(canvas)) return;
    const orig = {
      markMoved: canvas.markMoved,
      setData: canvas.setData,
      removeNode: canvas.removeNode,
    };
    this.patched.set(canvas, orig);
    const plugin = this;
    canvas.markMoved = function (node) {
      orig.markMoved.call(this, node);
      plugin.onMoved(this, node);
    };
    canvas.setData = function (...args) {
      const r = orig.setData.apply(this, args);
      plugin.refresh(this);
      return r;
    };
    canvas.removeNode = function (node) {
      const r = orig.removeNode.call(this, node);
      plugin.refresh(this);
      return r;
    };
    this.refresh(canvas);
  }

  // ---- pairing -----------------------------------------------------------

  imageOf(canvas, caption) {
    const id = caption?.unknownData?.[LINK_KEY];
    const img = id && canvas.nodes.get(id);
    return isImage(img) ? img : null;
  }

  captionOf(canvas, image) {
    for (const node of canvas.nodes.values()) {
      if (node.unknownData?.[LINK_KEY] === image.id) return node;
    }
    return null;
  }

  refresh(canvas) {
    const captioned = new Set();
    for (const node of canvas.nodes.values()) {
      const img = this.imageOf(canvas, node);
      node.nodeEl.toggleClass("neo-caption", !!img);
      if (img) captioned.add(img);
    }
    for (const node of canvas.nodes.values()) {
      if (isImage(node)) node.nodeEl.toggleClass("neo-captioned-image", captioned.has(node));
    }
  }

  // ---- creating ----------------------------------------------------------

  addCaption(canvas, image) {
    // Put the image's bottom edge on a grid line so the note's cells line up.
    const bottom = snapTo(image.y + image.height);
    if (bottom - image.y >= GRID) {
      image.moveAndResize({ x: image.x, y: image.y, width: image.width, height: bottom - image.y });
    }
    const caption = canvas.createTextNode({
      pos: { x: image.x, y: image.y + image.height },
      size: { width: image.width, height: 2 * GRID },
      text: "",
      save: false,
      focus: false,
    });
    caption.unknownData = { ...caption.unknownData, [LINK_KEY]: image.id };
    this.remember(image);
    this.remember(caption);
    this.refresh(canvas);
    canvas.requestSave();
    canvas.selectOnly(caption);
    caption.startEditing();
    new Notice("Note added below image");
  }

  // ---- keeping the pair together -----------------------------------------

  remember(node) {
    this.lastRect.set(node, { x: node.x, y: node.y, width: node.width, height: node.height });
  }

  set(node, rect) {
    if (node.x !== rect.x || node.y !== rect.y || node.width !== rect.width || node.height !== rect.height) {
      node.moveAndResize(rect);
    }
    this.remember(node);
  }

  onMoved(canvas, node) {
    if (this.busy) return;
    this.busy = true;
    try {
      const imgForCaption = this.imageOf(canvas, node);
      if (imgForCaption) return this.captionMoved(canvas, node, imgForCaption);
      if (isImage(node)) {
        const caption = this.captionOf(canvas, node);
        if (caption) this.imageMoved(canvas, node, caption);
      }
    } finally {
      this.busy = false;
    }
  }

  imageMoved(canvas, image, caption) {
    // Both selected: Obsidian moves them together already.
    if (canvas.selection.has(image) && canvas.selection.has(caption)) {
      this.remember(image);
      this.remember(caption);
      return;
    }
    const prev = this.lastRect.get(image);
    const resized = prev && (prev.width !== image.width || prev.height !== image.height);
    if (resized && canvas.options?.snapToGrid) {
      const h = snapTo(image.y + image.height) - image.y;
      if (h >= GRID && h !== image.height) {
        image.moveAndResize({ x: image.x, y: image.y, width: image.width, height: h });
      }
    }
    this.remember(image);
    this.set(caption, {
      x: image.x,
      y: image.y + image.height,
      width: image.width,
      height: snapUp(caption.height),
    });
  }

  captionMoved(canvas, caption, image) {
    if (canvas.selection.has(image) && canvas.selection.has(caption)) {
      this.remember(image);
      this.remember(caption);
      return;
    }
    const prev = this.lastRect.get(caption);
    const resized = !prev || prev.width !== caption.width || prev.height !== caption.height;
    if (resized) {
      // Note is being resized: keep it under the image, height in whole grid steps.
      const top = image.y + image.height;
      this.set(caption, {
        x: image.x,
        y: top,
        width: image.width,
        height: snapUp(caption.y + caption.height - top),
      });
    } else {
      // Note was dragged on its own: bring the image along.
      this.remember(caption);
      this.set(image, { x: caption.x, y: caption.y - image.height, width: image.width, height: image.height });
    }
  }
};
