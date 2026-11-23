// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Draw one node, and everything under it, inside the rectangle it was given.
fn Interp::paint(
  self : Interp,
  ui : @ctx.Ui,
  view : View,
  path : @id.Id,
  rect : @emath.Rect,
  size : @emath.Vec2,
) -> Unit {
  let layout = cell_layout(rect, size)
  match view {
    Empty => ()
    Text(text~, role~, wrap~) => {
      let font = ui.style().font_of(role)
      let laid = if wrap {
        @text.layout(ui.ctx().backend(), text, font, wrap=rect.width())
      } else {
        @text.line(ui.ctx().backend(), text, font)
      }
      ui.cell(path, rect, fn(inner) {
        inner.painter().galley(rect.min, laid, inner.style().color_of(role))
      })
    }
    Button(text~, tag~, kind~, enabled~) => {
      let mut answer = @hit.Response::none(path, rect)
      ui.cell(
        path,
        rect,
        fn(inner) {
          if !enabled {
            inner.disable()
          }
          answer = match kind {
            Normal => @widget.button(inner, text)
            Accent => @widget.accent_button(inner, text)
            Quiet => @widget.quiet_button(inner, text)
          }
        },
        layout~,
      )
      if answer.clicked {
        self.events.push(Clicked(tag))
      }
    }
    Checkbox(text~, tag~, value~, enabled~) => {
      let mut out = value
      ui.cell(
        path,
        rect,
        fn(inner) {
          if !enabled {
            inner.disable()
          }
          out = @widget.checkbox(inner, text, value).0
        },
        layout~,
      )
      if out != value {
        self.events.push(Toggled(tag~, value=out))
      }
    }
    Radio(text~, tag~, value~, enabled~) => {
      let mut out = value
      ui.cell(
        path,
        rect,
        fn(inner) {
          if !enabled {
            inner.disable()
          }
          out = @widget.radio(inner, text, value).0
        },
        layout~,
      )
      if out != value {
        self.events.push(Toggled(tag~, value=out))
      }
    }
    Switch(tag~, value~, enabled~) => {
      let mut out = value
      ui.cell(
        path,
        rect,
        fn(inner) {
          if !enabled {
            inner.disable()
          }
          out = @widget.switch(inner, value).0
        },
        layout~,
      )
      if out != value {
        self.events.push(Toggled(tag~, value=out))
      }
    }
    Slider(tag~, value~, low~, high~, width~, enabled~) => {
      let mut out = value
      ui.cell(
        path,
        rect,
        fn(inner) {
          if !enabled {
            inner.disable()
          }
          out = @widget.slider(inner, value, low~, high~, width~).0
        },
        layout~,
      )
      if out != value {
        self.events.push(Moved(tag~, value=out))
      }
    }
    DragValue(tag~, value~, low~, high~, speed~, width~, enabled~) => {
      let mut out = value
      ui.cell(
        path,
        rect,
        fn(inner) {
          if !enabled {
            inner.disable()
          }
          out = @widget.drag_value(inner, value, low~, high~, speed~, width~).0
        },
        layout~,
      )
      if out != value {
        self.events.push(Moved(tag~, value=out))
      }
    }
    Edit(text~, tag~, hint~, width~, enabled~) => {
      let mut out = text
      ui.cell(
        path,
        rect,
        fn(inner) {
          if !enabled {
            inner.disable()
          }
          out = @widget.edit(inner, text, hint~, width~).0
        },
        layout~,
      )
      if out != text {
        self.events.push(Edited(tag~, text=out))
      }
    }
    TextArea(text~, tag~, rows~, width~, enabled~) => {
      let mut out = text
      ui.cell(
        path,
        rect,
        fn(inner) {
          if !enabled {
            inner.disable()
          }
          out = @widget.text_area(inner, text, rows~, width~).0
        },
        layout~,
      )
      if out != text {
        self.events.push(Edited(tag~, text=out))
      }
    }
    Combo(items~, tag~, chosen~, open~, width~) => {
      let mut picked = chosen
      let mut unfolded = open
      ui.cell(
        path,
        rect,
        fn(inner) {
          let (now, is_open, _) = @widget.combo(
            inner,
            items,
            chosen,
            open,
            width~,
          )
          picked = now
          unfolded = is_open
        },
        layout~,
      )
      if picked != chosen {
        self.events.push(Chosen(tag~, at=picked))
      }
      if unfolded != open {
        self.events.push(Opened(tag~, open=unfolded))
      }
    }
    Tabs(labels~, tag~, chosen~) => {
      let mut picked = chosen
      ui.cell(
        path,
        rect,
        fn(inner) { picked = @widget.tabs(inner, labels, chosen).0 },
        layout~,
      )
      if picked != chosen {
        self.events.push(Chosen(tag~, at=picked))
      }
    }
    Progress(fraction~, width~, label~) =>
      ui.cell(
        path,
        rect,
        fn(inner) {
          @widget.progress(inner, fraction, width~, label~) |> ignore
        },
        layout~,
      )
    Spinner(phase~) =>
      ui.cell(
        path,
        rect,
        fn(inner) { @widget.spinner(inner, phase) |> ignore },
        layout~,
      )
    Hyperlink(text~, tag~) => {
      let mut answer = @hit.Response::none(path, rect)
      ui.cell(
        path,
        rect,
        fn(inner) { answer = @widget.hyperlink(inner, text) },
        layout~,
      )
      if answer.clicked {
        self.events.push(Clicked(tag))
      }
    }
    Badge(text~, tone~) =>
      ui.cell(
        path,
        rect,
        fn(inner) { @widget.badge(inner, text, tone~) |> ignore },
        layout~,
      )
    Separator =>
      ui.cell(
        path,
        rect,
        fn(inner) { @widget.separator(inner) |> ignore },
        layout~,
      )
    Space(..) => ()
    Row(flow~, children~) => self.stack(ui, path, rect, flow, children)
    Column(flow~, children~) => self.stack(ui, path, rect, flow, children)
    Grid(columns~, flow~, children~) =>
      self.cells(ui, path, rect, columns, flow, children)
    Panel(title~, tone~, padding~, child~) => {
      let style = ui.style()
      let ground = match tone {
        Plain => style.background
        _ => style.ground_of(tone)
      }
      let painter = ui.painter()
      painter.rect(
        rect,
        fill=ground,
        stroke=style.outline,
        corner=@paint.Corner::same(style.corner),
      )
      let mut top = rect.min.y + padding
      if title != "" {
        let font = style.font_of(Heading)
        let laid = @text.line(ui.ctx().backend(), title, font)
        painter.galley({ x: rect.min.x + padding, y: top, }, laid, style.text)
        top = top + laid.size.y + style.spacing.y
      }
      let body = @emath.Rect::of({ x: rect.min.x + padding, y: top, }, {
        x: rect.max.x - padding,
        y: rect.max.y - padding,
      })
      self.place(ui, child, path.child("body"), body, body.size())
    }
    Group(title~, open~, tag~, child~) => {
      let head = @widget.group_header_size(ui, title)
      let mut unfolded = open
      let box = @emath.Rect::at(rect.min, head)
      ui.cell(path.child("head"), box, fn(inner) {
        unfolded = @widget.group_header(inner, title, open).0
      })
      if unfolded != open {
        self.events.push(Opened(tag~, open=unfolded))
      }
      if unfolded {
        let gap = ui.style().spacing.y
        let body = @emath.Rect::of(
          { x: rect.min.x, y: box.max.y + gap, },
          rect.max,
        )
        self.place(ui, child, path.child("body"), body, body.size())
      }
    }
    Scroll(tag~, height~, child~) => {
      let content = self.measure(ui, child, path.child("body"), {
        x: rect.width(),
        y: open_room,
      })
      let memory = ui.ctx().memory()
      let offset = memory.num(path, 0)
      // The window is a cell of its own: the scrolling widget asks the region it
      // is building into for the room left, and that has to be this rectangle
      // rather than whatever the parent is up to.
      ui.cell(path, rect, fn(window) {
        let (now, _) = @widget.scroll_area(
          window,
          offset,
          height,
          content.y,
          fn(inner) {
            let box = inner.rect()
            let full = @emath.Rect::at(box.min, {
              x: box.width(),
              y: content.y,
            })
            self.place(inner, child, path.child("body"), full, {
              x: box.width(),
              y: open_room,
            })
          },
          salt=tag.value().to_string(),
        )
        memory.set(path, @mem.State::Num(now))
      })
    }
    List(items~, tag~, chosen~, height~) => {
      let mut picked = chosen
      ui.cell(
        path,
        rect,
        fn(inner) { picked = @widget.list(inner, items, chosen, height~).0 },
        layout~,
      )
      if picked != chosen {
        self.events.push(Chosen(tag~, at=picked))
      }
    }
    Table(columns~, rows~, tag~, chosen~, width~) => {
      let mut picked = chosen
      ui.cell(
        path,
        rect,
        fn(inner) {
          picked = @widget.table(inner, columns, rows, chosen, width~).0
        },
        layout~,
      )
      if picked != chosen {
        self.events.push(Chosen(tag~, at=picked))
      }
    }
    Sized(child~, ..) =>
      self.place(ui, child, path.child("in"), rect, rect.size())
  }
}

///|
/// Place children in a line, in the order they were written.
fn Interp::stack(
  self : Interp,
  ui : @ctx.Ui,
  path : @id.Id,
  rect : @emath.Rect,
  flow : @layout.Flow,
  children : Array[View],
) -> Unit {
  let style = ui.style()
  let gap = flow.gap_of(style.spacing)
  let inner = rect.shrink(flow.padding)
  let horizontal = flow.dir.is_horizontal()
  let room = inner.size()
  let sizes : Array[@emath.Vec2] = []
  let mut along = 0.0
  for i, child in children {
    let size = self.measure(
      ui,
      child,
      path.child(child.name(i)),
      @layout.child_room(room, horizontal, along),
    )
    sizes.push(size)
    along = along + (if horizontal { size.x } else { size.y }) + gap
  }
  along = if along > 0 { along - gap } else { along }
  let free = (if horizontal { inner.width() } else { inner.height() }) - along
  let lead = match flow.justify {
    Start => 0.0
    Center => free / 2
    End => free
    SpaceBetween => 0.0
  }
  let spread = if flow.justify == SpaceBetween && children.length() > 1 {
    free / (children.length() - 1).to_double()
  } else {
    0.0
  }
  let across = if horizontal { inner.height() } else { inner.width() }
  let mut at = (if horizontal { inner.min.x } else { inner.min.y }) + lead
  for i, child in children {
    let size = sizes[i]
    let main = if horizontal { size.x } else { size.y }
    let cross = if flow.stretch {
      across
    } else if horizontal {
      size.y
    } else {
      size.x
    }
    let offset = flow.cross.offset(across, cross)
    let cell = if horizontal {
      @emath.Rect::of({ x: at, y: inner.min.y + offset, }, {
        x: at + main,
        y: inner.min.y + offset + cross,
      })
    } else {
      @emath.Rect::of({ x: inner.min.x + offset, y: at, }, {
        x: inner.min.x + offset + cross,
        y: at + main,
      })
    }
    self.place(ui, child, path.child(child.name(i)), cell, room)
    at = at + main + gap + spread
  }
}

///|
/// Place children in equal columns.
fn Interp::cells(
  self : Interp,
  ui : @ctx.Ui,
  path : @id.Id,
  rect : @emath.Rect,
  columns : Int32,
  flow : @layout.Flow,
  children : Array[View],
) -> Unit {
  let count = if columns < 1 { 1 } else { columns }
  let gap = flow.gap_of(ui.style().spacing)
  let inner = rect.shrink(flow.padding)
  let cell = grid_cell(ui, inner.size(), count, flow, children)
  let rows = (children.length() + count - 1) / count
  let heights : Array[Double] = []
  for row in 0..<rows {
    let mut tall = 0.0
    for column in 0..<count {
      let at = row * count + column
      if at < children.length() {
        tall = bigger(
          tall,
          children[at].size(ui, room={ x: cell, y: inner.height(), }).y,
        )
      }
    }
    heights.push(tall)
  }
  let mut top = inner.min.y
  for row in 0..<rows {
    let mut left = inner.min.x
    for column in 0..<count {
      let at = row * count + column
      if at < children.length() {
        let child = children[at]
        let box = @emath.Rect::of({ x: left, y: top, }, {
          x: left + cell,
          y: top + heights[row],
        })
        self.place(ui, child, path.child(child.name(at)), box, {
          x: cell,
          y: heights[row],
        })
      }
      left = left + cell + gap
    }
    top = top + heights[row] + gap
  }
}

///|
/// How a widget has to be placed so that it fills the cell it was given.
///
/// A control asks for its own size, so it fills a cell exactly when the cell is
/// exactly what it asked for. A cell that is wider or taller than that is one
/// the layout stretched, and the control has to be told to stretch with it.
fn cell_layout(rect : @emath.Rect, size : @emath.Vec2) -> @layout.Layout {
  let wider = rect.width() > size.x + 0.01
  let taller = rect.height() > size.y + 0.01
  if wider && !taller {
    { dir: TopDown, cross: Min, cross_justify: true, }
  } else if taller && !wider {
    { dir: LeftToRight, cross: Min, cross_justify: true, }
  } else {
    @layout.top_down
  }
}
