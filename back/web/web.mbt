// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What every browser backend needs before it can draw anything: the surface's
/// size, the text metrics, and the input coming the other way.
///
/// Two backends draw a frame in a browser — one onto a canvas, one into the
/// document — and neither of them differs in how a string is measured or how a
/// key press arrives. Everything they share is here, so that a page drawn one
/// way and the same page drawn the other lay out identically.
pub fn attach(id : String) -> Unit {
  js_attach(id)
}

///|
/// How large the surface is, in the units a frame is laid out in.
pub fn size() -> @emath.Rect {
  @emath.Rect::of({ x: 0, y: 0, }, { x: js_width(), y: js_height(), })
}

///|
/// How many device pixels there are to a logical one.
pub fn pixels() -> Double {
  js_dpr()
}

///|
/// The time the page has been open, in seconds.
pub fn now() -> Double {
  js_now() / 1000.0
}

///|
/// Start listening for input on the surface.
pub fn listen() -> Unit {
  js_listen()
}

///|
/// Stop listening.
pub fn unlisten() -> Unit {
  js_unlisten()
}

///|
/// Everything that happened since the last frame.
pub fn raw(time : Double, dt : Double) -> @input.Raw {
  let events : Array[@input.Event] = []
  for line in lines(js_events()) {
    match event_of(line) {
      Some(event) => events.push(event)
      None => ()
    }
  }
  { screen: size(), events, time, dt, focused: js_focused(), }
}

///|
/// How much room a string takes in this font.
pub fn measure(text : String, font : @paint.FontId) -> @emath.Vec2 {
  { x: js_measure(text, font.size, mono(font)), y: js_line_height(font.size), }
}

///|
/// The distance between the tops of two consecutive lines.
pub fn line_height(font : @paint.FontId) -> Double {
  js_line_height(font.size)
}

///|
/// The longest prefix of the string that fits in this width.
pub fn prefix(text : String, font : @paint.FontId, room : Double) -> Int {
  js_prefix(text, font.size, mono(font), room)
}

///|
/// Which of the two families a font asks for, as the browser side spells it.
pub fn mono(font : @paint.FontId) -> Int {
  match font.family {
    Mono => 1
    Sans => 0
  }
}

///|
/// The lines of the event queue.
fn lines(text : String) -> Array[String] {
  let out : Array[String] = []
  let mut start = 0
  for i in 0..<text.length() {
    if text[i].to_int() == 10 {
      if i > start {
        out.push(text[start:i].to_owned())
      }
      start = i + 1
    }
  }
  if text.length() > start {
    out.push(text[start:].to_owned())
  }
  out
}

///|
/// One line of the event queue.
///
/// The browser's events are flattened into text rather than crossing the
/// boundary as objects: the foreign function interface carries numbers and
/// strings, and a line of text is the one shape that needs no marshalling on
/// either side.
fn event_of(line : String) -> @input.Event? {
  let parts = words(line, 5)
  if parts.length() == 0 {
    return None
  }
  match parts[0] {
    "m" => Some(PointerMoved(point(parts, 1)))
    "d" =>
      Some(
        PointerButton(
          at=point(parts, 1),
          btn=button(number(parts, 3)),
          down=true,
          mods=mods(number(parts, 4).to_int()),
        ),
      )
    "u" =>
      Some(
        PointerButton(
          at=point(parts, 1),
          btn=button(number(parts, 3)),
          down=false,
          mods=mods(number(parts, 4).to_int()),
        ),
      )
    "g" => Some(PointerGone)
    "s" => Some(Scroll(point(parts, 1)))
    "k" =>
      match key_of(word(parts, 1)) {
        Some(key) =>
          Some(
            KeyDown(key~, mods=mods(number(parts, 2).to_int()), repeat=false),
          )
        None => None
      }
    "t" => Some(Text(unescape(rest(line))))
    "v" => Some(Paste(unescape(rest(line))))
    "f" => Some(Focus(number(parts, 1) != 0))
    _ => None
  }
}

///|
fn key_of(name : String) -> @input.Key? {
  match name {
    "Enter" => Some(Enter)
    "Tab" => Some(Tab)
    "Backspace" => Some(Backspace)
    "Delete" => Some(Delete)
    "Escape" => Some(Escape)
    "Space" => Some(Space)
    "ArrowLeft" => Some(Left)
    "ArrowRight" => Some(Right)
    "ArrowUp" => Some(Up)
    "ArrowDown" => Some(Down)
    "Home" => Some(Home)
    "End" => Some(End)
    "PageUp" => Some(PageUp)
    "PageDown" => Some(PageDown)
    _ => None
  }
}

///|
fn button(index : Double) -> @input.Btn {
  if index >= 2 {
    Middle
  } else if index >= 1 {
    Secondary
  } else {
    Primary
  }
}

///|
fn mods(bits : Int) -> @input.Mods {
  { ctrl: bits % 2 == 1, alt: bits / 2 % 2 == 1, shift: bits / 4 % 2 == 1, }
}

///|
fn point(parts : Array[String], at : Int) -> @emath.Vec2 {
  { x: number(parts, at), y: number(parts, at + 1), }
}

///|
fn word(parts : Array[String], at : Int) -> String {
  if at < parts.length() {
    parts[at]
  } else {
    ""
  }
}

///|
fn number(parts : Array[String], at : Int) -> Double {
  parse(word(parts, at))
}

///|
/// A decimal number, which is all the protocol ever carries.
fn parse(text : String) -> Double {
  let mut whole = 0.0
  let mut fraction = 0.0
  let mut scale = 1.0
  let mut sign = 1.0
  let mut after = false
  for i in 0..<text.length() {
    let unit = text[i].to_int()
    if i == 0 && unit == 45 {
      sign = -1
      continue
    }
    if unit == 46 {
      after = true
      continue
    }
    if unit < 48 || unit > 57 {
      continue
    }
    let digit = (unit - 48).to_double()
    if after {
      scale = scale / 10
      fraction = fraction + digit * scale
    } else {
      whole = whole * 10 + digit
    }
  }
  sign * (whole + fraction)
}

///|
/// The first `most` words of a line.
fn words(line : String, most : Int) -> Array[String] {
  let out : Array[String] = []
  let mut start = 0
  for i in 0..<line.length() {
    if line[i].to_int() == 32 && out.length() < most {
      if i > start {
        out.push(line[start:i].to_owned())
      }
      start = i + 1
    }
  }
  if line.length() > start {
    out.push(line[start:].to_owned())
  }
  out
}

///|
/// Everything after the first space, which is where a line carrying text puts
/// it so that spaces in the text need no escaping.
fn rest(line : String) -> String {
  for i in 0..<line.length() {
    if line[i].to_int() == 32 {
      return line[i + 1:].to_owned()
    }
  }
  ""
}

///|
/// Newlines and backslashes come across escaped, since the queue is a line at a
/// time.
fn unescape(text : String) -> String {
  let out = StringBuilder()
  let mut i = 0
  while i < text.length() {
    let unit = text[i].to_int()
    if unit == 92 && i + 1 < text.length() {
      let next = text[i + 1].to_int()
      if next == 110 {
        out.write_string("\n")
        i = i + 2
        continue
      }
      if next == 92 {
        out.write_string("\\")
        i = i + 2
        continue
      }
    }
    out.write_string(text[i:i + 1].to_owned())
    i = i + 1
  }
  out.to_string()
}
