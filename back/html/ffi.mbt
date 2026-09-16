// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Everything the document is asked to do.
///
/// The elements of one frame are kept in a list and taken again the next frame
/// whenever the kind matches, so a still interface changes nothing in the
/// document at all and a moving one changes only what moved.
extern "js" fn js_html_init() -> Unit =
  #| () => {
  #|   const s = globalThis.__moonegui;
  #|   const layer = document.createElement("div");
  #|   layer.style.cssText = "position:relative;width:100%;height:100%;overflow:hidden";
  #|   s.el.appendChild(layer);
  #|   s.layer = layer;
  #|   s.nodes = [];
  #|   s.clips = [];
  #|   s.at = 0;
  #|   s.take = (kind, tag, ns) => {
  #|     const had = s.nodes[s.at];
  #|     if (had && had.kind === kind) { s.at += 1; return had.el; }
  #|     const el = ns ? document.createElementNS(ns, tag) : document.createElement(tag);
  #|     if (had) { layer.replaceChild(el, had.el); s.nodes[s.at] = { kind, el }; }
  #|     else { layer.appendChild(el); s.nodes.push({ kind, el }); }
  #|     s.at += 1;
  #|     return el;
  #|   };
  #|   // The clip in force, as the inset a `clip-path` wants: distances from
  #|   // each edge of the element rather than coordinates on the page.
  #|   s.clip = (el, x, y, w, h) => {
  #|     const c = s.clips[s.clips.length - 1];
  #|     if (!c) { el.style.clipPath = ""; return; }
  #|     const top = Math.max(0, c[1] - y), left = Math.max(0, c[0] - x);
  #|     const right = Math.max(0, (x + w) - c[2]), bottom = Math.max(0, (y + h) - c[3]);
  #|     el.style.clipPath = "inset(" + top + "px " + right + "px " + bottom + "px " + left + "px)";
  #|   };
  #| }

///|
extern "js" fn js_begin(r : Int, g : Int, b : Int, a : Int) -> Unit =
  #| (r, g, b, a) => {
  #|   const s = globalThis.__moonegui;
  #|   s.at = 0;
  #|   s.clips = [];
  #|   s.layer.style.background = globalThis.__moonegui_rgba(r, g, b, a);
  #| }

///|
extern "js" fn js_end() -> Unit =
  #| () => {
  #|   const s = globalThis.__moonegui;
  #|   while (s.nodes.length > s.at) {
  #|     const gone = s.nodes.pop();
  #|     s.layer.removeChild(gone.el);
  #|   }
  #| }

///|
extern "js" fn js_count() -> Int =
  #| () => globalThis.__moonegui.nodes.length

///|
extern "js" fn js_push_clip(
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
) -> Unit =
  #| (x1, y1, x2, y2) => globalThis.__moonegui.clips.push([x1, y1, x2, y2])

///|
extern "js" fn js_pop_clip() -> Unit =
  #| () => globalThis.__moonegui.clips.pop()

///|
/// A rectangle, filled when the border width is zero and outlined when it is
/// not, which is the one place a document needs less than a canvas: the border
/// is drawn inside the box rather than across its edge.
extern "js" fn js_rect(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  nw : Double,
  ne : Double,
  se : Double,
  sw : Double,
  width : Double,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
) -> Unit =
  #| (x, y, w, h, nw, ne, se, sw, width, r, g, b, a) => {
  #|   const s = globalThis.__moonegui;
  #|   const el = s.take("rect", "div");
  #|   const paint = globalThis.__moonegui_rgba(r, g, b, a);
  #|   el.style.cssText =
  #|     "position:absolute;box-sizing:border-box;pointer-events:none" +
  #|     ";left:" + x + "px;top:" + y + "px;width:" + w + "px;height:" + h + "px" +
  #|     ";border-radius:" + nw + "px " + ne + "px " + se + "px " + sw + "px" +
  #|     (width > 0
  #|       ? ";border:" + width + "px solid " + paint
  #|       : ";background:" + paint);
  #|   s.clip(el, x, y, w, h);
  #| }

///|
extern "js" fn js_circle(
  x : Double,
  y : Double,
  radius : Double,
  width : Double,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
) -> Unit =
  #| (x, y, radius, width, r, g, b, a) => {
  #|   const s = globalThis.__moonegui;
  #|   const el = s.take("circle", "div");
  #|   const paint = globalThis.__moonegui_rgba(r, g, b, a);
  #|   const side = Math.max(0, radius * 2);
  #|   el.style.cssText =
  #|     "position:absolute;box-sizing:border-box;border-radius:50%;pointer-events:none" +
  #|     ";left:" + (x - radius) + "px;top:" + (y - radius) + "px" +
  #|     ";width:" + side + "px;height:" + side + "px" +
  #|     (width > 0
  #|       ? ";border:" + width + "px solid " + paint
  #|       : ";background:" + paint);
  #|   s.clip(el, x - radius, y - radius, side, side);
  #| }

///|
extern "js" fn js_begin_path() -> Unit =
  #| () => { globalThis.__moonegui.points = []; }

///|
extern "js" fn js_point(x : Double, y : Double) -> Unit =
  #| (x, y) => { globalThis.__moonegui.points.push([x, y]); }

///|
/// A path becomes a one element `svg` laid over the page. Its box is the
/// bounding box of the points, so the coordinates inside it are relative and
/// the element can still be clipped like any other.
extern "js" fn js_end_path(
  closed : Int,
  width : Double,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
  filled : Int,
) -> Unit =
  #| (closed, width, r, g, b, a, filled) => {
  #|   const s = globalThis.__moonegui;
  #|   const points = s.points || [];
  #|   if (points.length === 0) return;
  #|   const pad = Math.max(1, width);
  #|   let x1 = points[0][0], y1 = points[0][1], x2 = x1, y2 = y1;
  #|   for (const p of points) {
  #|     x1 = Math.min(x1, p[0]); y1 = Math.min(y1, p[1]);
  #|     x2 = Math.max(x2, p[0]); y2 = Math.max(y2, p[1]);
  #|   }
  #|   x1 -= pad; y1 -= pad; x2 += pad; y2 += pad;
  #|   const w = x2 - x1, h = y2 - y1;
  #|   const svg = s.take("path", "svg", "http://www.w3.org/2000/svg");
  #|   svg.setAttribute("width", w);
  #|   svg.setAttribute("height", h);
  #|   svg.setAttribute("viewBox", "0 0 " + w + " " + h);
  #|   svg.style.cssText =
  #|     "position:absolute;overflow:visible;pointer-events:none" +
  #|     ";left:" + x1 + "px;top:" + y1 + "px";
  #|   while (svg.firstChild) svg.removeChild(svg.firstChild);
  #|   const shape = document.createElementNS("http://www.w3.org/2000/svg", closed ? "polygon" : "polyline");
  #|   shape.setAttribute("points", points.map((p) => (p[0] - x1) + "," + (p[1] - y1)).join(" "));
  #|   const paint = globalThis.__moonegui_rgba(r, g, b, a);
  #|   if (filled) {
  #|     shape.setAttribute("fill", paint);
  #|     shape.setAttribute("stroke", "none");
  #|   } else {
  #|     shape.setAttribute("fill", "none");
  #|     shape.setAttribute("stroke", paint);
  #|     shape.setAttribute("stroke-width", width);
  #|     shape.setAttribute("stroke-linecap", "round");
  #|     shape.setAttribute("stroke-linejoin", "round");
  #|   }
  #|   svg.appendChild(shape);
  #|   s.clip(svg, x1, y1, w, h);
  #| }

///|
extern "js" fn js_text(
  x : Double,
  y : Double,
  text : String,
  size : Double,
  mono : Int,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
) -> Unit =
  #| (x, y, text, size, mono, r, g, b, a) => {
  #|   const s = globalThis.__moonegui;
  #|   const el = s.take("text", "div");
  #|   el.style.cssText =
  #|     "position:absolute;white-space:pre;pointer-events:none" +
  #|     ";left:" + x + "px;top:" + y + "px" +
  #|     ";font:" + globalThis.__moonegui_face(size, mono) +
  #|     ";line-height:1;color:" + globalThis.__moonegui_rgba(r, g, b, a);
  #|   if (el.textContent !== text) el.textContent = text;
  #|   const box = el.getBoundingClientRect();
  #|   s.clip(el, x, y, box.width, box.height);
  #| }
