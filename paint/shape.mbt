// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A colour with an alpha channel, each component from 0 to 255.
pub(all) struct Color {
  r : Int
  g : Int
  b : Int
  a : Int
} derive(Eq, Debug)

///|
/// An opaque colour.
pub fn Color::rgb(r : Int, g : Int, b : Int) -> Color {
  { r: byte(r), g: byte(g), b: byte(b), a: 255, }
}

///|
/// A colour with an alpha channel.
pub fn Color::rgba(r : Int, g : Int, b : Int, a : Int) -> Color {
  { r: byte(r), g: byte(g), b: byte(b), a: byte(a), }
}

///|
/// A grey.
pub fn Color::grey(level : Int) -> Color {
  Color::rgb(level, level, level)
}

///|
/// Nothing at all: a shape filled with this is not drawn.
pub let clear : Color = { r: 0, g: 0, b: 0, a: 0, }

///|
/// True when the colour would not change anything it was drawn over.
pub fn Color::is_clear(self : Color) -> Bool {
  self.a == 0
}

///|
/// The same colour at a different opacity.
pub fn Color::with_alpha(self : Color, a : Int) -> Color {
  { ..self, a: byte(a), }
}

///|
/// Mix two colours, `t` running from zero (all `self`) to one (all `other`).
pub fn Color::lerp(self : Color, other : Color, t : Double) -> Color {
  let f = @emath.clamp(t, 0, 1)
  {
    r: mix(self.r, other.r, f),
    g: mix(self.g, other.g, f),
    b: mix(self.b, other.b, f),
    a: mix(self.a, other.a, f),
  }
}

///|
/// A line: how thick and what colour.
pub(all) struct Stroke {
  width : Double
  color : Color
} derive(Eq, Debug)

///|
/// No line at all.
pub let no_stroke : Stroke = { width: 0, color: clear, }

///|
/// A line of this width and colour.
pub fn Stroke::new(width : Double, color : Color) -> Stroke {
  { width, color, }
}

///|
/// True when the stroke would draw nothing.
pub fn Stroke::is_empty(self : Stroke) -> Bool {
  self.width <= 0 || self.color.is_clear()
}

///|
/// How round each corner of a rectangle is.
pub(all) struct Corner {
  nw : Double
  ne : Double
  se : Double
  sw : Double
} derive(Eq, Debug)

///|
/// Square corners.
pub let square : Corner = { nw: 0, ne: 0, se: 0, sw: 0, }

///|
/// The same radius on every corner.
pub fn Corner::same(radius : Double) -> Corner {
  { nw: radius, ne: radius, se: radius, sw: radius, }
}

///|
/// Which font to draw text in. The family is a choice between the two a user
/// interface actually needs; the size is in logical pixels.
pub(all) struct FontId {
  size : Double
  family : Family
} derive(Eq, Debug)

///|
pub(all) enum Family {
  Sans
  Mono
} derive(Eq, Debug)

///|
/// The default font.
pub let body : FontId = { size: 14, family: Sans, }

///|
/// One laid-out line of text, positioned relative to the text's own origin.
pub(all) struct TextRow {
  text : String
  at : @emath.Vec2
} derive(Eq, Debug)

///|
/// Text that has already been broken into lines and measured.
///
/// Laying out text needs the backend, which knows how wide a character is;
/// drawing it does not. Keeping the laid-out result in its own value is what
/// lets a widget measure once and draw later.
pub(all) struct Galley {
  rows : Array[TextRow]
  size : @emath.Vec2
  font : FontId
} derive(Eq, Debug)

///|
/// Something to draw.
///
/// Five kinds, not eleven: a rectangle, a circle, a path, text and an image
/// cover a user interface, and every one of them maps onto what a plain 2D
/// canvas can already do. Anything needing a triangle mesh is deliberately out.
pub(all) enum Shape {
  Rect(rect~ : @emath.Rect, corner~ : Corner, fill~ : Color, stroke~ : Stroke)
  Circle(
    centre~ : @emath.Vec2,
    radius~ : Double,
    fill~ : Color,
    stroke~ : Stroke
  )
  Path(
    points~ : Array[@emath.Vec2],
    closed~ : Bool,
    fill~ : Color,
    stroke~ : Stroke
  )
  Text(at~ : @emath.Vec2, galley~ : Galley, color~ : Color)
  Image(rect~ : @emath.Rect, name~ : String, tint~ : Color)
} derive(Eq, Debug)

///|
/// The rectangle a shape covers, stroke width included.
pub fn Shape::bounds(self : Shape) -> @emath.Rect {
  match self {
    Rect(rect~, stroke~, ..) => rect.grow(stroke.width / 2)
    Circle(centre~, radius~, stroke~, ..) =>
      @emath.Rect::around(
        centre,
        @emath.Vec2::splat((radius + stroke.width / 2) * 2),
      )
    Path(points~, stroke~, ..) => {
      if points.length() == 0 {
        return @emath.nothing
      }
      // Taken corner by corner rather than by uniting a rectangle per point:
      // a point is a rectangle of no area, and uniting with one of those adds
      // nothing at all, which would leave a straight line bounded by its last
      // point and drawn nowhere.
      let mut low = points[0]
      let mut high = points[0]
      for point in points {
        low = low.min(point)
        high = high.max(point)
      }
      @emath.Rect::of(low, high).grow(stroke.width / 2)
    }
    Text(at~, galley~, ..) => @emath.Rect::at(at, galley.size)
    Image(rect~, ..) => rect
  }
}

///|
/// A shape and the rectangle it may draw inside.
pub(all) struct Clipped {
  clip : @emath.Rect
  shape : Shape
} derive(Eq, Debug)

///|
fn byte(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
fn mix(a : Int, b : Int, t : Double) -> Int {
  byte((a.to_double() + (b - a).to_double() * t).to_int())
}

///|
pub extend Clipped with Debug::{to_repr}

///|
pub extend Clipped with Eq::{not_equal, equal}

///|
pub extend Color with Debug::{to_repr}

///|
pub extend Color with Eq::{not_equal, equal}

///|
pub extend Corner with Debug::{to_repr}

///|
pub extend Corner with Eq::{not_equal, equal}

///|
pub extend Family with Debug::{to_repr}

///|
pub extend Family with Eq::{not_equal, equal}

///|
pub extend FontId with Debug::{to_repr}

///|
pub extend FontId with Eq::{not_equal, equal}

///|
pub extend Galley with Debug::{to_repr}

///|
pub extend Galley with Eq::{not_equal, equal}

///|
pub extend Shape with Debug::{to_repr}

///|
pub extend Shape with Eq::{not_equal, equal}

///|
pub extend Stroke with Debug::{to_repr}

///|
pub extend Stroke with Eq::{not_equal, equal}

///|
pub extend TextRow with Debug::{to_repr}

///|
pub extend TextRow with Eq::{not_equal, equal}
