// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// How big a button with this label is.
pub fn button_size(ui : @ctx.Ui, string : String) -> @emath.Vec2 {
  control_size(ui, galley(ui, string).size)
}

///|
/// A button with a label on it.
///
/// The return is the whole answer: ask it whether it was clicked. Nothing is
/// registered, nothing is called back, and the code that reacts to the click
/// sits directly under the code that drew the button.
pub fn button(ui : @ctx.Ui, string : String) -> @hit.Response {
  let style = ui.style()
  let laid = galley(ui, string)
  let (rect, hit) = ui.allocate(button_size(ui, string), @hit.click, string)
  let response = with_click(hit, activated(ui, hit))
  let painter = ui.painter()
  painter.rect(
    rect,
    fill=style.fill_for(response),
    stroke=style.outline_for(response),
    corner=@paint.Corner::same(style.corner),
  )
  painter.galley(centred(rect, laid.size), laid, style.text_for(response))
  response
}

///|
/// A button drawn in the accent colour, for the one action a screen is about.
pub fn accent_button(ui : @ctx.Ui, string : String) -> @hit.Response {
  let style = ui.style()
  let laid = galley(ui, string)
  let (rect, hit) = ui.allocate(button_size(ui, string), @hit.click, string)
  let response = with_click(hit, activated(ui, hit))
  let fill = if !response.enabled {
    style.surface
  } else if response.pressed {
    style.accent.lerp(style.text, 0.2)
  } else if response.hovered {
    style.accent.lerp(style.text, 0.1)
  } else {
    style.accent
  }
  let painter = ui.painter()
  painter.rect(
    rect,
    fill~,
    stroke=style.outline_for(response),
    corner=@paint.Corner::same(style.corner),
  )
  painter.galley(centred(rect, laid.size), laid, style.background)
  response
}

///|
/// A button with no ground until the pointer is on it, for the actions that
/// should not compete with the rest of the screen.
pub fn quiet_button(ui : @ctx.Ui, string : String) -> @hit.Response {
  let style = ui.style()
  let laid = galley(ui, string)
  let (rect, hit) = ui.allocate(button_size(ui, string), @hit.click, string)
  let response = with_click(hit, activated(ui, hit))
  let painter = ui.painter()
  if response.hovered || response.pressed {
    painter.rect(
      rect,
      fill=style.fill_for(response),
      corner=@paint.Corner::same(style.corner),
    )
  }
  painter.galley(centred(rect, laid.size), laid, style.text_for(response))
  response
}

///|
/// How big a tick box or a radio button with this label is.
pub fn choice_size(ui : @ctx.Ui, string : String) -> @emath.Vec2 {
  let style = ui.style()
  let laid = galley(ui, string)
  let side = most(12, ui.line_height() * 0.8)
  control_size(ui, {
    x: side + style.spacing.x + laid.size.x,
    y: most(side, laid.size.y),
  })
}

///|
/// The side of the box a tick or a dot goes in.
fn choice_side(ui : @ctx.Ui) -> Double {
  most(12, ui.line_height() * 0.8)
}

///|
/// A box that is either ticked or not, with a label beside it.
///
/// The value goes in and the new value comes out, so a caller holds its own
/// state and this holds none: `checked = checkbox(ui, "Wrap", checked).0`.
pub fn checkbox(
  ui : @ctx.Ui,
  string : String,
  checked : Bool,
) -> (Bool, @hit.Response) {
  let style = ui.style()
  let laid = galley(ui, string)
  let side = choice_side(ui)
  let (rect, hit) = ui.allocate(choice_size(ui, string), @hit.click, string)
  let clicked = hit.clicked || activated(ui, hit)
  let response = with_click(hit, clicked)
  let value = if clicked { !checked } else { checked }
  if clicked {
    response.mark_changed()
  }
  let box = @emath.Rect::at(
    left_of(rect, @emath.Vec2::splat(side), style.padding.x),
    @emath.Vec2::splat(side),
  )
  let painter = ui.painter()
  painter.rect(
    box,
    fill=style.fill_for(response),
    stroke=style.outline_for(response),
    corner=@paint.Corner::same(style.corner / 2),
  )
  if value {
    let tick = style.accent
    painter.path(
      [
        { x: box.min.x + side * 0.22, y: box.min.y + side * 0.52, },
        { x: box.min.x + side * 0.42, y: box.min.y + side * 0.74, },
        { x: box.min.x + side * 0.78, y: box.min.y + side * 0.28, },
      ],
      stroke=@paint.Stroke::new(most(2, side / 8), tick),
    )
  }
  painter.galley(
    {
      x: box.max.x + style.spacing.x,
      y: rect.min.y + (rect.height() - laid.size.y) / 2,
    },
    laid,
    style.text_for(response),
  )
  (value, response)
}

///|
/// One of a set of choices: ticked when `value` is the one this button stands
/// for, and returning that one when it is chosen.
pub fn radio(
  ui : @ctx.Ui,
  string : String,
  chosen : Bool,
) -> (Bool, @hit.Response) {
  let style = ui.style()
  let laid = galley(ui, string)
  let side = choice_side(ui)
  let (rect, hit) = ui.allocate(choice_size(ui, string), @hit.click, string)
  let clicked = hit.clicked || activated(ui, hit)
  let response = with_click(hit, clicked)
  let value = chosen || clicked
  if clicked && !chosen {
    response.mark_changed()
  }
  let box = @emath.Rect::at(
    left_of(rect, @emath.Vec2::splat(side), style.padding.x),
    @emath.Vec2::splat(side),
  )
  let painter = ui.painter()
  painter.circle(
    box.centre(),
    side / 2,
    fill=style.fill_for(response),
    stroke=style.outline_for(response),
  )
  if value {
    painter.circle(box.centre(), side / 4, fill=style.accent)
  }
  painter.galley(
    {
      x: box.max.x + style.spacing.x,
      y: rect.min.y + (rect.height() - laid.size.y) / 2,
    },
    laid,
    style.text_for(response),
  )
  (value, response)
}
