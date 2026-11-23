// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// How tall the bar of a progress bar is.
fn bar_height(ui : @ctx.Ui) -> Double {
  most(6, ui.line_height() * 0.4)
}

///|
/// How big a progress bar is.
pub fn progress_size(
  ui : @ctx.Ui,
  width : Double,
  label~ : String = "",
) -> @emath.Vec2 {
  let bar = bar_height(ui)
  let under = if label == "" {
    0.0
  } else {
    ui.style().spacing.y + ui.line_height()
  }
  { x: width, y: bar + under, }
}

///|
/// How far along something is, from zero to one.
///
/// The fraction is the caller's; nothing here remembers anything, so a bar
/// reporting the progress of work happening elsewhere costs one number.
pub fn progress(
  ui : @ctx.Ui,
  fraction : Double,
  width~ : Double = 160,
  label~ : String = "",
) -> @hit.Response {
  let style = ui.style()
  let rect = ui.allocate_space(progress_size(ui, width, label~))
  let bar = bar_height(ui)
  let track = @emath.Rect::of(rect.min, { x: rect.max.x, y: rect.min.y + bar, })
  let painter = ui.painter()
  painter.rect(
    track,
    fill=style.surface,
    stroke=style.outline,
    corner=@paint.Corner::same(bar / 2),
  )
  let part = @emath.clamp(fraction, 0, 1)
  if part > 0 {
    painter.rect(
      @emath.Rect::of(track.min, {
        x: track.min.x + track.width() * part,
        y: track.max.y,
      }),
      fill=style.accent,
      corner=@paint.Corner::same(bar / 2),
    )
  }
  if label != "" {
    painter.galley(
      { x: rect.min.x, y: rect.min.y + bar + style.spacing.y, },
      galley(ui, label),
      style.weak_text,
    )
  }
  @hit.Response::none(ui.id(), rect)
}

///|
/// The eight directions a spinner's bars point in, so that drawing one needs no
/// trigonometry and every target draws the same pixels.
let bar_x : Array[Double] = [
  1.0, 0.7071067811865476, 0.0, -0.7071067811865476, -1.0, -0.7071067811865476, 0.0,
  0.7071067811865476,
]

///|
let bar_y : Array[Double] = [
  0.0, 0.7071067811865476, 1.0, 0.7071067811865476, 0.0, -0.7071067811865476, -1.0,
  -0.7071067811865476,
]

///|
/// How big a spinner is.
pub fn spinner_size(ui : @ctx.Ui) -> @emath.Vec2 {
  @emath.Vec2::splat(most(16, ui.line_height()))
}

///|
/// Something is happening, and there is no fraction to report.
///
/// The phase comes from the caller, which is what keeps a frame a function of
/// its input: a widget that read the clock would make every snapshot different.
pub fn spinner(ui : @ctx.Ui, phase : Double) -> @hit.Response {
  let style = ui.style()
  let rect = ui.allocate_space(spinner_size(ui))
  let radius = rect.width() / 2 - 2
  let centre = rect.centre()
  let head = ((phase % 1.0 + 1.0) % 1.0 * 8.0).to_int()
  let painter = ui.painter()
  for i in 0..<8 {
    let age = (i - head + 8) % 8
    let alpha = 255 - age * 26
    let ink = style.accent.with_alpha(alpha)
    let inner = radius * 0.55
    painter.line(
      { x: centre.x + bar_x[i] * inner, y: centre.y + bar_y[i] * inner, },
      { x: centre.x + bar_x[i] * radius, y: centre.y + bar_y[i] * radius, },
      @paint.Stroke::new(2, ink),
    )
  }
  @hit.Response::none(ui.id(), rect)
}
