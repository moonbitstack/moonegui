// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// How wide one tab is.
fn tab_width(ui : @ctx.Ui, label : String) -> Double {
  text_size(ui, label).x + ui.style().padding.x * 2
}

///|
/// How big a row of tabs is.
pub fn tabs_size(
  ui : @ctx.Ui,
  labels : Array[String],
  gap~ : Double = 4,
) -> @emath.Vec2 {
  let mut width = 0.0
  for label in labels {
    width = width + tab_width(ui, label)
  }
  if labels.length() > 1 {
    width = width + gap * (labels.length() - 1).to_double()
  }
  { x: width, y: control_height(ui), }
}

///|
/// One of a row of words, the chosen one underlined.
///
/// Which page is showing is the caller's state; this reports which tab was
/// pressed. A row of two or three is usually better than a drop-down, which is
/// why both exist.
pub fn tabs(
  ui : @ctx.Ui,
  labels : Array[String],
  chosen : Int32,
  gap~ : Double = 4,
  salt~ : String = "tabs",
) -> (Int32, @hit.Response) {
  let style = ui.style()
  let area = ui.allocate_space(tabs_size(ui, labels, gap~))
  let ctx = ui.ctx()
  let enabled = ui.is_enabled()
  let painter = ui.painter()
  let mut out = chosen
  let mut response = @hit.Response::none(ui.id(), area)
  let mut left = area.min.x
  for i, label in labels {
    let width = tab_width(ui, label)
    let cell = @emath.Rect::of({ x: left, y: area.min.y, }, {
      x: left + width,
      y: area.max.y,
    })
    let hit = ctx.interact(
      ui.next_id(salt + "#" + i.to_string()),
      cell,
      @hit.click,
      enabled~,
    )
    if i == 0 {
      response = with_click(hit, hit.clicked)
    } else {
      response = response.union(hit)
    }
    if hit.clicked {
      out = i
    }
    let picked = i == chosen
    if picked {
      painter.rect(
        cell,
        fill=style.surface,
        corner=@paint.Corner::same(style.corner),
      )
    } else if hit.hovered {
      painter.rect(
        cell,
        fill=style.hovered,
        corner=@paint.Corner::same(style.corner),
      )
    }
    let laid = galley(ui, label)
    painter.galley(
      centred(cell, laid.size),
      laid,
      if picked {
        style.text
      } else {
        style.weak_text
      },
    )
    if picked {
      painter.rect(
        @emath.Rect::of({ x: cell.min.x, y: cell.max.y - 2, }, {
          x: cell.max.x,
          y: cell.max.y,
        }),
        fill=style.accent,
      )
    }
    left = left + width + gap
  }
  if out != chosen {
    response.mark_changed()
  }
  (out, response)
}
