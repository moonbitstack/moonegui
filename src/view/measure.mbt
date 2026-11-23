// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Room with no edge to it, for measuring something that is not being placed.
pub let unlimited : @emath.Vec2 = @emath.Vec2::splat(1.0e9)

///|
/// One axis with no edge to it.
pub let open_room : Double = 1.0e9

///|
/// How big a node is before it is put anywhere.
///
/// This is the half of layout that a tree needs and an immediate-mode frame
/// does not: the frame allocates space as it goes, while a row has to know how
/// wide its children are before it can say where the second one starts.
pub fn View::size(
  self : View,
  ui : @ctx.Ui,
  room~ : @emath.Vec2 = unlimited,
) -> @emath.Vec2 {
  match self {
    Empty => @emath.zero
    Text(text~, role~, wrap~) =>
      if wrap {
        @text.layout(
          ui.ctx().backend(),
          text,
          ui.style().font_of(role),
          wrap=room.x,
        ).size
      } else {
        @widget.text_size_in(ui, text, ui.style().font_of(role))
      }
    Button(text~, ..) => @widget.button_size(ui, text)
    Checkbox(text~, ..) => @widget.choice_size(ui, text)
    Radio(text~, ..) => @widget.choice_size(ui, text)
    Switch(..) => @widget.switch_size(ui)
    Slider(width~, ..) => @widget.slider_size(ui, width)
    DragValue(width~, ..) => @widget.drag_value_size(ui, width)
    Edit(width~, ..) => @widget.edit_size(ui, width)
    TextArea(rows~, width~, ..) => @widget.text_area_size(ui, rows, width)
    Combo(items~, open~, width~, ..) =>
      @widget.combo_size(ui, items, open, width~)
    Tabs(labels~, ..) => @widget.tabs_size(ui, labels)
    Progress(width~, label~, ..) => @widget.progress_size(ui, width, label~)
    Spinner(..) => @widget.spinner_size(ui)
    Hyperlink(text~, ..) => @widget.hyperlink_size(ui, text)
    Badge(text~, ..) => @widget.badge_size(ui, text)
    Separator =>
      {
        x: if room.x < 1.0e9 {
          room.x
        } else {
          0
        },
        y: @widget.separator_height(ui),
      }
    Space(width~, height~) => { x: width, y: height, }
    Row(flow~, children~) => flow_size(ui, room, flow, children)
    Column(flow~, children~) => flow_size(ui, room, flow, children)
    Grid(columns~, flow~, children~) =>
      grid_size(ui, room, columns, flow, children)
    Panel(title~, padding~, child~, ..) => {
      let inner = inset(room, padding)
      let body = child.size(ui, room=inner)
      let head = if title == "" {
        0.0
      } else {
        @widget.control_height(ui) + ui.style().spacing.y
      }
      { x: body.x + padding * 2, y: body.y + padding * 2 + head, }
    }
    Group(title~, open~, child~, ..) => {
      let head = @widget.group_header_size(ui, title)
      let body = if open { child.size(ui, room~) } else { @emath.zero }
      let gap = if open { ui.style().spacing.y } else { 0.0 }
      { x: bigger(head.x, body.x), y: head.y + gap + body.y, }
    }
    Scroll(height~, child~, ..) => {
      let content = child.size(ui, room={ x: room.x, y: open_room, })
      {
        x: if room.x < 1.0e9 {
          room.x
        } else {
          content.x + @widget.scroll_bar_width() + 2
        },
        y: height,
      }
    }
    List(items~, height~, ..) => @widget.list_size(ui, items, height~)
    Table(rows~, width~, ..) => @widget.table_size(ui, rows.length(), width)
    Sized(bounds~, child~) => bounds.hold(child.size(ui, room~))
  }
}

///|
/// How big a row or a column is.
fn flow_size(
  ui : @ctx.Ui,
  room : @emath.Vec2,
  flow : Flow,
  children : Array[View],
) -> @emath.Vec2 {
  let style = ui.style()
  let gap = flow.gap_of(style)
  let pad = flow.padding * 2
  let inner = inset(room, flow.padding)
  let horizontal = flow.dir.is_horizontal()
  let mut main = 0.0
  let mut cross = 0.0
  for child in children {
    let size = child.size(ui, room=child_room(inner, horizontal, main))
    if horizontal {
      main = main + size.x + gap
      cross = bigger(cross, size.y)
    } else {
      main = main + size.y + gap
      cross = bigger(cross, size.x)
    }
  }
  // The gap after the last child is not part of the line.
  main = if main > 0 { main - gap } else { main }
  if flow.stretch {
    let across = if horizontal { room.y } else { room.x }
    if across < 1.0e9 {
      cross = across - pad
    }
  }
  if horizontal {
    { x: main + pad, y: cross + pad, }
  } else {
    { x: cross + pad, y: main + pad, }
  }
}

///|
/// How big a grid is: equal columns across, rows as tall as their tallest cell.
fn grid_size(
  ui : @ctx.Ui,
  room : @emath.Vec2,
  columns : Int32,
  flow : Flow,
  children : Array[View],
) -> @emath.Vec2 {
  let style = ui.style()
  let gap = flow.gap_of(style)
  let pad = flow.padding * 2
  let count = if columns < 1 { 1 } else { columns }
  let cell = grid_cell(ui, room, count, flow, children)
  let rows = (children.length() + count - 1) / count
  let heights : Array[Double] = []
  for row in 0..<rows {
    let mut tall = 0.0
    for column in 0..<count {
      let at = row * count + column
      if at < children.length() {
        let size = children[at].size(ui, room={ x: cell, y: room.y, })
        tall = bigger(tall, size.y)
      }
    }
    heights.push(tall)
  }
  let mut height = pad
  for tall in heights {
    height = height + tall
  }
  if rows > 1 {
    height = height + gap * (rows - 1).to_double()
  }
  {
    x: cell * count.to_double() + gap * (count - 1).to_double() + pad,
    y: height,
  }
}

///|
/// How wide one column of a grid is.
fn grid_cell(
  ui : @ctx.Ui,
  room : @emath.Vec2,
  columns : Int32,
  flow : Flow,
  children : Array[View],
) -> Double {
  let gap = flow.gap_of(ui.style())
  let pad = flow.padding * 2
  if room.x < 1.0e9 {
    let free = room.x - pad - gap * (columns - 1).to_double()
    if free > 0 {
      return free / columns.to_double()
    }
  }
  let mut widest = 0.0
  for child in children {
    let size = child.size(ui)
    widest = bigger(widest, size.x)
  }
  widest
}

///|
/// A room with its edges pulled in, never narrower than nothing.
fn inset(room : @emath.Vec2, by : Double) -> @emath.Vec2 {
  {
    x: if room.x < 1.0e9 {
      if room.x > by * 2 {
        room.x - by * 2
      } else {
        0
      }
    } else {
      room.x
    },
    y: if room.y < 1.0e9 {
      if room.y > by * 2 {
        room.y - by * 2
      } else {
        0
      }
    } else {
      room.y
    },
  }
}

///|
fn bigger(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}
