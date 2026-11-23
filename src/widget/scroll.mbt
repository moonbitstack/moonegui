// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// How wide the bar of a scrolling area is.
pub fn scroll_bar_width() -> Double {
  6
}

///|
/// A region that shows part of something taller, with a bar that says how much
/// of it is showing.
///
/// The offset is the caller's state and the content's height is the caller's
/// answer, so this asks for both and gives back what the pointer and the wheel
/// did to them. What is drawn inside is clipped to the window, not to the whole
/// content, which is the one thing a scrolling region cannot express in terms
/// of where its children go.
pub fn scroll_area(
  ui : @ctx.Ui,
  offset : Double,
  height : Double,
  content_height : Double,
  body : (@ctx.Ui) -> Unit,
  salt~ : String = "scroll",
) -> (Double, @hit.Response) {
  let style = ui.style()
  let rect = ui.allocate_space({ x: ui.available().x, y: height, })
  let bar = scroll_bar_width()
  let over = content_height > height
  let inner = @emath.Rect::of(rect.min, {
    x: rect.max.x - (if over { bar + 2 } else { 0 }),
    y: rect.max.y,
  })
  let room = if over { content_height - height } else { 0.0 }
  let mut out = @emath.clamp(offset, 0, room)
  let input = ui.ctx().input()
  match input.pointer() {
    Some(at) =>
      if rect.contains(at) && input.scroll().y != 0 {
        out = @emath.clamp(out - input.scroll().y * ui.line_height(), 0, room)
      }
    None => ()
  }
  ui.cell(
    ui.next_id(salt + "#body"),
    inner.translate({ x: 0, y: -out, }),
    body,
    clip=inner,
  )
  let mut response = @hit.Response::none(ui.id(), rect)
  if over {
    let track = @emath.Rect::of({ x: rect.max.x - bar, y: rect.min.y, }, {
      x: rect.max.x,
      y: rect.max.y,
    })
    let thumb = most(24, track.height() * height / content_height)
    let travel = track.height() - thumb
    let at = if room == 0 { 0.0 } else { travel * (out / room) }
    let handle = @emath.Rect::of({ x: track.min.x, y: track.min.y + at, }, {
      x: track.max.x,
      y: track.min.y + at + thumb,
    })
    let hit = ui
      .ctx()
      .interact(
        ui.next_id(salt + "#bar"),
        handle,
        @hit.click_and_drag,
        enabled=ui.is_enabled(),
      )
    if (hit.dragged || hit.pressed) && travel > 0 {
      match input.pointer() {
        Some(spot) =>
          out = @emath.clamp(
            (spot.y - track.min.y - thumb / 2) / travel * room,
            0,
            room,
          )
        None => ()
      }
    }
    let ink = if hit.dragged || hit.hovered || hit.pressed {
      style.weak_text
    } else {
      style.outline.color
    }
    ui
    .painter()
    .rect(track, fill=style.surface, corner=@paint.Corner::same(bar / 2))
    ui
    .painter()
    .rect(
      @emath.Rect::of({ x: handle.min.x, y: handle.min.y, }, {
        x: handle.max.x,
        y: handle.max.y,
      }),
      fill=ink,
      corner=@paint.Corner::same(bar / 2),
    )
    response = hit
  }
  if out != offset {
    response.mark_changed()
  }
  (out, response)
}
