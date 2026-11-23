// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// How much room the chevron of a folding header takes.
fn marker(ui : @ctx.Ui) -> Double {
  most(10, ui.line_height() * 0.7)
}

///|
/// How big the header of a folding section is.
pub fn group_header_size(ui : @ctx.Ui, title : String) -> @emath.Vec2 {
  let style = ui.style()
  control_size(ui, {
    x: marker(ui) + style.spacing.x + text_size(ui, title).x,
    y: text_size(ui, title).y,
  })
}

///|
/// The header of a section that folds away, with a chevron that says which way
/// it is.
pub fn group_header(
  ui : @ctx.Ui,
  title : String,
  open : Bool,
  salt~ : String = "group",
) -> (Bool, @hit.Response) {
  let style = ui.style()
  let laid = galley(ui, title)
  let (rect, hit) = ui.allocate(group_header_size(ui, title), @hit.click, salt)
  let clicked = hit.clicked || activated(ui, hit)
  let response = with_click(hit, clicked)
  let out = if clicked { !open } else { open }
  if clicked {
    response.mark_changed()
  }
  let painter = ui.painter()
  let size = marker(ui)
  let at = left_of(rect, @emath.Vec2::splat(size), style.padding.x + size / 4)
  let middle = at.y + size / 2
  let points : Array[@emath.Vec2] = if out {
    [
      { x: at.x, y: middle - 2, },
      { x: at.x + size, y: middle - 2, },
      { x: at.x + size / 2, y: middle + size / 3, },
    ]
  } else {
    [
      { x: at.x + 2, y: middle - size / 2, },
      { x: at.x + 2, y: middle + size / 2, },
      { x: at.x + size * 0.8, y: middle, },
    ]
  }
  painter.path(
    points,
    closed=true,
    fill=if response.hovered { style.text } else { style.weak_text },
  )
  painter.galley(
    {
      x: at.x + size + style.spacing.x,
      y: rect.min.y + (rect.height() - laid.size.y) / 2,
    },
    laid,
    style.text_for(response),
  )
  (out, response)
}

///|
/// A header and, when it is open, what is under it.
pub fn group(
  ui : @ctx.Ui,
  title : String,
  open : Bool,
  body : (@ctx.Ui) -> Unit,
  salt~ : String = "group",
) -> (Bool, @hit.Response) {
  let (out, response) = group_header(ui, title, open, salt~)
  if out {
    body(ui)
  }
  (out, response)
}
