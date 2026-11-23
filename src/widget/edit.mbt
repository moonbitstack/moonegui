// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// How big a single-line field is.
pub fn edit_size(ui : @ctx.Ui, width : Double) -> @emath.Vec2 {
  { x: width, y: control_height(ui), }
}

///|
/// A single line of editable text.
///
/// The string goes in and the edited string comes out; what stays behind
/// between frames is only the caret, which is kept under the widget's id. The
/// text itself belongs to the caller, so two fields showing the same string
/// stay in step without anything having to be told about it.
pub fn edit(
  ui : @ctx.Ui,
  value : String,
  hint~ : String = "",
  width~ : Double = 200,
  salt~ : String = "edit",
) -> (String, @hit.Response) {
  let style = ui.style()
  let back = ui.ctx().backend()
  let font = style.font
  let line_height = ui.line_height()
  let (rect, response) = ui.allocate(
    edit_size(ui, width),
    @hit.click_and_drag,
    salt,
  )
  let inner = @emath.Rect::of(
    { x: rect.min.x + style.padding.x, y: rect.min.y, },
    { x: rect.max.x - style.padding.x, y: rect.max.y, },
  )
  let memory = ui.ctx().memory()
  let id = response.id
  let remembered = memory.cursor(id, value.length())
  let mut out = value
  let mut at = clamp_to(remembered.0, out.length())
  let mut other = clamp_to(remembered.1, out.length())

  // The text is scrolled so the caret stays inside the field; the offset is
  // worked out from the caret rather than remembered, so a field whose text was
  // changed from outside comes back to a sensible place on its own.
  let mut offset = scroll_for(back, out, font, at, inner.width())
  if response.enabled {
    match ui.ctx().input().pointer() {
      Some(pointer) =>
        if response.pressed || response.dragged {
          let along = pointer.x - inner.min.x + offset
          at = @text.index_at(back, out, font, along)
          if response.pressed && !response.dragged {
            other = at
          }
        }
      None => ()
    }
  }
  if response.enabled && response.focused {
    let input = ui.ctx().input()
    let typed = input.typed()
    let pasted = match input.pasted() {
      Some(text) => text
      None => ""
    }
    let entered = typed + pasted
    if entered != "" {
      let cut = replace(out, at, other, entered)
      out = cut.0
      at = cut.1
      other = at
    }
    if input.key_pressed(@input.Key::Backspace) {
      if at != other {
        let cut = replace(out, at, other, "")
        out = cut.0
        at = cut.1
      } else if at > 0 {
        let from = @text.prev_index(out, at)
        out = @text.remove(out, from, at)
        at = from
      }
      other = at
    }
    if input.key_pressed(@input.Key::Delete) {
      if at != other {
        let cut = replace(out, at, other, "")
        out = cut.0
        at = cut.1
      } else if at < out.length() {
        out = @text.remove(out, at, @text.next_index(out, at))
      }
      other = at
    }
    match input.key_down(@input.Key::Left) {
      Some(mods) => {
        at = if at != other && !mods.shift {
          smaller(at, other)
        } else {
          @text.prev_index(out, at)
        }
        if !mods.shift {
          other = at
        }
      }
      None => ()
    }
    match input.key_down(@input.Key::Right) {
      Some(mods) => {
        at = if at != other && !mods.shift {
          larger(at, other)
        } else {
          @text.next_index(out, at)
        }
        if !mods.shift {
          other = at
        }
      }
      None => ()
    }
    match input.key_down(@input.Key::Home) {
      Some(mods) => {
        at = 0
        if !mods.shift {
          other = at
        }
      }
      None => ()
    }
    match input.key_down(@input.Key::End) {
      Some(mods) => {
        at = out.length()
        if !mods.shift {
          other = at
        }
      }
      None => ()
    }
    offset = scroll_for(back, out, font, at, inner.width())
  }
  at = clamp_to(at, out.length())
  other = clamp_to(other, out.length())
  memory.set(id, @mem.State::Cursor(at~, other~))
  if out != value {
    response.mark_changed()
  }
  let painter = ui.painter()
  painter.rect(
    rect,
    fill=style.fill_for(response),
    stroke=style.outline_for(response),
    corner=@paint.Corner::same(style.corner),
  )
  let inside = painter.sub(inner)
  let baseline = rect.min.y + (rect.height() - line_height) / 2
  if at != other {
    let from = @text.x_at(back, out, font, smaller(at, other)) - offset
    let to = @text.x_at(back, out, font, larger(at, other)) - offset
    inside.rect(
      @emath.Rect::of({ x: inner.min.x + from, y: baseline, }, {
        x: inner.min.x + to,
        y: baseline + line_height,
      }),
      fill=style.accent.with_alpha(96),
    )
  }
  if out == "" && hint != "" {
    inside.galley(
      { x: inner.min.x, y: baseline, },
      @text.line(back, hint, font),
      style.weak_text,
    )
  } else {
    inside.galley(
      { x: inner.min.x - offset, y: baseline, },
      @text.line(back, out, font),
      style.text_for(response),
    )
  }
  if response.focused && response.enabled {
    // A steady caret rather than a blinking one: a blink would make every frame
    // depend on the clock, and a library that repaints for ever is a worse
    // default than one whose caret does not wink.
    let caret = inner.min.x + @text.x_at(back, out, font, at) - offset
    inside.line(
      { x: caret, y: baseline, },
      { x: caret, y: baseline + line_height, },
      @paint.Stroke::new(1, style.accent),
    )
  }
  (out, response)
}

///|
/// How big a multi-line field is.
pub fn text_area_size(
  ui : @ctx.Ui,
  rows : Int32,
  width : Double,
) -> @emath.Vec2 {
  let line = ui.line_height()
  { x: width, y: rows.to_double() * line + ui.style().padding.y * 2, }
}

///|
/// Several lines of editable text.
///
/// Lines are the ones written: the field does not break a long line for you,
/// so what a caret index means stays obvious. What scrolls is the rows, not the
/// characters in them, and the row the caret is on is always kept in view.
pub fn text_area(
  ui : @ctx.Ui,
  value : String,
  rows~ : Int32 = 4,
  width~ : Double = 240,
  salt~ : String = "area",
) -> (String, @hit.Response) {
  let style = ui.style()
  let back = ui.ctx().backend()
  let font = style.font
  let line_height = ui.line_height()
  let visible = if rows < 1 { 1 } else { rows }
  let (rect, response) = ui.allocate(
    text_area_size(ui, visible, width),
    @hit.click_and_drag,
    salt,
  )
  let inner = @emath.Rect::of(
    { x: rect.min.x + style.padding.x, y: rect.min.y + style.padding.y, },
    { x: rect.max.x - style.padding.x, y: rect.max.y - style.padding.y, },
  )
  let memory = ui.ctx().memory()
  let id = response.id
  let remembered = memory.cursor(id, value.length())
  let mut out = value
  let mut at = clamp_to(remembered.0, out.length())
  let mut other = clamp_to(remembered.1, out.length())
  let starts = line_starts(out)
  let mut row = row_of(starts, at)
  if response.enabled {
    match ui.ctx().input().pointer() {
      Some(pointer) =>
        if response.pressed || response.dragged {
          let listed = index_at_point(
            back, out, starts, font, line_height, inner, pointer,
          )
          at = listed
          if response.pressed && !response.dragged {
            other = at
          }
        }
      None => ()
    }
  }
  if response.enabled && response.focused {
    let input = ui.ctx().input()
    let pasted = match input.pasted() {
      Some(text) => text
      None => ""
    }
    let typed = input.typed() + pasted
    if typed != "" {
      let cut = replace(out, at, other, typed)
      out = cut.0
      at = cut.1
      other = at
    }
    if input.key_pressed(@input.Key::Enter) {
      let cut = replace(out, at, other, "\n")
      out = cut.0
      at = cut.1
      other = at
    }
    if input.key_pressed(@input.Key::Backspace) {
      if at != other {
        let cut = replace(out, at, other, "")
        out = cut.0
        at = cut.1
      } else if at > 0 {
        let from = @text.prev_index(out, at)
        out = @text.remove(out, from, at)
        at = from
      }
      other = at
    }
    if input.key_pressed(@input.Key::Delete) {
      if at != other {
        let cut = replace(out, at, other, "")
        out = cut.0
        at = cut.1
      } else if at < out.length() {
        out = @text.remove(out, at, @text.next_index(out, at))
      }
      other = at
    }
    match input.key_down(@input.Key::Left) {
      Some(mods) => {
        at = if at != other && !mods.shift {
          smaller(at, other)
        } else {
          @text.prev_index(out, at)
        }
        if !mods.shift {
          other = at
        }
      }
      None => ()
    }
    match input.key_down(@input.Key::Right) {
      Some(mods) => {
        at = if at != other && !mods.shift {
          larger(at, other)
        } else {
          @text.next_index(out, at)
        }
        if !mods.shift {
          other = at
        }
      }
      None => ()
    }
    let listed = line_starts(out)
    match input.key_down(@input.Key::Up) {
      Some(mods) => {
        at = same_column(back, out, listed, font, at, -1)
        if !mods.shift {
          other = at
        }
      }
      None => ()
    }
    match input.key_down(@input.Key::Down) {
      Some(mods) => {
        at = same_column(back, out, listed, font, at, 1)
        if !mods.shift {
          other = at
        }
      }
      None => ()
    }
    match input.key_down(@input.Key::Home) {
      Some(mods) => {
        at = listed[row_of(listed, at)]
        if !mods.shift {
          other = at
        }
      }
      None => ()
    }
    match input.key_down(@input.Key::End) {
      Some(mods) => {
        let line = row_of(listed, at)
        at = row_end(out, listed, line)
        if !mods.shift {
          other = at
        }
      }
      None => ()
    }
  }
  at = clamp_to(at, out.length())
  other = clamp_to(other, out.length())
  row = row_of(line_starts(out), at)
  let top = if row >= visible { row - visible + 1 } else { 0 }
  memory.set(id, @mem.State::Cursor(at~, other~))
  if out != value {
    response.mark_changed()
  }
  let painter = ui.painter()
  painter.rect(
    rect,
    fill=style.fill_for(response),
    stroke=style.outline_for(response),
    corner=@paint.Corner::same(style.corner),
  )
  let inside = painter.sub(inner)
  let lines = line_starts(out)
  let low = smaller(at, other)
  let high = larger(at, other)
  let mut drawn = top
  while drawn < lines.length() && drawn < top + visible {
    let start = lines[drawn]
    let stop = row_end(out, lines, drawn)
    let y = inner.min.y + (drawn - top).to_double() * line_height
    let body = out[start:stop].to_owned()
    if high > low && high > start && low < stop {
      let from = if low > start { low - start } else { 0 }
      let to = if high < stop { high - start } else { stop - start }
      let left = @text.x_at(back, body, font, from)
      let right = @text.x_at(back, body, font, to)
      inside.rect(
        @emath.Rect::of({ x: inner.min.x + left, y, }, {
          x: inner.min.x + right,
          y: y + line_height,
        }),
        fill=style.accent.with_alpha(96),
      )
    }
    inside.galley(
      { x: inner.min.x, y, },
      @text.line(back, body, font),
      style.text_for(response),
    )
    drawn = drawn + 1
  }
  if response.focused && response.enabled {
    let start = lines[row_of(lines, at)]
    let column = at - start
    let body = out[start:row_end(out, lines, row_of(lines, at))].to_owned()
    let x = inner.min.x + @text.x_at(back, body, font, column)
    let y = inner.min.y + (row_of(lines, at) - top).to_double() * line_height
    inside.line(
      { x, y, },
      { x, y: y + line_height, },
      @paint.Stroke::new(1, style.accent),
    )
  }
  (out, response)
}

///|
/// Where each line begins.
fn line_starts(text : String) -> Array[Int32] {
  let out : Array[Int32] = [0]
  for i in 0..<text.length() {
    if text[i].to_int() == 10 {
      out.push(i + 1)
    }
  }
  out
}

///|
/// Which line an index falls on.
fn row_of(starts : Array[Int32], at : Int32) -> Int32 {
  let mut found = 0
  for i, start in starts {
    if start <= at {
      found = i
    }
  }
  found
}

///|
/// Where a line ends, not counting its newline.
fn row_end(text : String, starts : Array[Int32], row : Int32) -> Int32 {
  if row + 1 < starts.length() {
    starts[row + 1] - 1
  } else {
    text.length()
  }
}

///|
/// The index the pointer is nearest to in a multi-line field.
fn index_at_point(
  back : &@back.Backend,
  text : String,
  starts : Array[Int32],
  font : @paint.FontId,
  line_height : Double,
  inner : @emath.Rect,
  pointer : @emath.Vec2,
) -> Int32 {
  let guess = ((pointer.y - inner.min.y) / line_height).to_int()
  let row = if guess < 0 {
    0
  } else if guess >= starts.length() {
    starts.length() - 1
  } else {
    guess
  }
  let start = starts[row]
  let body = text[start:row_end(text, starts, row)].to_owned()
  let column = @text.index_at(back, body, font, pointer.x - inner.min.x)
  start + column
}

///|
/// The index one line up or down, keeping the column where it can.
fn same_column(
  back : &@back.Backend,
  text : String,
  starts : Array[Int32],
  font : @paint.FontId,
  at : Int32,
  by : Int32,
) -> Int32 {
  let row = row_of(starts, at)
  let target = row + by
  if target < 0 {
    return 0
  }
  if target >= starts.length() {
    return text.length()
  }
  let x = @text.x_at(
    back,
    text[starts[row]:row_end(text, starts, row)].to_owned(),
    font,
    at - starts[row],
  )
  let body = text[starts[target]:row_end(text, starts, target)].to_owned()
  starts[target] + @text.index_at(back, body, font, x)
}

///|
/// Put a string in where the selection was, and say where the caret ends up.
fn replace(
  text : String,
  at : Int32,
  other : Int32,
  what : String,
) -> (String, Int32) {
  let from = smaller(at, other)
  let to = larger(at, other)
  let cut = @text.remove(text, from, to)
  (@text.insert(cut, from, what), from + what.length())
}

///|
/// How far the text is scrolled so that the caret is inside the field.
fn scroll_for(
  back : &@back.Backend,
  text : String,
  font : @paint.FontId,
  at : Int32,
  room : Double,
) -> Double {
  let full = back.measure(text, font).x
  if full <= room {
    return 0
  }
  let caret = @text.x_at(back, text, font, at)
  @emath.clamp(caret - room, 0, full - room)
}

///|
fn clamp_to(index : Int32, length : Int32) -> Int32 {
  if index < 0 {
    0
  } else if index > length {
    length
  } else {
    index
  }
}

///|
fn smaller(a : Int32, b : Int32) -> Int32 {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn larger(a : Int32, b : Int32) -> Int32 {
  if a > b {
    a
  } else {
    b
  }
}
