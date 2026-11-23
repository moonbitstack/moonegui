// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// How wide the knob of a switch is.
fn knob(ui : @ctx.Ui) -> Double {
  most(12, ui.line_height() * 0.8)
}

///|
/// How big a switch is.
pub fn switch_size(ui : @ctx.Ui) -> @emath.Vec2 {
  let side = knob(ui)
  control_size(ui, { x: side * 2, y: side, })
}

///|
/// A switch: a track with a knob at one end or the other.
///
/// It is the same question as a tick box — on or off — asked where a row is too
/// busy for a box and a label: a settings list usually wants this and a form
/// usually wants the box.
pub fn switch(
  ui : @ctx.Ui,
  value : Bool,
  salt~ : String = "switch",
) -> (Bool, @hit.Response) {
  let style = ui.style()
  let side = knob(ui)
  let (rect, hit) = ui.allocate(switch_size(ui), @hit.click, salt)
  let clicked = hit.clicked || activated(ui, hit)
  let response = with_click(hit, clicked)
  let out = if clicked { !value } else { value }
  if clicked {
    response.mark_changed()
  }
  let track = @emath.Rect::at(centred(rect, { x: side * 2, y: side, }), {
    x: side * 2,
    y: side,
  })
  let fill = if !response.enabled {
    style.surface
  } else if out {
    style.accent
  } else {
    style.fill_for(response)
  }
  let painter = ui.painter()
  painter.rect(
    track,
    fill~,
    stroke=style.outline_for(response),
    corner=@paint.Corner::same(side / 2),
  )
  let middle = track.centre().y
  let at = if out { track.max.x - side / 2 } else { track.min.x + side / 2 }
  painter.circle(
    { x: at, y: middle, },
    side / 2 - 2,
    fill=if out { style.background } else { style.weak_text },
  )
  (out, response)
}
