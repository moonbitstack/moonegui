// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// How big a link is.
pub fn hyperlink_size(ui : @ctx.Ui, string : String) -> @emath.Vec2 {
  control_size(ui, text_size(ui, string))
}

///|
/// A string that leads somewhere.
///
/// It is a button that looks like a word: the same click, the same keyboard
/// access, none of the box. Where it leads is the caller's business — this
/// reports the click and nothing else.
pub fn hyperlink(
  ui : @ctx.Ui,
  string : String,
  salt~ : String = "link",
) -> @hit.Response {
  let style = ui.style()
  let laid = galley(ui, string)
  let (rect, hit) = ui.allocate(hyperlink_size(ui, string), @hit.click, salt)
  let response = with_click(hit, activated(ui, hit))
  let ink = if !response.enabled {
    style.weak_text
  } else if response.hovered || response.focused {
    style.text
  } else {
    style.accent
  }
  let painter = ui.painter()
  let at = centred(rect, laid.size)
  painter.galley(at, laid, ink)
  let rule = most(1, style.outline.width)
  painter.rect(
    @emath.Rect::of({ x: at.x, y: at.y + laid.size.y - rule, }, {
      x: at.x + laid.size.x,
      y: at.y + laid.size.y,
    }),
    fill=ink,
  )
  response
}

///|
/// How big a badge is.
pub fn badge_size(ui : @ctx.Ui, string : String) -> @emath.Vec2 {
  let text = text_size(ui, string)
  { x: text.x + 12, y: most(text.y, ui.line_height()) + 4, }
}

///|
/// A short word in a pill, for a count, a state, or a tag.
pub fn badge(
  ui : @ctx.Ui,
  string : String,
  tone~ : @ctx.Tone = Accent,
) -> @hit.Response {
  let style = ui.style()
  let rect = ui.allocate_space(badge_size(ui, string))
  let laid = galley(ui, string)
  ui
  .painter()
  .rect(
    rect,
    fill=style.ground_of(tone),
    stroke=style.outline,
    corner=@paint.Corner::same(rect.height() / 2),
  )
  ui.painter().galley(centred(rect, laid.size), laid, style.ink_of(tone))
  @hit.Response::none(ui.id(), rect)
}
