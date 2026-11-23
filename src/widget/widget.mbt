// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What every widget here does with a string: lay it out as one row in the
/// style's font.
fn galley(ui : @ctx.Ui, string : String) -> @paint.Galley {
  @text.line(ui.ctx().backend(), string, ui.style().font)
}

///|
/// The same, in a font other than the body's.
fn galley_in(
  ui : @ctx.Ui,
  string : String,
  font : @paint.FontId,
) -> @paint.Galley {
  @text.line(ui.ctx().backend(), string, font)
}

///|
/// How much room a string takes in the body font.
pub fn text_size(ui : @ctx.Ui, string : String) -> @emath.Vec2 {
  galley(ui, string).size
}

///|
/// How much room a string takes in a font of the caller's choosing.
pub fn text_size_in(
  ui : @ctx.Ui,
  string : String,
  font : @paint.FontId,
) -> @emath.Vec2 {
  galley_in(ui, string, font).size
}

///|
/// The size a control with this much content asks for: the content plus its
/// padding, and never shorter than a pointer can comfortably hit.
///
/// A widget asks for its size before it is placed, so the same answer has to be
/// available to whatever is doing the placing — a tree that is laid out before
/// it is drawn, most of all.
pub fn control_size(ui : @ctx.Ui, content : @emath.Vec2) -> @emath.Vec2 {
  let style = ui.style()
  {
    x: content.x + style.padding.x * 2,
    y: most(style.min_height, content.y + style.padding.y * 2),
  }
}

///|
/// How tall a control is, whatever is written on it.
pub fn control_height(ui : @ctx.Ui) -> Double {
  let style = ui.style()
  most(style.min_height, ui.line_height() + style.padding.y * 2)
}

///|
/// How tall a row of a list or a table is.
pub fn row_height(ui : @ctx.Ui) -> Double {
  control_height(ui)
}

///|
/// Where something of this size sits when centred in a rectangle.
fn centred(rect : @emath.Rect, size : @emath.Vec2) -> @emath.Vec2 {
  {
    x: rect.min.x + (rect.width() - size.x) / 2,
    y: rect.min.y + (rect.height() - size.y) / 2,
  }
}

///|
/// Where something of this size sits against the left edge, centred top to
/// bottom.
fn left_of(
  rect : @emath.Rect,
  size : @emath.Vec2,
  inset : Double,
) -> @emath.Vec2 {
  { x: rect.min.x + inset, y: rect.min.y + (rect.height() - size.y) / 2, }
}

///|
/// Whether the keyboard just activated a focused widget.
///
/// A button that can be reached with Tab has to be pressable with the keyboard
/// too, or the focus ring leads nowhere.
fn activated(ui : @ctx.Ui, response : @hit.Response) -> Bool {
  if !response.focused || !response.enabled {
    return false
  }
  let input = ui.ctx().input()
  input.key_pressed(@input.Key::Enter) || input.key_pressed(@input.Key::Space)
}

///|
fn most(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// A widget's response with the click it was given by the keyboard folded in.
fn with_click(response : @hit.Response, clicked : Bool) -> @hit.Response {
  if clicked {
    { ..response, clicked: true, }
  } else {
    response
  }
}

///|
/// A number written with this many digits after the point.
fn fixed(value : Double, digits : Int32) -> String {
  let mut unit = 1.0
  for _ in 0..<digits {
    unit = unit * 10.0
  }
  let units = (value * unit + 0.5).to_int()
  let scale = unit.to_int()
  let whole = units / scale
  let rest = units - whole * scale
  let out = StringBuilder()
  out.write_string(whole.to_string())
  if digits > 0 {
    out.write_string(".")
    let mut step = scale / 10
    while step > 0 {
      out.write_string((rest / step % 10).to_string())
      step = step / 10
    }
  }
  out.to_string()
}

///|
/// A rectangle one of a column of rows sits in, given the row's index.
fn row_rect(area : @emath.Rect, index : Int32, height : Double) -> @emath.Rect {
  let top = area.min.y + height * index.to_double()
  @emath.Rect::of({ x: area.min.x, y: top, }, {
    x: area.max.x,
    y: top + height,
  })
}
