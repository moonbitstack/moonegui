// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Everything that has to cross into the browser.
///
/// Numbers and strings only: a colour arrives as four integers and a shape as a
/// handful of coordinates, so nothing on either side has to agree about the
/// layout of a value.
extern "js" fn js_attach(id : String) -> Unit =
  #| (id) => {
  #|   const el = document.getElementById(id);
  #|   const state = {
  #|     el,
  #|     meter: document.createElement("canvas").getContext("2d"),
  #|     queue: [],
  #|     focused: true,
  #|     dpr: 1,
  #|     onResize: [],
  #|   };
  #|   globalThis.__moonegui = state;
  #|   const resize = () => {
  #|     const box = el.getBoundingClientRect();
  #|     state.dpr = globalThis.devicePixelRatio || 1;
  #|     state.width = Math.max(1, Math.round(box.width));
  #|     state.height = Math.max(1, Math.round(box.height));
  #|     state.onResize.forEach((f) => f());
  #|   };
  #|   state.resize = resize;
  #|   resize();
  #|   globalThis.addEventListener("resize", resize);
  #|   globalThis.__moonegui_face = (size, mono) => size + "px " + (mono
  #|     ? "ui-monospace, SFMono-Regular, Menlo, Consolas, monospace"
  #|     : "system-ui, -apple-system, Segoe UI, Roboto, sans-serif");
  #|   globalThis.__moonegui_rgba = (r, g, b, a) =>
  #|     "rgba(" + r + "," + g + "," + b + "," + (a / 255) + ")";
  #|   globalThis.__moonegui_rect = (c, x, y, w, h, nw, ne, se, sw) => {
  #|     c.beginPath();
  #|     if (c.roundRect && (nw || ne || se || sw)) c.roundRect(x, y, w, h, [nw, ne, se, sw]);
  #|     else c.rect(x, y, w, h);
  #|   };
  #| }

///|
extern "js" fn js_dpr() -> Double =
  #| () => globalThis.__moonegui.dpr

///|
extern "js" fn js_width() -> Double =
  #| () => globalThis.__moonegui.width

///|
extern "js" fn js_height() -> Double =
  #| () => globalThis.__moonegui.height

///|
extern "js" fn js_now() -> Double =
  #| () => performance.now()

///|
extern "js" fn js_focused() -> Bool =
  #| () => globalThis.__moonegui.focused

///|
extern "js" fn js_measure(text : String, size : Double, mono : Int) -> Double =
  #| (text, size, mono) => {
  #|   const s = globalThis.__moonegui;
  #|   s.meter.font = globalThis.__moonegui_face(size, mono);
  #|   return s.meter.measureText(text).width;
  #| }

///|
/// The distance between the tops of two lines, taken from the font itself where
/// the browser reports it and from the size where it does not.
extern "js" fn js_line_height(size : Double) -> Double =
  #| (size) => Math.round(size * 1.35)

///|
/// The longest prefix that fits, found by halving rather than by measuring
/// every prefix, and never landing inside a surrogate pair.
extern "js" fn js_prefix(
  text : String,
  size : Double,
  mono : Int,
  room : Double,
) -> Int =
  #| (text, size, mono, room) => {
  #|   const s = globalThis.__moonegui;
  #|   s.meter.font = globalThis.__moonegui_face(size, mono);
  #|   if (room <= 0) return 0;
  #|   if (s.meter.measureText(text).width <= room) return text.length;
  #|   let low = 0, high = text.length;
  #|   while (low < high) {
  #|     let mid = (low + high + 1) >> 1;
  #|     const code = text.charCodeAt(mid);
  #|     if (code >= 0xDC00 && code <= 0xDFFF) mid -= 1;
  #|     if (mid <= low) break;
  #|     if (s.meter.measureText(text.slice(0, mid)).width <= room) low = mid;
  #|     else high = mid - 1;
  #|   }
  #|   return low;
  #| }

///|
extern "js" fn js_listen() -> Unit =
  #| () => {
  #|   const s = globalThis.__moonegui;
  #|   if (s.onMove) return;
  #|   const el = s.el;
  #|   const push = (line) => s.queue.push(line);
  #|   const bits = (e) => (e.ctrlKey || e.metaKey ? 1 : 0) | (e.altKey ? 2 : 0) | (e.shiftKey ? 4 : 0);
  #|   const spot = (e) => {
  #|     const box = el.getBoundingClientRect();
  #|     return (e.clientX - box.left) + " " + (e.clientY - box.top);
  #|   };
  #|   const escape = (text) => text.split("\\").join("\\\\").split("\n").join("\\n");
  #|   s.onMove = (e) => push("m " + spot(e));
  #|   s.onDown = (e) => {
  #|     el.focus();
  #|     el.setPointerCapture && el.setPointerCapture(e.pointerId);
  #|     push("d " + spot(e) + " " + e.button + " " + bits(e));
  #|   };
  #|   s.onUp = (e) => push("u " + spot(e) + " " + e.button + " " + bits(e));
  #|   s.onLeave = () => push("g");
  #|   s.onWheel = (e) => { e.preventDefault(); push("s " + (-e.deltaX) + " " + (-e.deltaY)); };
  #|   s.onKey = (e) => {
  #|     const named = ["Enter","Tab","Backspace","Delete","Escape","ArrowLeft","ArrowRight","ArrowUp","ArrowDown","Home","End","PageUp","PageDown"];
  #|     if (e.key === " ") {
  #|       e.preventDefault();
  #|       push("k Space " + bits(e));
  #|       push("t  ");
  #|       return;
  #|     }
  #|     if (named.indexOf(e.key) >= 0) {
  #|       if (e.key === "Tab" || e.key.startsWith("Arrow")) e.preventDefault();
  #|       push("k " + e.key + " " + bits(e));
  #|       return;
  #|     }
  #|     if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
  #|       push("t " + escape(e.key));
  #|     }
  #|   };
  #|   s.onPaste = (e) => {
  #|     const text = (e.clipboardData || globalThis.clipboardData).getData("text");
  #|     if (text) push("v " + escape(text));
  #|   };
  #|   s.onBlur = () => { s.focused = false; push("f 0"); };
  #|   s.onFocus = () => { s.focused = true; push("f 1"); };
  #|   el.addEventListener("pointermove", s.onMove);
  #|   el.addEventListener("pointerdown", s.onDown);
  #|   el.addEventListener("pointerup", s.onUp);
  #|   el.addEventListener("pointerleave", s.onLeave);
  #|   el.addEventListener("wheel", s.onWheel, { passive: false });
  #|   el.addEventListener("keydown", s.onKey);
  #|   el.addEventListener("paste", s.onPaste);
  #|   el.addEventListener("blur", s.onBlur);
  #|   el.addEventListener("focus", s.onFocus);
  #| }

///|
extern "js" fn js_unlisten() -> Unit =
  #| () => {
  #|   const s = globalThis.__moonegui;
  #|   if (!s || !s.onMove) return;
  #|   const el = s.el;
  #|   el.removeEventListener("pointermove", s.onMove);
  #|   el.removeEventListener("pointerdown", s.onDown);
  #|   el.removeEventListener("pointerup", s.onUp);
  #|   el.removeEventListener("pointerleave", s.onLeave);
  #|   el.removeEventListener("wheel", s.onWheel);
  #|   el.removeEventListener("keydown", s.onKey);
  #|   el.removeEventListener("paste", s.onPaste);
  #|   el.removeEventListener("blur", s.onBlur);
  #|   el.removeEventListener("focus", s.onFocus);
  #|   s.onMove = null;
  #| }

///|
extern "js" fn js_events() -> String =
  #| () => {
  #|   const s = globalThis.__moonegui;
  #|   const out = s.queue.join("\n");
  #|   s.queue = [];
  #|   return out;
  #| }
