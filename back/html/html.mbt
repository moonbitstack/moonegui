// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A backend that draws a frame as elements in the document.
///
/// The same shapes that go onto a canvas can go into the page instead: a
/// rectangle is a `div`, a circle is a `div` with a round border, a path is an
/// `svg`, and a row of text is a `div` the browser renders with its own text
/// engine. What that buys is everything the document already has — selectable
/// text, hardware scrolling, zoom, and elements a screen reader can be taught
/// to read — at the cost of one element per shape.
///
/// Both browser backends measure through the same code, so a page laid out for
/// one is laid out identically for the other.
pub struct Html {
  id : String
}

///|
/// Take over the element with this id and draw into it.
pub fn Html::new(id? : String = "moonegui") -> Html {
  @web.attach(id)
  js_html_init()
  { id, }
}

///|
/// Which element this backend draws into.
pub fn Html::id(self : Html) -> String {
  self.id
}

///|
/// How large the surface is, in the units a frame is laid out in.
pub fn Html::size(_self : Html) -> @emath.Rect {
  @web.size()
}

///|
/// Start a frame: every element from the frame before is offered for reuse.
///
/// A frame is drawn in order, so the nth shape this frame can take over the
/// element the nth shape used last frame whenever the two are the same kind.
/// That keeps the document from being rebuilt sixty times a second, and it is
/// why this backend needs a `begin` where the canvas one needs a `clear`.
pub fn Html::begin(_self : Html, color : @paint.Color) -> Unit {
  js_begin(color.r, color.g, color.b, color.a)
}

///|
/// Finish a frame: whatever was not reused is taken out of the document.
pub fn Html::end(_self : Html) -> Unit {
  js_end()
}

///|
/// Start listening for input.
pub fn Html::listen(_self : Html) -> Unit {
  @web.listen()
}

///|
/// Stop listening.
pub fn Html::unlisten(_self : Html) -> Unit {
  @web.unlisten()
}

///|
/// Everything that happened since the last frame.
pub fn Html::raw(_self : Html, time : Double, dt : Double) -> @input.Raw {
  @web.raw(time, dt)
}

///|
/// How many elements the last frame left in the document.
pub fn Html::count(_self : Html) -> Int {
  js_count()
}

///|
pub impl @back.Backend for Html with fn measure(_self, text, font) {
  @web.measure(text, font)
}

///|
pub impl @back.Backend for Html with fn line_height(_self, font) {
  @web.line_height(font)
}

///|
pub impl @back.Backend for Html with fn measure_prefix(_self, text, font, room) {
  @web.prefix(text, font, room)
}

///|
/// Clipping is a rectangle every later element is cut to, which in a document
/// is a `clip-path` on each of them rather than a nesting of parents: the
/// elements stay a flat list, so reusing them stays a matter of counting.
pub impl @back.Backend for Html with fn push_clip(_self, rect) {
  js_push_clip(rect.min.x, rect.min.y, rect.max.x, rect.max.y)
}

///|
pub impl @back.Backend for Html with fn pop_clip(_self) {
  js_pop_clip()
}

///|
pub impl @back.Backend for Html with fn fill_rect(_self, rect, corner, color) {
  js_rect(
    rect.min.x,
    rect.min.y,
    rect.width(),
    rect.height(),
    corner.nw,
    corner.ne,
    corner.se,
    corner.sw,
    0,
    color.r,
    color.g,
    color.b,
    color.a,
  )
}

///|
pub impl @back.Backend for Html with fn stroke_rect(_self, rect, corner, stroke) {
  js_rect(
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
pub impl @back.Backend for Html with fn fill_circle(
  _self,
  centre,
  radius,
  color,
) {
  js_circle(centre.x, centre.y, radius, 0, color.r, color.g, color.b, color.a)
}

///|
pub impl @back.Backend for Html with fn stroke_circle(
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
  )
}

///|
pub impl @back.Backend for Html with fn stroke_path(
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
pub impl @back.Backend for Html with fn fill_path(_self, points, color) {
  js_begin_path()
  for point in points {
    js_point(point.x, point.y)
  }
  js_end_path(1, 0, color.r, color.g, color.b, color.a, 1)
}

///|
pub impl @back.Backend for Html with fn fill_text(_self, at, text, font, color) {
  js_text(
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
