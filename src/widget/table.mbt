// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// How big a list of these items is.
pub fn list_size(
  ui : @ctx.Ui,
  items : Array[String],
  height~ : Double = 160,
) -> @emath.Vec2 {
  let mut widest = 0.0
  for item in items {
    let width = text_size(ui, item).x
    if width > widest {
      widest = width
    }
  }
  let rows = items.length().to_double() * row_height(ui)
  {
    x: widest + ui.style().padding.x * 2,
    y: if rows < height {
      rows
    } else {
      height
    },
  }
}

///|
/// A column of words, one of which is chosen.
///
/// It is a list, not a menu: the choose happens in place and the caller keeps
/// the index, so a list can be as long as the caller's data and no longer.
pub fn list(
  ui : @ctx.Ui,
  items : Array[String],
  chosen : Int32,
  height~ : Double = 160,
  salt~ : String = "list",
) -> (Int32, @hit.Response) {
  let style = ui.style()
  let area = ui.allocate_space(list_size(ui, items, height~))
  let height = row_height(ui)
  let painter = ui.painter()
  let ctx = ui.ctx()
  let enabled = ui.is_enabled()
  let mut out = chosen
  let mut response = @hit.Response::none(ui.id(), area)
  for i, item in items {
    let row = row_rect(area, i, height)
    if row.min.y >= area.max.y {
      break
    }
    let hit = ctx.interact(
      ui.next_id(salt + "#" + i.to_string()),
      row,
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
    let ground = if i == chosen {
      style.accent.with_alpha(60)
    } else if hit.hovered {
      style.hovered
    } else {
      @paint.clear
    }
    if !ground.is_clear() {
      painter.rect(row, fill=ground)
    }
    let laid = galley(ui, item)
    painter.galley(
      left_of(row, laid.size, style.padding.x),
      laid,
      if i == chosen {
        style.text
      } else {
        style.text_for(hit)
      },
    )
  }
  if out != chosen {
    response.mark_changed()
  }
  (out, response)
}

///|
/// How big a table with this many rows is.
pub fn table_size(ui : @ctx.Ui, rows : Int32, width : Double) -> @emath.Vec2 {
  { x: width, y: row_height(ui) * (rows + 1).to_double(), }
}

///|
/// Rows of cells under a header, one row of which is chosen.
///
/// Every column is the same width: a table whose columns resize to their
/// contents moves every time a number grows a digit, and a reader who is
/// watching the numbers would rather they stayed put.
pub fn table(
  ui : @ctx.Ui,
  columns : Array[String],
  rows : Array[Array[String]],
  chosen : Int32,
  width~ : Double = 320,
  salt~ : String = "table",
) -> (Int32, @hit.Response) {
  let style = ui.style()
  let area = ui.allocate_space(table_size(ui, rows.length(), width))
  let height = row_height(ui)
  let count = if columns.length() == 0 { 1 } else { columns.length() }
  let each = area.width() / count.to_double()
  let painter = ui.painter()
  let ctx = ui.ctx()
  let enabled = ui.is_enabled()
  let mut out = chosen
  let mut response = @hit.Response::none(ui.id(), area)
  let header = row_rect(area, 0, height)
  for i, label in columns {
    let cell = @emath.Rect::of(
      { x: header.min.x + each * i.to_double(), y: header.min.y, },
      { x: header.min.x + each * (i + 1).to_double(), y: header.max.y, },
    )
    let laid = galley(ui, label)
    painter.galley(
      left_of(cell, laid.size, style.padding.x),
      laid,
      style.weak_text,
    )
  }
  painter.rect(
    @emath.Rect::of({ x: header.min.x, y: header.max.y - 1, }, {
      x: header.max.x,
      y: header.max.y,
    }),
    fill=style.outline.color,
  )
  for i, cells in rows {
    let row = row_rect(
      @emath.Rect::of({ x: area.min.x, y: area.min.y + height, }, {
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
    if i == 0 {
      response = with_click(hit, hit.clicked)
    } else {
      response = response.union(hit)
    }
    if hit.clicked {
      out = i
    }
    let ground = if i == chosen {
      style.accent.with_alpha(60)
    } else if hit.hovered {
      style.hovered
    } else if i % 2 == 1 {
      style.surface
    } else {
      @paint.clear
    }
    if !ground.is_clear() {
      painter.rect(row, fill=ground)
    }
    for j, text in cells {
      if j >= count {
        break
      }
      let cell = @emath.Rect::of(
        { x: row.min.x + each * j.to_double(), y: row.min.y, },
        { x: row.min.x + each * (j + 1).to_double(), y: row.max.y, },
      )
      let laid = galley(ui, text)
      painter.galley(
        left_of(cell, laid.size, style.padding.x),
        laid,
        style.text_for(hit),
      )
    }
  }
  if out != chosen {
    response.mark_changed()
  }
  (out, response)
}
