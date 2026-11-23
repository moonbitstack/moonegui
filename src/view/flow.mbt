// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Where the children of a row or a column sit when they do not fill it.
#derive(Eq, Debug)
pub(all) enum Justify {
  Start
  Center
  End
  /// The gaps between children grow until they fill the space, and the two
  /// ends stay put.
  SpaceBetween
}

///|
/// How a row, a column or a grid places its children.
///
/// The gap is optional because the common answer is the style's own spacing:
/// a tree whose rows leave the style's gap between their children sits on the
/// same grid as the widgets around it without anyone writing the number twice.
#derive(Eq, Debug)
pub(all) struct Flow {
  dir : @layout.Dir
  gap : Double?
  padding : Double
  /// Where a child narrower than the line sits across the direction of flow.
  cross : @emath.Align
  justify : Justify
  /// Whether children are stretched across the direction of flow.
  stretch : Bool
}

///|
/// Children side by side.
pub let row_flow : Flow = {
  dir: LeftToRight,
  gap: None,
  padding: 0,
  cross: Min,
  justify: Start,
  stretch: false,
}

///|
/// Children stacked downwards.
pub let column_flow : Flow = {
  dir: TopDown,
  gap: None,
  padding: 0,
  cross: Min,
  justify: Start,
  stretch: false,
}

///|
/// The same flow with a gap of its own.
pub fn Flow::with_gap(self : Flow, gap : Double) -> Flow {
  { ..self, gap: Some(gap), }
}

///|
/// The same flow with room around its children.
pub fn Flow::with_padding(self : Flow, padding : Double) -> Flow {
  { ..self, padding, }
}

///|
/// The same flow with its children aligned differently across it.
pub fn Flow::with_cross(self : Flow, cross : @emath.Align) -> Flow {
  { ..self, cross, }
}

///|
/// The same flow with its children placed differently along it.
pub fn Flow::with_justify(self : Flow, justify : Justify) -> Flow {
  { ..self, justify, }
}

///|
/// The same flow with its children stretched across it, or not.
pub fn Flow::with_stretch(self : Flow, stretch : Bool) -> Flow {
  { ..self, stretch, }
}

///|
/// The gap this flow leaves, which is the style's when it has none of its own.
pub fn Flow::gap_of(self : Flow, style : @ctx.Style) -> Double {
  match self.gap {
    Some(value) => value
    None =>
      if self.dir.is_horizontal() {
        style.spacing.x
      } else {
        style.spacing.y
      }
  }
}

///|
/// How big something may be.
///
/// The maximum is a number rather than an option because a maximum that is not
/// there is a maximum nothing reaches, and one sentinel is easier to compare
/// and to print than an optional inside every measurement.
#derive(Eq, Debug)
pub(all) struct Bounds {
  min : @emath.Vec2
  max : @emath.Vec2
}

///|
/// A huge maximum: nothing is cut.
pub let open_bounds : @emath.Vec2 = @emath.Vec2::splat(1.0e9)

///|
/// No bounds at all.
pub let unbounded : Bounds = {
  min: @emath.Vec2::splat(0),
  max: @emath.Vec2::splat(1.0e9),
}

///|
/// No smaller than this and no bigger than that.
pub fn Bounds::new(
  min~ : @emath.Vec2 = @emath.Vec2::splat(0),
  max~ : @emath.Vec2 = @emath.Vec2::splat(1.0e9),
) -> Bounds {
  { min, max, }
}

///|
/// At least this big.
pub fn Bounds::at_least(min : @emath.Vec2) -> Bounds {
  { min, max: @emath.Vec2::splat(1.0e9), }
}

///|
/// At most this big.
pub fn Bounds::at_most(max : @emath.Vec2) -> Bounds {
  { min: @emath.Vec2::splat(0), max, }
}

///|
/// This size held inside the bounds.
pub fn Bounds::hold(self : Bounds, size : @emath.Vec2) -> @emath.Vec2 {
  {
    x: @emath.clamp(size.x, self.min.x, self.max.x),
    y: @emath.clamp(size.y, self.min.y, self.max.y),
  }
}

///|
/// What is left for the next child of a flow, once this much has gone.
///
/// A child is measured against what is left rather than against the whole
/// line: a grid asks for all the room it is offered, and offering it the whole
/// line would let the second child of a row push the row past the window.
pub fn child_room(
  room : @emath.Vec2,
  horizontal : Bool,
  used : Double,
) -> @emath.Vec2 {
  let left = if used > 0 { used } else { 0 }
  if horizontal {
    {
      x: if room.x < 1.0e9 {
        if room.x > left {
          room.x - left
        } else {
          0
        }
      } else {
        room.x
      },
      y: room.y,
    }
  } else {
    {
      x: room.x,
      y: if room.y < 1.0e9 {
        if room.y > left {
          room.y - left
        } else {
          0
        }
      } else {
        room.y
      },
    }
  }
}

///|
/// True when the room is wide enough to lay out against it.
pub fn is_finite(room : @emath.Vec2) -> Bool {
  room.x < 1.0e9 && room.y < 1.0e9
}
