// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// How much room the chevron of a drop-down takes.
fn chevron(ui : @ctx.Ui) -> Double {
  most(10, ui.line_height() * 0.7)
}

///|
/// How big a drop-down is, its open list included.
pub fn combo_size(
  ui : @ctx.Ui,
  items : Array[String],
  open : Bool,
  width~ : Double = 160,
) -> @emath.Vec2 {
  let rows = if open {
    items.length().to_double() * row_height(ui)
  } else {
    0.0
  }
  { x: width, y: control_height(ui) + rows, }
}

///|
/// A field showing the chosen item, and the rest of the list below it when it
/// is open.
///
/// Open is the caller's state, not the widget's: a tree that is laid out before
/// it is drawn has to know how tall this is before anything is drawn, and a
/// popup that floats over its neighbours would need a second pass over the
/// frame. What opens is therefore a disclosure — the list takes room of its own
/// — which also means it can be scrolled to and read without a pointer.
pub fn combo(
  ui : @ctx.Ui,
  items : Array[String],
  chosen : Int32,
  open : Bool,
  width~ : Double = 160,
  salt~ : String = "combo",
) -> (Int32, Bool, @hit.Response) {
  let style = ui.style()
  let area = ui.allocate_space(combo_size(ui, items, open, width~))
  let field_height = control_height(ui)
  let field = @emath.Rect::of(area.min, {
    x: area.max.x,
    y: area.min.y + field_height,
  })
  let ctx = ui.ctx()
  let enabled = ui.is_enabled()
  let field_hit = ctx.interact(ui.next_id(salt), field, @hit.click, enabled~)
  let clicked = field_hit.clicked || activated(ui, field_hit)
  let mut out = chosen
  let mut is_open = open
  if clicked {
    is_open = !open
  }
  let mut response = with_click(field_hit, clicked)
  let painter = ui.painter()
  painter.rect(
    field,
    fill=style.fill_for(response),
    stroke=style.outline_for(response),
    corner=@paint.Corner::same(style.corner),
  )
  let shown = if chosen >= 0 && chosen < items.length() {
    items[chosen]
  } else {
    ""
  }
  let laid = galley(ui, shown)
  painter.galley(
    left_of(field, laid.size, style.padding.x),
    laid,
    style.text_for(response),
  )
  let arrow = chevron(ui)
  let middle = field.centre()
  let tip = if is_open { -1.0 } else { 1.0 }
  painter.path(
    [
      { x: field.max.x - style.padding.x - arrow, y: middle.y - 2 * tip, },
      { x: field.max.x - style.padding.x - arrow / 2, y: middle.y + 2 * tip, },
      { x: field.max.x - style.padding.x, y: middle.y - 2 * tip, },
    ],
    stroke=@paint.Stroke::new(1.5, style.weak_text),
  )
  if is_open {
    let height = row_height(ui)
    for i, item in items {
      let row = row_rect(
        @emath.Rect::of({ x: area.min.x, y: field.max.y, }, {
          x: area.max.x,
          y: area.max.y,
        }),
        i,
        height,
      )
      let hit = ctx.interact(
        ui.next_id(salt + "#" + i.to_string()),
        row,
        @hit.click,
        enabled~,
      )
      response = response.union(hit)
      if hit.clicked {
        out = i
        is_open = false
      }
      let ground = if i == chosen {
        style.accent.with_alpha(70)
      } else if hit.hovered {
        style.hovered
      } else {
        style.surface
      }
      painter.rect(row, fill=ground, corner=@paint.Corner::same(style.corner))
      let written = galley(ui, item)
      painter.galley(
        left_of(row, written.size, style.padding.x),
        written,
        style.text,
      )
    }
  }
  if out != chosen || is_open != open {
    response.mark_changed()
  }
  (out, is_open, response)
}
