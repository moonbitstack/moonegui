// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Which way widgets are laid out.
pub(all) enum Dir {
  LeftToRight
  RightToLeft
  TopDown
  BottomUp
} derive(Eq, Debug)

///|
/// True when the direction runs along the horizontal axis.
pub fn Dir::is_horizontal(self : Dir) -> Bool {
  match self {
    LeftToRight => true
    RightToLeft => true
    _ => false
  }
}

///|
/// How a region places what is put in it.
pub(all) struct Layout {
  dir : Dir
  /// Where a widget narrower than the region sits across the direction of flow.
  cross : @emath.Align
  /// Whether a widget is stretched to the full width across that direction
  /// instead of being aligned within it.
  cross_justify : Bool
} derive(Eq, Debug)

///|
/// Widgets stacked downwards, each as wide as it asks to be.
pub let top_down : Layout = { dir: TopDown, cross: Min, cross_justify: false, }

///|
/// Widgets stacked downwards, each stretched to the full width.
pub let top_down_justified : Layout = {
  dir: TopDown,
  cross: Min,
  cross_justify: true,
}

///|
/// Widgets in a row, aligned on their tops.
pub let left_to_right : Layout = {
  dir: LeftToRight,
  cross: Min,
  cross_justify: false,
}

///|
/// A row whose widgets are centred on one another.
pub let centred_row : Layout = {
  dir: LeftToRight,
  cross: Center,
  cross_justify: false,
}

///|
/// Where a region has got to.
pub struct Region {
  /// Everything allocated so far.
  mut used : @emath.Rect
  /// Everything it is allowed to use.
  max : @emath.Rect
  /// The corner the next widget starts at.
  mut cursor : @emath.Vec2
}

///|
/// Hands out rectangles inside a region, in the layout's direction.
pub struct Placer {
  layout : Layout
  region : Region
  spacing : @emath.Vec2
}

///|
/// A placer that fills this rectangle.
pub fn Placer::new(
  max : @emath.Rect,
  layout? : Layout = top_down,
  spacing? : @emath.Vec2 = { x: 8, y: 6, },
) -> Placer {
  let cursor : @emath.Vec2 = match layout.dir {
    LeftToRight => max.min
    TopDown => max.min
    RightToLeft => { x: max.max.x, y: max.min.y, }
    BottomUp => { x: max.min.x, y: max.max.y, }
  }
  {
    layout,
    region: { used: @emath.Rect::of(cursor, cursor), max, cursor, },
    spacing,
  }
}

///|
/// How much room is left in the direction of flow.
pub fn Placer::available(self : Placer) -> @emath.Vec2 {
  let max = self.region.max
  let cursor = self.region.cursor
  match self.layout.dir {
    LeftToRight => { x: max.max.x - cursor.x, y: max.height(), }
    RightToLeft => { x: cursor.x - max.min.x, y: max.height(), }
    TopDown => { x: max.width(), y: max.max.y - cursor.y, }
    BottomUp => { x: max.width(), y: cursor.y - max.min.y, }
  }
}

///|
/// Take a rectangle of this size, and move the cursor past it.
///
/// The size asked for is what the widget wants; what it gets is that size
/// aligned — or stretched, when the layout justifies — across the direction of
/// flow. A widget that asks for more than is left still gets what it asked for:
/// clipping is the caller's business, and a layout that silently shrank things
/// would be harder to reason about than one that overflows visibly.
pub fn Placer::allocate(self : Placer, want : @emath.Vec2) -> @emath.Rect {
  let region = self.region
  let max = region.max
  let horizontal = self.layout.dir.is_horizontal()
  let cross_room = if horizontal { max.height() } else { max.width() }
  let cross_size = if self.layout.cross_justify {
    cross_room
  } else if horizontal {
    want.y
  } else {
    want.x
  }
  let cross_offset = if self.layout.cross_justify {
    0.0
  } else {
    self.layout.cross.offset(cross_room, cross_size)
  }
  let size : @emath.Vec2 = if horizontal {
    { x: want.x, y: cross_size, }
  } else {
    { x: cross_size, y: want.y, }
  }
  let at : @emath.Vec2 = match self.layout.dir {
    LeftToRight => { x: region.cursor.x, y: max.min.y + cross_offset, }
    RightToLeft => { x: region.cursor.x - size.x, y: max.min.y + cross_offset, }
    TopDown => { x: max.min.x + cross_offset, y: region.cursor.y, }
    BottomUp => { x: max.min.x + cross_offset, y: region.cursor.y - size.y, }
  }
  let rect = @emath.Rect::at(at, size)
  self.advance(rect)
  rect
}

///|
/// Move the cursor past a rectangle that was placed by other means.
pub fn Placer::advance(self : Placer, rect : @emath.Rect) -> Unit {
  let region = self.region
  region.used = region.used.union(rect)
  region.cursor = match self.layout.dir {
    LeftToRight => { x: rect.max.x + self.spacing.x, y: region.cursor.y, }
    RightToLeft => { x: rect.min.x - self.spacing.x, y: region.cursor.y, }
    TopDown => { x: region.cursor.x, y: rect.max.y + self.spacing.y, }
    BottomUp => { x: region.cursor.x, y: rect.min.y - self.spacing.y, }
  }
}

///|
/// Everything placed so far.
pub fn Placer::used(self : Placer) -> @emath.Rect {
  self.region.used
}

///|
/// The rectangle the placer may use.
pub fn Placer::max(self : Placer) -> @emath.Rect {
  self.region.max
}

///|
/// Where the next widget will start.
pub fn Placer::cursor(self : Placer) -> @emath.Vec2 {
  self.region.cursor
}

///|
/// The gap left between widgets.
pub fn Placer::spacing(self : Placer) -> @emath.Vec2 {
  self.spacing
}

///|
/// How this placer places things.
pub fn Placer::layout(self : Placer) -> Layout {
  self.layout
}

///|
/// A placer for a nested region, which starts where this one has got to.
pub fn Placer::child(
  self : Placer,
  layout : Layout,
  size? : @emath.Vec2? = None,
) -> Placer {
  let room = self.available()
  let want = match size {
    Some(value) => value
    None => room
  }
  let at : @emath.Vec2 = match self.layout.dir {
    RightToLeft =>
      { x: self.region.cursor.x - want.x, y: self.region.cursor.y, }
    BottomUp => { x: self.region.cursor.x, y: self.region.cursor.y - want.y, }
    _ => self.region.cursor
  }
  Placer::new(@emath.Rect::at(at, want), layout~, spacing=self.spacing)
}
