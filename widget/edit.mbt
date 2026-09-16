// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

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
  hint? : String = "",
  width? : Double = 200,
  salt? : String = "edit",
) -> (String, @hit.Response) {
  let style = ui.style()
  let back = ui.ctx().backend()
  let font = style.font
  let line_height = ui.line_height()
  let height = most(style.min_height, line_height + style.padding.y * 2)
  let (rect, response) = ui.allocate(
    { x: width, y: height, },
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
/// Put a string in where the selection was, and say where the caret ends up.
fn replace(
  text : String,
  at : Int,
  other : Int,
  what : String,
) -> (String, Int) {
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
  at : Int,
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
fn clamp_to(index : Int, length : Int) -> Int {
  if index < 0 {
    0
  } else if index > length {
    length
  } else {
    index
  }
}

///|
fn smaller(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn larger(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}
