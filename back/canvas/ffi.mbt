// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Everything a 2D canvas is asked to draw.
///
/// Numbers only: a colour arrives as four integers and a shape as a handful of
/// coordinates, so nothing on either side has to agree about the layout of a
/// value.
extern "js" fn js_canvas_init() -> Unit =
  #| () => {
  #|   const s = globalThis.__moonegui;
  #|   s.ctx = s.el.getContext("2d");
  #|   const fit = () => {
  #|     s.el.width = Math.round(s.width * s.dpr);
  #|     s.el.height = Math.round(s.height * s.dpr);
  #|     s.ctx.setTransform(s.dpr, 0, 0, s.dpr, 0, 0);
  #|   };
  #|   s.onResize.push(fit);
  #|   fit();
  #| }

///|
extern "js" fn js_clear(r : Int, g : Int, b : Int, a : Int) -> Unit =
  #| (r, g, b, a) => {
  #|   const s = globalThis.__moonegui;
  #|   s.ctx.setTransform(s.dpr, 0, 0, s.dpr, 0, 0);
  #|   s.ctx.fillStyle = globalThis.__moonegui_rgba(r, g, b, a);
  #|   s.ctx.fillRect(0, 0, s.width, s.height);
  #| }

///|
extern "js" fn js_push_clip(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> Unit =
  #| (x, y, w, h) => {
  #|   const c = globalThis.__moonegui.ctx;
  #|   c.save();
  #|   c.beginPath();
  #|   c.rect(x, y, w, h);
  #|   c.clip();
  #| }

///|
extern "js" fn js_pop_clip() -> Unit =
  #| () => globalThis.__moonegui.ctx.restore()

///|
extern "js" fn js_fill_rect(
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  nw : Double,
  ne : Double,
  se : Double,
  sw : Double,
  r : Int,
  g : Int,
  b : Int,
  a : Int,
) -> Unit =
  #| (x, y, w, h, nw, ne, se, sw, r, g, b, a) => {
  #|   const c = globalThis.__moonegui.ctx;
  #|   c.fillStyle = globalThis.__moonegui_rgba(r, g, b, a);
  #|   globalThis.__moonegui_rect(c, x, y, w, h, nw, ne, se, sw);
  #|   c.fill();
  #| }

///|
extern "js" fn js_stroke_rect(
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
  #|   const c = globalThis.__moonegui.ctx;
  #|   c.strokeStyle = globalThis.__moonegui_rgba(r, g, b, a);
  #|   c.lineWidth = width;
  #|   // Half a pixel in from the edge: a one pixel line centred on a whole
  #|   // coordinate is drawn across two rows of pixels and comes out grey.
  #|   const half = width / 2;
  #|   globalThis.__moonegui_rect(c, x + half, y + half, w - width, h - width, nw, ne, se, sw);
  #|   c.stroke();
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
  filled : Int,
) -> Unit =
  #| (x, y, radius, width, r, g, b, a, filled) => {
  #|   const c = globalThis.__moonegui.ctx;
  #|   c.beginPath();
  #|   c.arc(x, y, Math.max(0, radius), 0, Math.PI * 2);
  #|   if (filled) {
  #|     c.fillStyle = globalThis.__moonegui_rgba(r, g, b, a);
  #|     c.fill();
  #|   } else {
  #|     c.strokeStyle = globalThis.__moonegui_rgba(r, g, b, a);
  #|     c.lineWidth = width;
  #|     c.stroke();
  #|   }
  #| }

///|
extern "js" fn js_begin_path() -> Unit =
  #| () => {
  #|   const c = globalThis.__moonegui.ctx;
  #|   c.beginPath();
  #|   globalThis.__moonegui.started = false;
  #| }

///|
extern "js" fn js_point(x : Double, y : Double) -> Unit =
  #| (x, y) => {
  #|   const s = globalThis.__moonegui;
  #|   if (s.started) s.ctx.lineTo(x, y);
  #|   else { s.ctx.moveTo(x, y); s.started = true; }
  #| }

///|
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
  #|   const c = globalThis.__moonegui.ctx;
  #|   if (closed) c.closePath();
  #|   if (filled) {
  #|     c.fillStyle = globalThis.__moonegui_rgba(r, g, b, a);
  #|     c.fill();
  #|   } else {
  #|     c.strokeStyle = globalThis.__moonegui_rgba(r, g, b, a);
  #|     c.lineWidth = width;
  #|     c.lineJoin = "round";
  #|     c.lineCap = "round";
  #|     c.stroke();
  #|   }
  #| }

///|
/// Text is drawn from its top left, which is where a laid out row says it is.
extern "js" fn js_fill_text(
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
  #|   const c = globalThis.__moonegui.ctx;
  #|   c.font = globalThis.__moonegui_face(size, mono);
  #|   c.textBaseline = "top";
  #|   c.fillStyle = globalThis.__moonegui_rgba(r, g, b, a);
  #|   c.fillText(text, x, y);
  #| }
