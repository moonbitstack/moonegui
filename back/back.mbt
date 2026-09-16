// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What a backend has to be able to do.
///
/// Three of these measure and nine draw. Everything else a user interface needs
/// — layout, interaction, state — is above this line and shared by every
/// backend, which is the whole point of drawing the line here.
pub(open) trait Backend {
  /// How much room a string takes in this font.
  fn measure(Self, String, @paint.FontId) -> @emath.Vec2
  /// The distance between the tops of two consecutive lines.
  fn line_height(Self, @paint.FontId) -> Double
  /// The longest prefix of the string that fits in this width, as a code unit
  /// index. Line breaking would otherwise ask `measure` once per candidate
  /// break, which is the difference between one call and hundreds.
  fn measure_prefix(Self, String, @paint.FontId, Double) -> Int
  fn push_clip(Self, @emath.Rect) -> Unit
  fn pop_clip(Self) -> Unit
  fn fill_rect(Self, @emath.Rect, @paint.Corner, @paint.Color) -> Unit
  fn stroke_rect(Self, @emath.Rect, @paint.Corner, @paint.Stroke) -> Unit
  fn fill_circle(Self, @emath.Vec2, Double, @paint.Color) -> Unit
  fn stroke_circle(Self, @emath.Vec2, Double, @paint.Stroke) -> Unit
  fn stroke_path(Self, Array[@emath.Vec2], Bool, @paint.Stroke) -> Unit
  fn fill_path(Self, Array[@emath.Vec2], @paint.Color) -> Unit
  fn fill_text(Self, @emath.Vec2, String, @paint.FontId, @paint.Color) -> Unit
}

///|
/// Hand a frame's shapes to a backend, in order.
///
/// A shape carries the rectangle it may draw inside, and the painter already
/// removed the ones that could not be seen, so this pushes a clip only when a
/// shape really straddles an edge.
pub fn play(shapes : Array[@paint.Clipped], back : &Backend) -> Unit {
  for item in shapes {
    let clipped = item.clip != @paint.unclipped
    if clipped {
      back.push_clip(item.clip)
    }
    draw(item.shape, back)
    if clipped {
      back.pop_clip()
    }
  }
}

///|
fn draw(shape : @paint.Shape, back : &Backend) -> Unit {
  match shape {
    Rect(rect~, corner~, fill~, stroke~) => {
      if !fill.is_clear() {
        back.fill_rect(rect, corner, fill)
      }
      if !stroke.is_empty() {
        back.stroke_rect(rect, corner, stroke)
      }
    }
    Circle(centre~, radius~, fill~, stroke~) => {
      if !fill.is_clear() {
        back.fill_circle(centre, radius, fill)
      }
      if !stroke.is_empty() {
        back.stroke_circle(centre, radius, stroke)
      }
    }
    Path(points~, closed~, fill~, stroke~) => {
      if !fill.is_clear() {
        back.fill_path(points, fill)
      }
      if !stroke.is_empty() {
        back.stroke_path(points, closed, stroke)
      }
    }
    Text(at~, galley~, color~) =>
      for row in galley.rows {
        back.fill_text(at + row.at, row.text, galley.font, color)
      }
    Image(rect~, tint~, ..) =>
      // An image is a rectangle until a backend that can load one says
      // otherwise; drawing its outline is more honest than drawing nothing.
      back.stroke_rect(rect, @paint.square, @paint.Stroke::new(1, tint))
  }
}
