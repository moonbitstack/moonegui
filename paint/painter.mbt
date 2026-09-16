// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A rectangle large enough to contain anything, which is what "no clipping"
/// means when clipping is a rectangle.
pub let unclipped : @emath.Rect = {
  min: { x: -1.0e9, y: -1.0e9, },
  max: { x: 1.0e9, y: 1.0e9, },
}

///|
/// Where shapes are collected.
///
/// Clipping is decided here rather than by the backend: a shape completely
/// outside its clip is dropped, one completely inside loses the clip
/// altogether, and only a shape that straddles the edge carries one. A backend
/// therefore never has to intersect anything, and a canvas — whose clip can
/// only ever be made smaller — is not asked to widen one.
pub struct Painter {
  shapes : Array[Clipped]
  clip : @emath.Rect
}

///|
/// A painter that collects into its own list.
pub fn Painter::new(clip? : @emath.Rect = unclipped) -> Painter {
  { shapes: [], clip, }
}

///|
/// A painter that draws into the same list, clipped to a smaller rectangle.
pub fn Painter::sub(self : Painter, clip : @emath.Rect) -> Painter {
  { shapes: self.shapes, clip: self.clip.intersect(clip), }
}

///|
/// Everything collected so far.
pub fn Painter::shapes(self : Painter) -> Array[Clipped] {
  self.shapes
}

///|
/// How many shapes have been collected.
pub fn Painter::count(self : Painter) -> Int {
  self.shapes.length()
}

///|
/// The rectangle this painter draws inside.
pub fn Painter::clip(self : Painter) -> @emath.Rect {
  self.clip
}

///|
/// Add a shape, clipping it away if it cannot be seen.
pub fn Painter::add(self : Painter, shape : Shape) -> Unit {
  let bounds = shape.bounds()
  if self.clip.intersect(bounds).is_empty() {
    return
  }
  let clip = if contains_rect(self.clip, bounds) {
    unclipped
  } else {
    self.clip
  }
  self.shapes.push({ clip, shape, })
}

///|
/// Draw a rectangle.
pub fn Painter::rect(
  self : Painter,
  rect : @emath.Rect,
  fill? : Color = clear,
  stroke? : Stroke = no_stroke,
  corner? : Corner = square,
) -> Unit {
  self.add(Rect(rect~, corner~, fill~, stroke~))
}

///|
/// Draw a circle.
pub fn Painter::circle(
  self : Painter,
  centre : @emath.Vec2,
  radius : Double,
  fill? : Color = clear,
  stroke? : Stroke = no_stroke,
) -> Unit {
  self.add(Circle(centre~, radius~, fill~, stroke~))
}

///|
/// Draw a straight line between two points.
pub fn Painter::line(
  self : Painter,
  from : @emath.Vec2,
  to : @emath.Vec2,
  stroke : Stroke,
) -> Unit {
  self.add(Path(points=[from, to], closed=false, fill=clear, stroke~))
}

///|
/// Draw a path through several points.
pub fn Painter::path(
  self : Painter,
  points : Array[@emath.Vec2],
  closed? : Bool = false,
  fill? : Color = clear,
  stroke? : Stroke = no_stroke,
) -> Unit {
  self.add(Path(points~, closed~, fill~, stroke~))
}

///|
/// Draw text that has already been laid out.
pub fn Painter::galley(
  self : Painter,
  at : @emath.Vec2,
  galley : Galley,
  color : Color,
) -> Unit {
  self.add(Text(at~, galley~, color~))
}

///|
/// Forget everything collected, which is what a new frame starts from.
pub fn Painter::clear(self : Painter) -> Unit {
  self.shapes.clear()
}

///|
/// True when the outer rectangle holds all of the inner one.
fn contains_rect(outer : @emath.Rect, inner : @emath.Rect) -> Bool {
  inner.min.x >= outer.min.x &&
  inner.min.y >= outer.min.y &&
  inner.max.x <= outer.max.x &&
  inner.max.y <= outer.max.y
}
