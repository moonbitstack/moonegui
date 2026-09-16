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
  color? : @paint.Color? = None,
  wrap? : Bool = false,
  sense? : @hit.Sense = @hit.inert,
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
  label(ui, string, color=Some(ui.style().weak_text))
}

///|
/// Draw a string larger than the body text.
pub fn heading(ui : @ctx.Ui, string : String) -> @hit.Response {
  let style = ui.style()
  let font : @paint.FontId = { ..style.font, size: style.font.size * 1.5, }
  let laid = @text.line(ui.ctx().backend(), string, font)
  let (rect, response) = ui.allocate(laid.size, @hit.inert, string)
  ui.painter().galley(rect.min, laid, style.text)
  response
}

///|
/// Draw a rule across the region.
pub fn separator(ui : @ctx.Ui) -> @hit.Response {
  let style = ui.style()
  let thickness = most(1, style.outline.width)
  let rect = ui.allocate_space({
    x: ui.available().x,
    y: thickness + style.spacing.y,
  })
  let y = rect.min.y + (rect.height() - thickness) / 2
  ui
  .painter()
  .rect(
    @emath.Rect::of({ x: rect.min.x, y, }, { x: rect.max.x, y: y + thickness, }),
    fill=style.outline.color,
  )
  @hit.Response::none(ui.id(), rect)
}
