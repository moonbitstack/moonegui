// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A backend that writes down what it was asked to draw.
///
/// This is what the library is tested against. A frame becomes a list of lines,
/// a test compares that list, and nothing needs a screen, a font file or a
/// browser. Its font is deliberately fake and exactly regular: every character
/// is the same width, so a measurement is a multiplication and a test can work
/// out the expected numbers by hand.
pub struct Rec {
  lines : Array[String]
  advance : Double
  height : Double
}

///|
/// A recorder whose characters are `advance` wide and whose lines are `height`
/// apart, both as a fraction of the font size.
pub fn Rec::new(advance? : Double = 0.5, height? : Double = 1.25) -> Rec {
  { lines: [], advance, height, }
}

///|
/// Everything drawn so far, one command per line.
pub fn Rec::text(self : Rec) -> String {
  let out = StringBuilder()
  for i in 0..<self.lines.length() {
    if i > 0 {
      out.write_string("\n")
    }
    out.write_string(self.lines[i])
  }
  out.to_string()
}

///|
/// The commands as a list.
pub fn Rec::lines(self : Rec) -> Array[String] {
  self.lines
}

///|
/// Forget what was drawn, which is how a test looks at one frame at a time.
pub fn Rec::clear(self : Rec) -> Unit {
  self.lines.clear()
}

///|
pub impl Backend for Rec with fn measure(self, text, font) {
  {
    x: chars(text).to_double() * font.size * self.advance,
    y: font.size * self.height,
  }
}

///|
pub impl Backend for Rec with fn line_height(self, font) {
  font.size * self.height
}

///|
pub impl Backend for Rec with fn measure_prefix(self, text, font, width) {
  let per = font.size * self.advance
  if per <= 0 {
    return text.length()
  }
  let fits = (width / per).to_int()
  if fits <= 0 {
    0
  } else if fits >= chars(text) {
    text.length()
  } else {
    index_of_char(text, fits)
  }
}

///|
pub impl Backend for Rec with fn push_clip(self, rect) {
  self.lines.push("clip " + rect_text(rect))
}

///|
pub impl Backend for Rec with fn pop_clip(self) {
  self.lines.push("unclip")
}

///|
pub impl Backend for Rec with fn fill_rect(self, rect, corner, color) {
  self.lines.push(
    "fill_rect " +
    rect_text(rect) +
    corner_text(corner) +
    " " +
    color_text(color),
  )
}

///|
pub impl Backend for Rec with fn stroke_rect(self, rect, corner, stroke) {
  self.lines.push(
    "stroke_rect " +
    rect_text(rect) +
    corner_text(corner) +
    " " +
    stroke_text(stroke),
  )
}

///|
pub impl Backend for Rec with fn fill_circle(self, centre, radius, color) {
  self.lines.push(
    "fill_circle " +
    point_text(centre) +
    " r=" +
    number(radius) +
    " " +
    color_text(color),
  )
}

///|
pub impl Backend for Rec with fn stroke_circle(self, centre, radius, stroke) {
  self.lines.push(
    "stroke_circle " +
    point_text(centre) +
    " r=" +
    number(radius) +
    " " +
    stroke_text(stroke),
  )
}

///|
pub impl Backend for Rec with fn stroke_path(self, points, closed, stroke) {
  self.lines.push(
    "stroke_path " +
    path_text(points) +
    (if closed { " closed" } else { "" }) +
    " " +
    stroke_text(stroke),
  )
}

///|
pub impl Backend for Rec with fn fill_path(self, points, color) {
  self.lines.push("fill_path " + path_text(points) + " " + color_text(color))
}

///|
pub impl Backend for Rec with fn fill_text(self, at, text, font, color) {
  self.lines.push(
    "text " +
    point_text(at) +
    " " +
    font_text(font) +
    " " +
    color_text(color) +
    " " +
    quote(text),
  )
}

///|
/// A number, printed as sixty-fourths.
///
/// Snapshots are compared across four backends, and a floating point number
/// does not print the same on all of them. Rounding to a fixed point first
/// removes the question: what reaches a snapshot is always an integer.
pub fn number(value : Double) -> String {
  let units = round_to_int(value * 64)
  let whole = units / 64
  let part = units % 64
  if part == 0 {
    whole.to_string()
  } else if part > 0 {
    whole.to_string() + "+" + part.to_string() + "/64"
  } else {
    (whole - 1).to_string() + "+" + (part + 64).to_string() + "/64"
  }
}

///|
fn round_to_int(value : Double) -> Int {
  if value >= 0 {
    (value + 0.5).to_int()
  } else {
    -(-value + 0.5).to_int()
  }
}

///|
fn point_text(point : @emath.Vec2) -> String {
  "(" + number(point.x) + "," + number(point.y) + ")"
}

///|
fn rect_text(rect : @emath.Rect) -> String {
  point_text(rect.min) + "-" + point_text(rect.max)
}

///|
fn corner_text(corner : @paint.Corner) -> String {
  if corner == @paint.square {
    ""
  } else {
    " round=" +
    number(corner.nw) +
    "," +
    number(corner.ne) +
    "," +
    number(corner.se) +
    "," +
    number(corner.sw)
  }
}

///|
fn color_text(color : @paint.Color) -> String {
  "#" +
  hex(color.r) +
  hex(color.g) +
  hex(color.b) +
  (if color.a == 255 { "" } else { hex(color.a) })
}

///|
fn stroke_text(stroke : @paint.Stroke) -> String {
  color_text(stroke.color) + " w=" + number(stroke.width)
}

///|
fn font_text(font : @paint.FontId) -> String {
  (match font.family {
    Sans => "sans"
    Mono => "mono"
  }) +
  "/" +
  number(font.size)
}

///|
fn path_text(points : Array[@emath.Vec2]) -> String {
  let out = StringBuilder()
  for i in 0..<points.length() {
    if i > 0 {
      out.write_string("-")
    }
    out.write_string(point_text(points[i]))
  }
  out.to_string()
}

///|
fn quote(text : String) -> String {
  "\"" + text + "\""
}

///|
fn hex(value : Int) -> String {
  let digits = "0123456789abcdef"
  let hi = value / 16 % 16
  let lo = value % 16
  digits[hi:hi + 1].to_owned() + digits[lo:lo + 1].to_owned()
}

///|
/// How many characters a string has, counting a surrogate pair as one.
fn chars(text : String) -> Int {
  let mut count = 0
  let mut i = 0
  while i < text.length() {
    i = i + step(text, i)
    count = count + 1
  }
  count
}

///|
/// The code unit index of the nth character.
fn index_of_char(text : String, nth : Int) -> Int {
  let mut count = 0
  let mut i = 0
  while i < text.length() && count < nth {
    i = i + step(text, i)
    count = count + 1
  }
  i
}

///|
fn step(text : String, at : Int) -> Int {
  let unit = text[at].to_int()
  if unit >= 0xD800 && unit <= 0xDBFF && at + 1 < text.length() {
    2
  } else {
    1
  }
}
