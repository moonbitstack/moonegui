// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A width no line ever reaches: text laid out against it is never broken.
pub let no_wrap : Double = 1.0e9

///|
/// Break a string into rows and measure them.
///
/// Newlines are honoured, and a row too wide for `wrap` is broken at the last
/// space that still fits, or mid-word when there is no space to break at. A
/// word longer than the whole line has to be cut somewhere, and cutting it is
/// better than letting it run off the edge.
pub fn layout(
  back : &@back.Backend,
  text : String,
  font : @paint.FontId,
  wrap? : Double = no_wrap,
  align? : @emath.Align = Min,
) -> @paint.Galley {
  let height = back.line_height(font)
  let lines : Array[String] = []
  for para in paragraphs(text) {
    for row in break_line(back, para, font, wrap) {
      lines.push(row)
    }
  }
  let widths : Array[Double] = []
  let mut widest = 0.0
  for line in lines {
    let width = back.measure(line, font).x
    widths.push(width)
    if width > widest {
      widest = width
    }
  }
  let rows : Array[@paint.TextRow] = []
  for i, line in lines {
    let at : @emath.Vec2 = {
      x: align.offset(widest, widths[i]),
      y: i.to_double() * height,
    }
    rows.push({ text: line, at, })
  }
  { rows, size: { x: widest, y: rows.length().to_double() * height, }, font, }
}

///|
/// Lay a string out as one row, however wide it turns out to be.
pub fn line(
  back : &@back.Backend,
  text : String,
  font : @paint.FontId,
) -> @paint.Galley {
  let size = back.measure(text, font)
  {
    rows: [{ text, at: @emath.zero, }],
    size: { x: size.x, y: back.line_height(font), },
    font,
  }
}

///|
/// Shorten a string until it fits, marking the cut with a tail.
pub fn elide(
  back : &@back.Backend,
  text : String,
  font : @paint.FontId,
  width : Double,
  tail? : String = "…",
) -> String {
  if back.measure(text, font).x <= width {
    return text
  }
  let room = width - back.measure(tail, font).x
  if room <= 0 {
    return tail
  }
  let cut = down(text, back.measure_prefix(text, font, room))
  text[0:cut].to_owned() + tail
}

///|
/// The code unit index a pointer at `x` is nearest to, `x` being measured from
/// the start of the text.
///
/// Nearest rather than last-that-fits: clicking the right half of a character
/// puts the caret after it, which is what every text field does.
pub fn index_at(
  back : &@back.Backend,
  text : String,
  font : @paint.FontId,
  x : Double,
) -> Int {
  let n = text.length()
  if n == 0 || x <= 0 {
    return 0
  }
  if x >= back.measure(text, font).x {
    return n
  }
  let before = down(text, back.measure_prefix(text, font, x))
  let after = next_index(text, before)
  let left = x_at(back, text, font, before)
  let right = x_at(back, text, font, after)
  if x - left <= right - x {
    before
  } else {
    after
  }
}

///|
/// How far into the text a caret at this index sits.
pub fn x_at(
  back : &@back.Backend,
  text : String,
  font : @paint.FontId,
  index : Int,
) -> Double {
  let at = clamp_index(index, text.length())
  back.measure(text[0:at].to_owned(), font).x
}

///|
/// The index one character on, never landing inside a surrogate pair.
pub fn next_index(text : String, index : Int) -> Int {
  let n = text.length()
  let at = clamp_index(index, n)
  if at >= n {
    return n
  }
  if is_high(text[at]) && at + 1 < n {
    at + 2
  } else {
    at + 1
  }
}

///|
/// The index one character back.
pub fn prev_index(text : String, index : Int) -> Int {
  let at = clamp_index(index, text.length())
  if at <= 0 {
    return 0
  }
  if at >= 2 && is_low(text[at - 1]) {
    at - 2
  } else {
    at - 1
  }
}

///|
/// Put a string in at an index.
pub fn insert(text : String, at : Int, what : String) -> String {
  let index = clamp_index(at, text.length())
  text[0:index].to_owned() + what + text[index:].to_owned()
}

///|
/// Take out everything between two indices.
pub fn remove(text : String, from : Int, to : Int) -> String {
  let n = text.length()
  let low = if from < to { from } else { to }
  let high = if from < to { to } else { from }
  let a = clamp_index(low, n)
  let b = clamp_index(high, n)
  text[0:a].to_owned() + text[b:].to_owned()
}

///|
/// The lines of the text, as written, before any breaking.
fn paragraphs(text : String) -> Array[String] {
  let out : Array[String] = []
  let n = text.length()
  let mut start = 0
  for i in 0..<n {
    if text[i].to_int() == 10 {
      let mut stop = i
      if stop > start && text[stop - 1].to_int() == 13 {
        stop = stop - 1
      }
      out.push(text[start:stop].to_owned())
      start = i + 1
    }
  }
  out.push(text[start:n].to_owned())
  out
}

///|
fn break_line(
  back : &@back.Backend,
  line : String,
  font : @paint.FontId,
  wrap : Double,
) -> Array[String] {
  if line.length() == 0 {
    return [""]
  }
  let out : Array[String] = []
  let mut rest = line
  while back.measure(rest, font).x > wrap {
    let fit = down(rest, back.measure_prefix(rest, font, wrap))
    // The cut has to move at least one character on, or a character wider than
    // the whole line would break here for ever.
    let mut cut = if fit < 1 { next_index(rest, 0) } else { fit }
    if cut >= rest.length() {
      break
    }
    let space = last_space(rest, cut)
    if space > 0 {
      cut = space
    }
    out.push(trim_end(rest[0:cut].to_owned()))
    let mut next = cut
    while next < rest.length() && is_space(rest[next]) {
      next = next + 1
    }
    if next >= rest.length() {
      return out
    }
    rest = rest[next:].to_owned()
  }
  out.push(rest)
  out
}

///|
/// The last space before `cut`, or zero when there is none to break at.
fn last_space(text : String, cut : Int) -> Int {
  let mut found = 0
  for i in 0..<cut {
    if is_space(text[i]) {
      found = i
    }
  }
  found
}

///|
fn trim_end(text : String) -> String {
  let mut stop = text.length()
  while stop > 0 && is_space(text[stop - 1]) {
    stop = stop - 1
  }
  text[0:stop].to_owned()
}

///|
fn is_space(unit : UInt16) -> Bool {
  unit.to_int() == 32 || unit.to_int() == 9
}

///|
fn is_high(unit : UInt16) -> Bool {
  let value = unit.to_int()
  value >= 0xD800 && value <= 0xDBFF
}

///|
fn is_low(unit : UInt16) -> Bool {
  let value = unit.to_int()
  value >= 0xDC00 && value <= 0xDFFF
}

///|
/// The nearest index at or before this one that is not inside a surrogate pair.
fn down(text : String, index : Int) -> Int {
  let at = clamp_index(index, text.length())
  if at > 0 && at < text.length() && is_low(text[at]) {
    at - 1
  } else {
    at
  }
}

///|
fn clamp_index(index : Int, length : Int) -> Int {
  if index < 0 {
    0
  } else if index > length {
    length
  } else {
    index
  }
}
