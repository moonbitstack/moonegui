// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
let sheet : @emath.Rect = @emath.Rect::of({ x: 0, y: 0, }, { x: 200, y: 100, })

///|
/// A backend written here rather than in the library, which is what every host
/// is: it is handed the contract and nothing else, and it decides what a frame
/// becomes. This one writes down what it was asked for, so a test can ask the
/// questions a real surface would answer with pixels.
struct Tally {
  log : Array[String]
}

///|
fn Tally::new() -> Tally {
  { log: [], }
}

///|
fn Tally::count(self : Tally, prefix : String) -> Int32 {
  let mut found = 0
  for line in self.log {
    if line.has_prefix(prefix) {
      found = found + 1
    }
  }
  found
}

///|
/// True when one of the lines says this.
fn Tally::has(self : Tally, part : String) -> Bool {
  for line in self.log {
    if line.contains(part) {
      return true
    }
  }
  false
}

///|
/// How deep the clips are at the end: a backend left inside a clip would cut
/// everything the next frame draws.
fn Tally::depth(self : Tally) -> Int32 {
  let mut depth = 0
  for line in self.log {
    if line == "push" {
      depth = depth + 1
    } else if line == "pop" {
      depth = depth - 1
    }
  }
  depth
}

///|
impl @back.Backend for Tally with fn measure(self, text, font) {
  self.log.push("measure")
  { x: text.length().to_double() * font.size * 0.5, y: font.size * 1.25, }
}

///|
impl @back.Backend for Tally with fn line_height(_self, font) {
  font.size * 1.25
}

///|
impl @back.Backend for Tally with fn measure_prefix(self, text, font, width) {
  self.log.push("prefix")
  let per = font.size * 0.5
  if per <= 0 {
    return text.length()
  }
  let fits = (width / per).to_int()
  if fits <= 0 {
    0
  } else if fits >= text.length() {
    text.length()
  } else {
    fits
  }
}

///|
impl @back.Backend for Tally with fn push_clip(self, _rect) {
  self.log.push("push")
}

///|
impl @back.Backend for Tally with fn pop_clip(self) {
  self.log.push("pop")
}

///|
impl @back.Backend for Tally with fn fill_rect(self, _rect, _corner, _color) {
  self.log.push("rect")
}

///|
impl @back.Backend for Tally with fn stroke_rect(self, _rect, _corner, _stroke) {
  self.log.push("framed")
}

///|
impl @back.Backend for Tally with fn fill_circle(self, _centre, _radius, _color) {
  self.log.push("disc")
}

///|
impl @back.Backend for Tally with fn stroke_circle(
  self,
  _centre,
  _radius,
  _stroke,
) {
  self.log.push("ring")
}

///|
impl @back.Backend for Tally with fn stroke_path(
  self,
  _points,
  _closed,
  _stroke,
) {
  self.log.push("line")
}

///|
impl @back.Backend for Tally with fn fill_path(self, _points, _color) {
  self.log.push("area")
}

///|
impl @back.Backend for Tally with fn fill_text(self, at, text, _font, _color) {
  self.log.push("text " + @back.number(at.y) + " " + text)
}

///|
test "a host outside the library paints a frame through the contract alone" {
  let tally = Tally::new()
  let context = @ctx.Ctx::new(tally)
  let out = context.run(@input.Raw::new(sheet), fn(ui) {
    @widget.heading(ui, "held") |> ignore
    @widget.button(ui, "press") |> ignore
  })
  @back.play(out.shapes, tally)
  // Lay out means ask: the frame was measured by the backend it was given.
  assert_eq(tally.count("measure") > 0, true)
  // Two widgets, one of them a button, which is a filled rectangle.
  assert_eq(tally.count("rect"), 1)
  assert_eq(tally.count("text "), 2)
  // Nothing was clipped in a frame this small, and nothing was left open.
  assert_eq(tally.count("push"), 0)
  assert_eq(tally.depth(), 0)
  assert_eq(tally.has(" held"), true)
  assert_eq(tally.has(" press"), true)
}

///|
test "a click reaches a widget through a backend the library has never seen" {
  let tally = Tally::new()
  let context = @ctx.Ctx::new(tally)
  let mut button : @emath.Rect = @emath.Rect::of(@emath.zero, @emath.zero)
  let mut clicked = false
  let draw = fn(raw) {
    let out = context.run(raw, fn(ui) {
      let response = @widget.button(ui, "press")
      button = response.rect
      clicked = response.clicked
    })
    @back.play(out.shapes, tally)
  }
  draw(@input.Raw::new(sheet))
  let middle = button.centre()
  let events : Array[@input.Event] = [
    PointerMoved(middle),
    PointerButton(at=middle, btn=Primary, down=true, mods=@input.none),
    PointerButton(at=middle, btn=Primary, down=false, mods=@input.none),
  ]
  draw({ screen: sheet, events, time: 1.0, dt: 0.016, focused: true, })
  assert_eq(clicked, true)
}
