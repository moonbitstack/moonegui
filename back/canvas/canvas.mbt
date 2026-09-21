// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A backend that draws on a canvas in a browser.
///
/// Every drawing command maps onto something a 2D context already does, which
/// is the whole reason the shape list has five kinds and no meshes: there is no
/// triangulation, no glyph atlas and no shader, and a frame is a few dozen
/// calls into the browser's own renderer.
pub struct Canvas {
  id : String
}

///|
/// Take over the canvas with this element id.
pub fn Canvas::new(id? : String = "moonegui") -> Canvas {
  @web.attach(id)
  js_canvas_init()
  { id, }
}

///|
/// Which element this backend draws on.
pub fn Canvas::id(self : Canvas) -> String {
  self.id
}

///|
/// How large the canvas is, in the units a frame is laid out in.
pub fn Canvas::size(_self : Canvas) -> @emath.Rect {
  @web.size()
}

///|
/// How many device pixels there are to a logical one.
pub fn Canvas::pixels(_self : Canvas) -> Double {
  @web.pixels()
}

///|
/// Paint the whole canvas one colour, which is what a frame starts with.
pub fn Canvas::clear(_self : Canvas, color : @paint.Color) -> Unit {
  js_clear(color.r, color.g, color.b, color.a)
}

///|
/// Start listening for input on the canvas.
pub fn Canvas::listen(_self : Canvas) -> Unit {
  @web.listen()
}

///|
/// Stop listening.
pub fn Canvas::unlisten(_self : Canvas) -> Unit {
  @web.unlisten()
}

///|
/// Everything that happened since the last frame.
pub fn Canvas::raw(_self : Canvas, time : Double, dt : Double) -> @input.Raw {
  @web.raw(time, dt)
}

///|
/// The time the page has been open, in seconds.
pub fn now() -> Double {
  @web.now()
}

///|
pub impl @back.Backend for Canvas with fn measure(_self, text, font) {
  @web.measure(text, font)
}

///|
pub impl @back.Backend for Canvas with fn line_height(_self, font) {
  @web.line_height(font)
}

///|
pub impl @back.Backend for Canvas with fn measure_prefix(
  _self,
  text,
  font,
  room,
) {
  @web.prefix(text, font, room)
}

///|
pub impl @back.Backend for Canvas with fn push_clip(_self, rect) {
  js_push_clip(rect.min.x, rect.min.y, rect.width(), rect.height())
}

///|
pub impl @back.Backend for Canvas with fn pop_clip(_self) {
  js_pop_clip()
}

///|
pub impl @back.Backend for Canvas with fn fill_rect(_self, rect, corner, color) {
  js_fill_rect(
    rect.min.x,
    rect.min.y,
    rect.width(),
    rect.height(),
    corner.nw,
    corner.ne,
    corner.se,
    corner.sw,
    color.r,
    color.g,
    color.b,
    color.a,
  )
}

///|
pub impl @back.Backend for Canvas with fn stroke_rect(
  _self,
  rect,
  corner,
  stroke,
) {
  js_stroke_rect(
    rect.min.x,
    rect.min.y,
    rect.width(),
    rect.height(),
    corner.nw,
    corner.ne,
    corner.se,
    corner.sw,
    stroke.width,
    stroke.color.r,
    stroke.color.g,
    stroke.color.b,
    stroke.color.a,
  )
}

///|
pub impl @back.Backend for Canvas with fn fill_circle(
  _self,
  centre,
  radius,
  color,
) {
  js_circle(
    centre.x,
    centre.y,
    radius,
    0,
    color.r,
    color.g,
    color.b,
    color.a,
    1,
  )
}

///|
pub impl @back.Backend for Canvas with fn stroke_circle(
  _self,
  centre,
  radius,
  stroke,
) {
  js_circle(
    centre.x,
    centre.y,
    radius,
    stroke.width,
    stroke.color.r,
    stroke.color.g,
    stroke.color.b,
    stroke.color.a,
    0,
  )
}

///|
pub impl @back.Backend for Canvas with fn stroke_path(
  _self,
  points,
  closed,
  stroke,
) {
  js_begin_path()
  for point in points {
    js_point(point.x, point.y)
  }
  js_end_path(
    if closed {
      1
    } else {
      0
    },
    stroke.width,
    stroke.color.r,
    stroke.color.g,
    stroke.color.b,
    stroke.color.a,
    0,
  )
}

///|
pub impl @back.Backend for Canvas with fn fill_path(_self, points, color) {
  js_begin_path()
  for point in points {
    js_point(point.x, point.y)
  }
  js_end_path(1, 0, color.r, color.g, color.b, color.a, 1)
}

///|
pub impl @back.Backend for Canvas with fn fill_text(
  _self,
  at,
  text,
  font,
  color,
) {
  js_fill_text(
    at.x,
    at.y,
    text,
    font.size,
    @web.mono(font),
    color.r,
    color.g,
    color.b,
    color.a,
  )
}

///|
pub extend Canvas with @back.Backend::{
  measure,
  pop_clip,
  stroke_rect,
  fill_text,
  line_height,
  measure_prefix,
  fill_rect,
  stroke_path,
  push_clip,
  fill_circle,
  stroke_circle,
  fill_path,
}
