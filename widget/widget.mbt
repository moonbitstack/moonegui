// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What every widget here does with a string: lay it out as one row in the
/// style's font.
fn galley(ui : @ctx.Ui, string : String) -> @paint.Galley {
  @text.line(ui.ctx().backend(), string, ui.style().font)
}

///|
/// The size a widget with this much content wants: the content plus its
/// padding, and never shorter than a pointer can comfortably hit.
fn wants(ui : @ctx.Ui, content : @emath.Vec2) -> @emath.Vec2 {
  let style = ui.style()
  {
    x: content.x + style.padding.x * 2,
    y: most(style.min_height, content.y + style.padding.y * 2),
  }
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
  input.key_pressed(Enter) || input.key_pressed(Space)
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
