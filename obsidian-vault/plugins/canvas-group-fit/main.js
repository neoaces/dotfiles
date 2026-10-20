const { Plugin, setIcon, setTooltip } = require("obsidian");

const GRID = 20; // canvas grid spacing at normal zoom
const PADDING = 20; // space between the cards and the group's edge, same as Obsidian's "Create group"
const CORNER_HIT = 14; // screen px around a group corner that counts as the resize corner

const floorGrid = (v) => Math.floor(v / GRID) * GRID;
const ceilGrid = (v) => Math.ceil(v / GRID) * GRID;
const isGroup = (node) => node?.nodeEl?.hasClass("canvas-node-group");

module.exports = class CanvasGroupFit extends Plugin {
  onload() {
    this.patched = new Map(); // canvas.menu -> original render

    // Toolbar button above a selected group.
    const patchAll = () => {
      for (const leaf of this.app.workspace.getLeavesOfType("canvas")) {
        const canvas = leaf.view?.canvas;
        if (canvas) this.patchMenu(canvas);
      }
    };
    this.app.workspace.onLayoutReady(patchAll);
    this.registerEvent(this.app.workspace.on("layout-change", patchAll));
    this.registerEvent(this.app.workspace.on("active-leaf-change", patchAll));

    // Right-click menu on a group.
    this.registerEvent(
      this.app.workspace.on("canvas:node-menu", (menu, node) => {
        if (!isGroup(node) || node.canvas.readonly) return;
        menu.addItem((item) =>
          item
            .setTitle("Fit group to contents")
            .setIcon("shrink")
            .onClick(() => this.fit(node.canvas, node))
        );
      })
    );

    this.addCommand({
      id: "fit-selected-groups",
      name: "Fit selected groups to contents",
      checkCallback: (checking) => {
        const canvas = this.activeCanvas();
        const groups = canvas ? Array.from(canvas.selection).filter(isGroup) : [];
        if (groups.length === 0 || canvas.readonly) return false;
        if (!checking) this.fitAll(canvas, groups);
        return true;
      },
    });

    // Double-click a group's corner. Matched by position, because Obsidian captures the
    // pointer on the resize handle and the double-click lands on another element.
    this.registerDomEvent(
      document,
      "dblclick",
      (evt) => {
        const canvas = this.canvasAt(evt);
        if (!canvas || canvas.readonly) return;
        const group = this.groupCornerAt(canvas, evt);
        if (!group) return;
        evt.preventDefault();
        evt.stopPropagation();
        this.fit(canvas, group);
      },
      true
    );
  }

  onunload() {
    for (const [menu, render] of this.patched) menu.render = render;
    this.patched.clear();
  }

  activeCanvas() {
    const view = this.app.workspace.activeLeaf?.view;
    return view?.getViewType?.() === "canvas" ? view.canvas : null;
  }

  canvasAt(evt) {
    if (!(evt.target instanceof Element)) return null;
    for (const leaf of this.app.workspace.getLeavesOfType("canvas")) {
      const canvas = leaf.view?.canvas;
      if (canvas?.wrapperEl?.contains(evt.target)) return canvas;
    }
    return null;
  }

  groupCornerAt(canvas, evt) {
    const pos = canvas.posFromEvt(evt);
    const r = CORNER_HIT / (canvas.scale || 1);
    for (const node of canvas.nodes.values()) {
      if (!isGroup(node)) continue;
      const corners = [
        [node.x, node.y],
        [node.x + node.width, node.y],
        [node.x, node.y + node.height],
        [node.x + node.width, node.y + node.height],
      ];
      if (corners.some(([cx, cy]) => Math.abs(pos.x - cx) <= r && Math.abs(pos.y - cy) <= r)) return node;
    }
    return null;
  }

  patchMenu(canvas) {
    const menu = canvas.menu;
    if (!menu || this.patched.has(menu)) return;
    const render = menu.render;
    this.patched.set(menu, render);
    const plugin = this;
    menu.render = function (rebuild, ...rest) {
      const r = render.call(this, rebuild, ...rest);
      if (rebuild) plugin.addButton(canvas, this.menuEl);
      return r;
    };
  }

  addButton(canvas, menuEl) {
    if (canvas.readonly || !menuEl || menuEl.querySelector(".neo-group-fit")) return;
    const groups = Array.from(canvas.selection).filter(isGroup);
    if (groups.length === 0) return;
    const btn = menuEl.createEl("button", { cls: "clickable-icon neo-group-fit" });
    setIcon(btn, "shrink");
    setTooltip(btn, "Fit group to contents", { placement: "top" });
    btn.addEventListener("click", () => this.fitAll(canvas, groups));
  }

  fitAll(canvas, groups) {
    for (const group of groups) this.fit(canvas, group, false);
    canvas.requestSave();
  }

  fit(canvas, group, save = true) {
    // A card belongs to the group if its centre is inside it, so cards hanging over the edge are pulled in too.
    const inside = Array.from(canvas.nodes.values()).filter((n) => {
      if (n === group) return false;
      const cx = n.x + n.width / 2;
      const cy = n.y + n.height / 2;
      return cx >= group.x && cx <= group.x + group.width && cy >= group.y && cy <= group.y + group.height;
    });
    if (inside.length === 0) return;

    const minX = Math.min(...inside.map((n) => n.x)) - PADDING;
    const minY = Math.min(...inside.map((n) => n.y)) - PADDING;
    const maxX = Math.max(...inside.map((n) => n.x + n.width)) + PADDING;
    const maxY = Math.max(...inside.map((n) => n.y + n.height)) + PADDING;

    const snap = canvas.options?.snapToGrid;
    const x = snap ? floorGrid(minX) : minX;
    const y = snap ? floorGrid(minY) : minY;
    const right = snap ? ceilGrid(maxX) : maxX;
    const bottom = snap ? ceilGrid(maxY) : maxY;

    group.moveAndResize({ x, y, width: right - x, height: bottom - y });
    if (save) canvas.requestSave();
  }
};
