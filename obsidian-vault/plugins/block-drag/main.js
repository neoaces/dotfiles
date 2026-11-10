const { Plugin } = require("obsidian");
const { ViewPlugin, Decoration } = require("@codemirror/view");

// Hovering a list item in the editor (Live Preview or source) shows a ⠿ handle
// beside its bullet/checkbox. Dragging the handle moves the item together with
// everything nested under it. The drop line follows the pointer: the top half
// of an item drops before it, the bottom half drops after it (or as its first
// child when it already has children). Dropping changes the moved block's
// indentation to match its new spot. Escape cancels a drag.
//
// While dragging, a copy of the block follows the pointer and the original is
// faded. The drop line glides between spots, and the moved block flashes
// briefly where it lands.

const LIST_RE = /^([ \t]*)(?:[-*+]|\d+[.)])(?:[ \t]|$)/;
const SCAN_LIMIT = 500; // lines to look upward for a line's owning item
const EDGE = 48; // px from the scroller's edge where dragging auto-scrolls
const FLASH_MS = 700; // how long a dropped block stays highlighted

const DOTS_SVG =
  '<svg viewBox="0 0 10 16" width="10" height="16" aria-hidden="true">' +
  [3, 8, 13].map((y) => `<circle cx="2.5" cy="${y}" r="1.5"/><circle cx="7.5" cy="${y}" r="1.5"/>`).join("") +
  "</svg>";

function indentWidth(str, tabSize) {
  let w = 0;
  for (const c of str) w += c === "\t" ? tabSize - (w % tabSize) : 1;
  return w;
}

function listItem(state, n) {
  const line = state.doc.line(n);
  const m = LIST_RE.exec(line.text);
  if (!m) return null;
  return { n, line, indent: m[1], width: indentWidth(m[1], state.tabSize) };
}

// Last line of the item's block: its own line plus every deeper-indented line
// after it (blank lines count only when something nested follows them).
function blockEnd(state, item) {
  const doc = state.doc;
  let end = item.n;
  for (let n = item.n + 1; n <= doc.lines; n++) {
    const text = doc.line(n).text;
    if (!text.trim()) continue;
    if (indentWidth(/^[ \t]*/.exec(text)[0], state.tabSize) <= item.width) break;
    end = n;
  }
  return end;
}

// The deepest list item whose block contains line n.
function owner(state, n) {
  for (let k = n; k >= 1 && n - k < SCAN_LIMIT; k--) {
    const item = listItem(state, k);
    if (item) {
      if (k === n || blockEnd(state, item) >= n) return item;
    } else if (k < n && /^\S/.test(state.doc.line(k).text)) {
      return null; // an unindented non-list line ends any list above it
    }
  }
  return null;
}

function reindent(text, from, to) {
  if (!text.trim()) return "";
  if (text.startsWith(from)) return to + text.slice(from.length);
  return to + text.replace(/^[ \t]*/, "");
}

class DragHandles {
  constructor(view) {
    this.view = view;
    this.hovered = null;
    this.drag = null;
    this.decorations = Decoration.none;
    this.flashTimer = 0;

    const scroller = view.scrollDOM;
    if (getComputedStyle(scroller).position === "static") scroller.style.position = "relative";

    this.handle = scroller.createDiv({ cls: "block-drag-handle" });
    this.handle.innerHTML = DOTS_SVG;
    this.indicator = scroller.createDiv({ cls: "block-drag-indicator" });

    this.onHover = this.onHover.bind(this);
    this.onLeave = () => !this.drag && this.hideHandle();
    this.onDown = this.onDown.bind(this);
    this.onMove = this.onMove.bind(this);
    this.onUp = this.onUp.bind(this);
    this.onKey = (e) => e.key === "Escape" && this.endDrag(false);
    this.stop = (e) => e.stopPropagation();

    scroller.addEventListener("mousemove", this.onHover);
    scroller.addEventListener("mouseleave", this.onLeave);
    this.handle.addEventListener("pointerdown", this.onDown);
    this.handle.addEventListener("mousedown", this.stop);
  }

  update(u) {
    if (u.docChanged) this.decorations = this.decorations.map(u.changes);
    if (!this.drag && (u.docChanged || u.geometryChanged)) this.hideHandle();
  }

  destroy() {
    this.endDrag(false);
    window.clearTimeout(this.flashTimer);
    this.view.scrollDOM.removeEventListener("mousemove", this.onHover);
    this.view.scrollDOM.removeEventListener("mouseleave", this.onLeave);
    this.handle.remove();
    this.indicator.remove();
  }

  // Client coordinates → coordinates inside the scroller's content.
  local(x, y) {
    const r = this.view.scrollDOM.getBoundingClientRect();
    return { x: x - r.left + this.view.scrollDOM.scrollLeft, y: y - r.top + this.view.scrollDOM.scrollTop };
  }

  markerCoords(item) {
    return this.view.coordsAtPos(item.line.from + item.indent.length, 1);
  }

  // ---- hover ---------------------------------------------------------------

  onHover(e) {
    if (this.drag || this.handle.contains(e.target)) return;
    const view = this.view;
    const content = view.contentDOM.getBoundingClientRect();
    if (e.clientY < content.top || e.clientY > content.bottom) return this.hideHandle();
    const pos = view.posAtCoords({ x: e.clientX, y: e.clientY }, false);
    const item = owner(view.state, view.state.doc.lineAt(pos).number);
    if (!item) return this.hideHandle();
    if (this.hovered && this.hovered.n === item.n) return;

    const c = this.markerCoords(item);
    if (!c) return this.hideHandle();
    const p = this.local(this.handleAnchor(item, c.left), (c.top + c.bottom) / 2);
    this.hovered = item;
    this.handle.style.left = `${p.x}px`;
    this.handle.style.top = `${p.y}px`;
    this.handle.addClass("is-visible");
  }

  // Where the handle's right side lines up: the bullet/checkbox, or the fold arrow
  // when the item has one (items with children), so the two don't overlap.
  handleAnchor(item, markerLeft) {
    const { node } = this.view.domAtPos(item.line.from);
    const line = (node.nodeType === 1 ? node : node.parentElement)?.closest(".cm-line");
    const arrow = line?.querySelector(".cm-fold-indicator .collapse-indicator");
    const r = arrow?.getBoundingClientRect();
    return r && r.width ? Math.min(markerLeft, r.left) : markerLeft;
  }

  hideHandle() {
    this.hovered = null;
    this.handle.removeClass("is-visible");
  }

  // ---- drag ----------------------------------------------------------------

  onDown(e) {
    if (e.button !== 0 || !this.hovered) return;
    e.preventDefault();
    e.stopPropagation();
    const src = listItem(this.view.state, this.hovered.n);
    if (!src) return;
    const end = blockEnd(this.view.state, src);
    this.drag = { src, end, x: e.clientX, y: e.clientY, target: null, raf: 0, ghost: null };
    this.drag.ghost = this.makeGhost(src, end, e);
    this.setMarks(src.n, end, "block-drag-source");
    this.handle.setPointerCapture(e.pointerId);
    this.handle.addEventListener("pointermove", this.onMove);
    this.handle.addEventListener("pointerup", this.onUp);
    this.handle.addEventListener("pointercancel", this.onUp);
    window.addEventListener("keydown", this.onKey, true);
    document.body.addClass("block-drag-active");
    this.handle.addClass("is-dragging");
  }

  onMove(e) {
    if (!this.drag) return;
    this.drag.x = e.clientX;
    this.drag.y = e.clientY;
    this.placeGhost();
    this.findTarget();
    if (!this.drag.raf) this.drag.raf = requestAnimationFrame(() => this.autoScroll());
  }

  onUp() {
    this.endDrag(true);
  }

  autoScroll() {
    const d = this.drag;
    if (!d) return;
    d.raf = 0;
    const scroller = this.view.scrollDOM;
    const r = scroller.getBoundingClientRect();
    let dy = 0;
    if (d.y < r.top + EDGE) dy = -Math.ceil((r.top + EDGE - d.y) / 4);
    else if (d.y > r.bottom - EDGE) dy = Math.ceil((d.y - (r.bottom - EDGE)) / 4);
    if (!dy) return;
    const before = scroller.scrollTop;
    scroller.scrollTop += dy;
    if (scroller.scrollTop === before) return;
    this.placeGhost();
    this.findTarget();
    d.raf = requestAnimationFrame(() => this.autoScroll());
  }

  findTarget() {
    const { view, drag: d } = this;
    const state = view.state;
    const content = view.contentDOM.getBoundingClientRect();
    const x = Math.min(Math.max(d.x, content.left + 1), content.right - 1);
    const y = Math.min(Math.max(d.y, content.top + 1), content.bottom - 1);
    const n = state.doc.lineAt(view.posAtCoords({ x, y }, false)).number;
    const item = owner(state, n);
    d.target = null;

    if (item && (item.n < d.src.n || item.n > d.end)) {
      const head = view.lineBlockAt(item.line.from);
      const mid = view.documentTop + (head.top + head.bottom) / 2;
      const child = item.n < state.doc.lines && blockEnd(state, item) > item.n ? listItem(state, item.n + 1) : null;
      let t;
      if (n === item.n && y < mid) {
        t = { line: item.n, indent: item.indent, anchor: item, y: head.top };
      } else if (n === item.n && child) {
        t = { line: child.n, indent: child.indent, anchor: child, y: head.bottom };
      } else {
        const end = blockEnd(state, item);
        t = { line: end + 1, indent: item.indent, anchor: item, y: view.lineBlockAt(state.doc.line(end).from).bottom };
      }
      const noop = (t.line === d.src.n || t.line === d.end + 1) && t.indent === d.src.indent;
      if (!noop) d.target = t;
    }

    const t = d.target;
    const c = t && this.markerCoords(t.anchor);
    if (!c) return this.indicator.removeClass("is-visible");
    if (!this.indicator.hasClass("is-visible")) {
      // Appear in place rather than gliding over from where it last was.
      this.indicator.style.transition = "none";
      requestAnimationFrame(() => (this.indicator.style.transition = ""));
    }
    const p = this.local(c.left, view.documentTop + t.y);
    this.indicator.style.left = `${p.x}px`;
    this.indicator.style.top = `${p.y}px`;
    this.indicator.style.width = `${Math.max(content.right - c.left, 40)}px`;
    this.indicator.addClass("is-visible");
  }

  endDrag(commit) {
    const d = this.drag;
    if (!d) return;
    this.drag = null;
    if (d.raf) cancelAnimationFrame(d.raf);
    this.handle.removeEventListener("pointermove", this.onMove);
    this.handle.removeEventListener("pointerup", this.onUp);
    this.handle.removeEventListener("pointercancel", this.onUp);
    window.removeEventListener("keydown", this.onKey, true);
    document.body.removeClass("block-drag-active");
    this.handle.removeClass("is-dragging");
    this.indicator.removeClass("is-visible");
    this.hideHandle();
    this.setMarks();
    const moved = commit && d.target;
    this.releaseGhost(d.ghost, moved ? null : d.src.n);
    if (moved) this.move(d.src, d.end, d.target);
  }

  // ---- ghost & line marks --------------------------------------------------

  // A floating copy of the block's rendered lines, grabbed where the pointer
  // went down so it moves with the cursor.
  makeGhost(src, end, e) {
    const view = this.view;
    const lines = [];
    for (let n = src.n; n <= end; n++) {
      const { node } = view.domAtPos(view.state.doc.line(n).from);
      const el = (node.nodeType === 1 ? node : node.parentElement)?.closest(".cm-line");
      if (el && !lines.includes(el)) lines.push(el);
    }
    if (!lines.length) return null;

    const content = view.contentDOM.getBoundingClientRect();
    const top = lines[0].getBoundingClientRect().top;
    const ghost = view.scrollDOM.createDiv({ cls: "cm-content block-drag-ghost" });
    ghost.style.width = `${content.width}px`;
    for (const el of lines) {
      const copy = el.cloneNode(true);
      copy.removeClass("cm-active");
      ghost.appendChild(copy);
    }
    ghost.dataset.dx = String(e.clientX - content.left);
    ghost.dataset.dy = String(e.clientY - top);
    this.placeGhost(e.clientX, e.clientY, ghost);
    return ghost;
  }

  placeGhost(x = this.drag.x, y = this.drag.y, ghost = this.drag.ghost) {
    if (!ghost) return;
    const p = this.local(x - Number(ghost.dataset.dx), y - Number(ghost.dataset.dy));
    ghost.style.left = `${p.x}px`;
    ghost.style.top = `${p.y}px`;
  }

  // Fade the ghost out; a cancelled drag also slides it back to line `home`.
  releaseGhost(ghost, home) {
    if (!ghost) return;
    ghost.addClass("is-leaving");
    if (home) {
      const content = this.view.contentDOM.getBoundingClientRect();
      const line = this.view.lineBlockAt(this.view.state.doc.line(home).from);
      const p = this.local(content.left, this.view.documentTop + line.top);
      ghost.style.left = `${p.x}px`;
      ghost.style.top = `${p.y}px`;
    }
    window.setTimeout(() => ghost.remove(), 200);
  }

  // Line classes on lines from..to (none when called without arguments).
  setMarks(from, to, cls) {
    const doc = this.view.state.doc;
    const marks = [];
    if (from) {
      const deco = Decoration.line({ class: cls });
      for (let n = from; n <= Math.min(to, doc.lines); n++) marks.push(deco.range(doc.line(n).from));
    }
    this.decorations = Decoration.set(marks);
    this.view.dispatch({}); // redraw with the new decorations
  }

  flash(from, to) {
    window.clearTimeout(this.flashTimer);
    this.setMarks(from, to, "block-drag-dropped");
    this.flashTimer = window.setTimeout(() => this.setMarks(), FLASH_MS);
  }

  move(src, end, target) {
    const { state } = this.view;
    const doc = state.doc;
    const from = doc.line(src.n).from;
    const to = doc.line(end).to;
    const lines = doc.sliceString(from, to).split("\n").map((l) => reindent(l, src.indent, target.indent));
    const text = lines.join("\n");

    const del = end < doc.lines ? { from, to: to + 1 } : { from: from - 1, to };
    const atEnd = target.line > doc.lines;
    const at = atEnd ? doc.length : doc.line(target.line).from;
    const ins = { from: at, insert: atEnd ? "\n" + text : text + "\n" };

    const changes = state.changes([del, ins]);
    const start = changes.mapPos(at, -1) + (atEnd ? 1 : 0);
    this.view.dispatch({
      changes,
      selection: { anchor: start + lines[0].length },
      userEvent: "move.drop",
    });
    const first = this.view.state.doc.lineAt(start).number;
    this.flash(first, first + lines.length - 1);
  }
}

module.exports = class BlockDrag extends Plugin {
  onload() {
    this.registerEditorExtension(ViewPlugin.fromClass(DragHandles, { decorations: (v) => v.decorations }));
  }
};
