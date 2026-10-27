// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A point, or an offset, or a size: two numbers whose meaning comes from where
/// they are used. egui makes the same choice, and it is what lets a rectangle be
/// described as a corner plus a size without two nearly identical types.
pub(all) struct Vec2 {
  x : Double
  y : Double
} derive(Eq, Debug)

///|
/// The origin, the zero offset, and the empty size.
pub let zero : Vec2 = { x: 0, y: 0, }

///|
/// Both components the same, which is the common case for spacing.
pub fn Vec2::splat(value : Double) -> Vec2 {
  { x: value, y: value, }
}

///|
pub impl Add for Vec2 with fn add(self, other) {
  { x: self.x + other.x, y: self.y + other.y, }
}

///|
pub impl Sub for Vec2 with fn sub(self, other) {
  { x: self.x - other.x, y: self.y - other.y, }
}

///|
pub impl Neg for Vec2 with fn neg(self) {
  { x: -self.x, y: -self.y, }
}

///|
/// Scale both components.
pub fn Vec2::scale(self : Vec2, factor : Double) -> Vec2 {
  { x: self.x * factor, y: self.y * factor, }
}

///|
/// The larger of each component.
pub fn Vec2::max(self : Vec2, other : Vec2) -> Vec2 {
  { x: larger(self.x, other.x), y: larger(self.y, other.y), }
}

///|
/// The smaller of each component.
pub fn Vec2::min(self : Vec2, other : Vec2) -> Vec2 {
  { x: smaller(self.x, other.x), y: smaller(self.y, other.y), }
}

///|
/// The distance from the origin.
pub fn Vec2::length(self : Vec2) -> Double {
  (self.x * self.x + self.y * self.y).sqrt()
}

///|
/// Where something sits inside the space it was given.
pub(all) enum Align {
  Min
  Center
  Max
} derive(Eq, Debug)

///|
/// The offset that aligns `size` inside `space` on one axis.
pub fn Align::offset(self : Align, space : Double, size : Double) -> Double {
  match self {
    Min => 0
    Center => (space - size) / 2
    Max => space - size
  }
}

///|
/// A rectangle, as a corner and the corner opposite.
///
/// Holding both corners rather than a corner and a size means the two questions
/// asked most often — where does it end, and does it contain this point — are
/// answered without arithmetic, and a rectangle can be empty without being
/// negative.
pub(all) struct Rect {
  min : Vec2
  max : Vec2
} derive(Eq, Debug)

///|
/// A rectangle with nothing in it, positioned nowhere.
pub let nothing : Rect = { min: zero, max: zero, }

///|
/// The rectangle between two corners, in either order.
pub fn Rect::of(a : Vec2, b : Vec2) -> Rect {
  { min: a.min(b), max: a.max(b), }
}

///|
/// The rectangle at `at` with this size.
pub fn Rect::at(at : Vec2, size : Vec2) -> Rect {
  { min: at, max: at + size, }
}

///|
/// A rectangle centred on a point.
pub fn Rect::around(centre : Vec2, size : Vec2) -> Rect {
  let half = size.scale(0.5)
  { min: centre - half, max: centre + half, }
}

///|
/// How wide the rectangle is.
pub fn Rect::width(self : Rect) -> Double {
  self.max.x - self.min.x
}

///|
/// How tall it is.
pub fn Rect::height(self : Rect) -> Double {
  self.max.y - self.min.y
}

///|
/// Its width and height.
pub fn Rect::size(self : Rect) -> Vec2 {
  self.max - self.min
}

///|
/// The point in the middle.
pub fn Rect::centre(self : Rect) -> Vec2 {
  (self.min + self.max).scale(0.5)
}

///|
/// True when the rectangle covers no area.
pub fn Rect::is_empty(self : Rect) -> Bool {
  self.max.x <= self.min.x || self.max.y <= self.min.y
}

///|
/// True when the point is inside, counting the near edges and not the far ones,
/// so that neighbouring rectangles do not both claim a point on their border.
pub fn Rect::contains(self : Rect, point : Vec2) -> Bool {
  point.x >= self.min.x &&
  point.x < self.max.x &&
  point.y >= self.min.y &&
  point.y < self.max.y
}

///|
/// The part of the rectangle that is also in the other one.
pub fn Rect::intersect(self : Rect, other : Rect) -> Rect {
  let min = self.min.max(other.min)
  let max = self.max.min(other.max)
  { min, max: max.max(min), }
}

///|
/// The smallest rectangle holding both. An empty operand is ignored, so a
/// bounding box can be grown from nothing.
pub fn Rect::union(self : Rect, other : Rect) -> Rect {
  if self.is_empty() {
    return other
  }
  if other.is_empty() {
    return self
  }
  { min: self.min.min(other.min), max: self.max.max(other.max), }
}

///|
/// Move the rectangle.
pub fn Rect::translate(self : Rect, by : Vec2) -> Rect {
  { min: self.min + by, max: self.max + by, }
}

///|
/// Pull all four edges inwards.
pub fn Rect::shrink(self : Rect, by : Double) -> Rect {
  let inset = Vec2::splat(by)
  let min = self.min + inset
  { min, max: (self.max - inset).max(min), }
}

///|
/// Push all four edges outwards.
pub fn Rect::grow(self : Rect, by : Double) -> Rect {
  let inset = Vec2::splat(by)
  { min: self.min - inset, max: self.max + inset, }
}

///|
/// The nearest point inside the rectangle.
pub fn Rect::clamp(self : Rect, point : Vec2) -> Vec2 {
  {
    x: clamp(point.x, self.min.x, self.max.x),
    y: clamp(point.y, self.min.y, self.max.y),
  }
}

///|
/// Space around something: the four edges, in the CSS order.
pub(all) struct Margin {
  top : Double
  right : Double
  bottom : Double
  left : Double
} derive(Eq, Debug)

///|
/// The same margin on every edge.
pub fn Margin::same(value : Double) -> Margin {
  { top: value, right: value, bottom: value, left: value, }
}

///|
/// A margin with nothing on any edge.
pub let no_margin : Margin = { top: 0, right: 0, bottom: 0, left: 0, }

///|
/// The total margin across each axis.
pub fn Margin::sum(self : Margin) -> Vec2 {
  { x: self.left + self.right, y: self.top + self.bottom, }
}

///|
/// Pull a rectangle's edges in by this margin.
pub fn Margin::shrink_rect(self : Margin, rect : Rect) -> Rect {
  let min = { x: rect.min.x + self.left, y: rect.min.y + self.top, }
  let max = { x: rect.max.x - self.right, y: rect.max.y - self.bottom, }
  { min, max: max.max(min), }
}

///|
/// Push a rectangle's edges out by this margin.
pub fn Margin::grow_rect(self : Margin, rect : Rect) -> Rect {
  {
    min: { x: rect.min.x - self.left, y: rect.min.y - self.top, },
    max: { x: rect.max.x + self.right, y: rect.max.y + self.bottom, },
  }
}

///|
/// A number between two others, moved so it is.
pub fn clamp(value : Double, low : Double, high : Double) -> Double {
  if high < low {
    return low
  }
  if value < low {
    low
  } else if value > high {
    high
  } else {
    value
  }
}

///|
/// Where `value` sits between `low` and `high`, from zero to one.
pub fn inverse_lerp(value : Double, low : Double, high : Double) -> Double {
  if high == low {
    0
  } else {
    clamp((value - low) / (high - low), 0, 1)
  }
}

///|
/// The number `t` of the way from `low` to `high`.
pub fn lerp(low : Double, high : Double, t : Double) -> Double {
  low + (high - low) * t
}

///|
fn larger(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn smaller(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
pub extend Align with Debug::{to_repr}

///|
pub extend Align with Eq::{not_equal, equal}

///|
pub extend Margin with Debug::{to_repr}

///|
pub extend Margin with Eq::{not_equal, equal}

///|
pub extend Rect with Debug::{to_repr}

///|
pub extend Rect with Eq::{not_equal, equal}

///|
pub extend Vec2 with Debug::{to_repr}

///|
pub extend Vec2 with Add::{add}

///|
pub extend Vec2 with Eq::{not_equal, equal}

///|
pub extend Vec2 with Neg::{neg}

///|
pub extend Vec2 with Sub::{sub}
