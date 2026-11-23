// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Draw a string.
///
/// A label is inert: the pointer passes through it to whatever is underneath,
/// which is what lets a label be drawn over a panel without stealing its
/// clicks. Ask for another sense when the label is meant to be interacted with.
pub fn label(
  ui : @ctx.Ui,
  string : String,
  color? : @paint.Color,
  wrap~ : Bool = false,
  sense~ : @hit.Sense = @hit.inert,
) -> @hit.Response {
  let style = ui.style()
  let laid = if wrap {
    @text.layout(ui.ctx().backend(), string, style.font, wrap=ui.available().x)
  } else {
    galley(ui, string)
  }
  let (rect, response) = ui.allocate(laid.size, sense, string)
  let ink = match color {
    Some(value) => value
    None => style.text_for(response)
  }
  ui.painter().galley(rect.min, laid, ink)
  response
}

///|
/// Draw a string in the weaker of the two text colours, for the things a reader
/// should be able to ignore.
pub fn weak(ui : @ctx.Ui, string : String) -> @hit.Response {
  label(ui, string, color=ui.style().weak_text)
}

///|
/// Draw a string larger than the body text.
pub fn heading(ui : @ctx.Ui, string : String) -> @hit.Response {
  let style = ui.style()
  let laid = galley_in(ui, string, style.font_of(Heading))
  let (rect, response) = ui.allocate(laid.size, @hit.inert, string)
  ui.painter().galley(rect.min, laid, style.text)
  response
}

///|
/// Draw a small string in the colour a reader is expected to skim.
pub fn caption(ui : @ctx.Ui, string : String) -> @hit.Response {
  let style = ui.style()
  let laid = galley_in(ui, string, style.font_of(Caption))
  let (rect, response) = ui.allocate(laid.size, @hit.inert, string)
  ui.painter().galley(rect.min, laid, style.weak_text)
  response
}

///|
/// How tall a separator is, the gap below it included.
pub fn separator_height(ui : @ctx.Ui) -> Double {
  most(1, ui.style().outline.width) + ui.style().spacing.y
}

///|
/// Draw a rule across the region.
pub fn separator(ui : @ctx.Ui) -> @hit.Response {
  rule(ui, ui.style().outline.color)
}

///|
/// Draw a rule of a given colour, for a separator that has to say something.
pub fn coloured_rule(ui : @ctx.Ui, color : @paint.Color) -> @hit.Response {
  rule(ui, color)
}

///|
fn rule(ui : @ctx.Ui, color : @paint.Color) -> @hit.Response {
  let thickness = most(1, ui.style().outline.width)
  let rect = ui.allocate_space({ x: ui.available().x, y: separator_height(ui), })
  let y = rect.min.y + (rect.height() - thickness) / 2
  ui
  .painter()
  .rect(
    @emath.Rect::of({ x: rect.min.x, y, }, { x: rect.max.x, y: y + thickness, }),
    fill=color,
  )
  @hit.Response::none(ui.id(), rect)
}
