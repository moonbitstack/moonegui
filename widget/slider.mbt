// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// How much of the range an arrow key moves the handle.
const STEPS : Double = 20

///|
/// A handle on a track, dragged to choose a number between two others.
///
/// Dragging is what a slider is for, and a drag is the one interaction that
/// cannot be answered from a single frame: the pointer is matched to the handle
/// on the frame the button went down, and every frame after that belongs to the
/// same handle whether the pointer is still over it or not.
pub fn slider(
  ui : @ctx.Ui,
  value : Double,
  low? : Double = 0,
  high? : Double = 1,
  width? : Double = 160,
  salt? : String = "slider",
) -> (Double, @hit.Response) {
  let style = ui.style()
  let height = most(style.min_height, ui.line_height())
  let (rect, response) = ui.allocate(
    { x: width, y: height, },
    @hit.click_and_drag,
    salt,
  )
  let radius = height / 3
  let left = rect.min.x + radius
  let right = rect.max.x - radius
  let mut out = value
  if response.enabled && (response.dragged || response.pressed) {
    match ui.ctx().input().pointer() {
      Some(at) =>
        out = @emath.lerp(low, high, @emath.inverse_lerp(at.x, left, right))
      None => ()
    }
  }
  if response.enabled && response.focused {
    let step = (high - low) / STEPS
    let input = ui.ctx().input()
    if input.key_pressed(@input.Key::Left) {
      out = out - step
    }
    if input.key_pressed(@input.Key::Right) {
      out = out + step
    }
    if input.key_pressed(@input.Key::Home) {
      out = low
    }
    if input.key_pressed(@input.Key::End) {
      out = high
    }
  }
  out = @emath.clamp(out, low, high)
  if out != value {
    response.mark_changed()
  }
  let at = @emath.lerp(left, right, @emath.inverse_lerp(out, low, high))
  let middle = rect.centre().y
  let track = @emath.Rect::of({ x: left, y: middle - 2, }, {
    x: right,
    y: middle + 2,
  })
  let painter = ui.painter()
  painter.rect(track, fill=style.surface, corner=@paint.Corner::same(2))
  if at > left {
    painter.rect(
      @emath.Rect::of({ x: left, y: middle - 2, }, { x: at, y: middle + 2, }),
      fill=style.accent,
      corner=@paint.Corner::same(2),
    )
  }
  painter.circle(
    { x: at, y: middle, },
    radius,
    fill=style.fill_for(response),
    stroke=style.outline_for(response),
  )
  (out, response)
}

///|
/// A slider with its value written beside it, which is what a number worth
/// dragging usually deserves.
pub fn slider_with_label(
  ui : @ctx.Ui,
  string : String,
  value : Double,
  low? : Double = 0,
  high? : Double = 1,
  width? : Double = 160,
) -> (Double, @hit.Response) {
  let mut out = value
  let mut response = @hit.Response::none(ui.id(), ui.used())
  // The row is given the height of the tallest thing in it: a row filling the
  // whole region would centre its contents against the region rather than
  // against one another.
  let height = most(ui.style().min_height, ui.line_height())
  ui.child(
    @layout.centred_row,
    fn(row) {
      let (moved, answer) = slider(row, value, low~, high~, width~, salt=string)
      out = moved
      response = answer
      label(row, string) |> ignore
    },
    size=Some({ x: ui.available().x, y: height, }),
    salt=string,
  )
  |> ignore
  (out, response)
}
