// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
let screen : @emath.Rect = @emath.Rect::of({ x: 0, y: 0, }, { x: 200, y: 100, })

///|
/// One interface, one recorder, and a clock that moves a second a frame so that
/// two clicks in two frames are never mistaken for a double click.
struct Harness {
  ctx : @ctx.Ctx
  rec : @back.Rec
  mut time : Double
}

///|
fn harness() -> Harness {
  let rec = @back.Rec::new()
  { ctx: @ctx.Ctx::new(rec), rec, time: 0, }
}

///|
fn Harness::draw(
  self : Harness,
  events : Array[@input.Event],
  body : (@ctx.Ui) -> Unit,
) -> String {
  let out = self.ctx.run(
    { screen, events, time: self.time, dt: 0.016, focused: true, },
    body,
  )
  self.time = self.time + 1
  self.rec.clear()
  @back.play(out.shapes, self.rec)
  self.rec.text()
}

///|
fn at(x : Double, y : Double) -> @emath.Vec2 {
  { x, y, }
}

///|
fn tap(x : Double, y : Double) -> Array[@input.Event] {
  [
    PointerMoved(at(x, y)),
    PointerButton(at=at(x, y), btn=Primary, down=true, mods=@input.none),
    PointerButton(at=at(x, y), btn=Primary, down=false, mods=@input.none),
  ]
}

///|
fn hover(x : Double, y : Double) -> Array[@input.Event] {
  [PointerMoved(at(x, y))]
}

///|
fn key(key : @input.Key, shift? : Bool = false) -> Array[@input.Event] {
  [KeyDown(key~, mods={ ctrl: false, alt: false, shift, }, repeat=false)]
}

///|
test "a label is drawn where it was placed, in the text colour" {
  let h = harness()
  inspect(
    h.draw([], fn(ui) { @widget.label(ui, "hello") |> ignore }),
    content=(
      #|text (0,0) sans/14 #dedede "hello"
    ),
  )
}

///|
test "a weak label is drawn in the colour meant to be ignored" {
  let h = harness()
  inspect(
    h.draw([], fn(ui) { @widget.weak(ui, "hint") |> ignore }),
    content=(
      #|text (0,0) sans/14 #8c8c8c "hint"
    ),
  )
}

///|
test "a heading is drawn in a larger font" {
  let h = harness()
  inspect(
    h.draw([], fn(ui) { @widget.heading(ui, "hi") |> ignore }),
    content=(
      #|text (0,0) sans/21 #dedede "hi"
    ),
  )
}

///|
test "a wrapped label becomes one drawing command a row" {
  let h = harness()
  inspect(
    h.draw([], fn(ui) {
      ui.child(
        @layout.top_down,
        fn(narrow) {
          @widget.label(narrow, "one two three", wrap=true) |> ignore
        },
        size={ x: 30, y: 100, },
      )
      |> ignore
    }),
    content=(
      #|text (0,0) sans/14 #dedede "one"
      #|text (0,17+32/64) sans/14 #dedede "two"
      #|text (0,35) sans/14 #dedede "thre"
      #|text (0,52+32/64) sans/14 #dedede "e"
    ),
  )
}

///|
test "a label does not take the pointer away from what is under it" {
  let h = harness()
  let mut hovered = true
  let build = fn(ui : @ctx.Ui) { hovered = @widget.label(ui, "hello").hovered }
  h.draw(hover(10, 5), build) |> ignore
  h.draw([], build) |> ignore
  assert_false(hovered)
}

///|
test "a separator is a thin rule across the region" {
  let h = harness()
  inspect(
    h.draw([], fn(ui) { @widget.separator(ui) |> ignore }),
    content=(
      #|fill_rect (0,3)-(200,4) #46464e
    ),
  )
}

///|
test "a button is a rounded box with its label in the middle" {
  let h = harness()
  inspect(
    h.draw([], fn(ui) { @widget.button(ui, "ok") |> ignore }),
    content=(
      #|fill_rect (0,0)-(30,25+32/64) round=4,4,4,4 #28282e
      #|stroke_rect (0,0)-(30,25+32/64) round=4,4,4,4 #46464e w=1
      #|text (8,4) sans/14 #dedede "ok"
    ),
  )
}

///|
test "a button under the pointer is drawn differently" {
  let h = harness()
  let build = fn(ui : @ctx.Ui) { @widget.button(ui, "ok") |> ignore }
  h.draw(hover(10, 10), build) |> ignore
  inspect(
    h.draw([], build),
    content=(
      #|fill_rect (0,0)-(30,25+32/64) round=4,4,4,4 #383840
      #|stroke_rect (0,0)-(30,25+32/64) round=4,4,4,4 #46464e w=1
      #|text (8,4) sans/14 #dedede "ok"
    ),
  )
}

///|
test "a button is clicked on the frame after it was drawn" {
  let h = harness()
  let mut clicked = false
  let build = fn(ui : @ctx.Ui) { clicked = @widget.button(ui, "ok").clicked }
  h.draw(tap(10, 10), build) |> ignore
  assert_false(clicked)
  h.draw(tap(10, 10), build) |> ignore
  assert_true(clicked)
}

///|
test "a click outside a button is not a click on it" {
  let h = harness()
  let mut clicked = false
  let build = fn(ui : @ctx.Ui) { clicked = @widget.button(ui, "ok").clicked }
  h.draw(tap(150, 80), build) |> ignore
  h.draw(tap(150, 80), build) |> ignore
  assert_false(clicked)
}

///|
test "a button reached with the keyboard can be pressed with it" {
  let h = harness()
  let mut clicked = false
  let mut focused = false
  let build = fn(ui : @ctx.Ui) {
    let response = @widget.button(ui, "ok")
    clicked = response.clicked
    focused = response.focused
  }
  h.draw([], build) |> ignore
  h.draw(key(Tab), build) |> ignore
  h.draw(key(Enter), build) |> ignore
  assert_true(focused)
  assert_true(clicked)
  h.draw(key(Space), build) |> ignore
  assert_true(clicked)
  h.draw([], build) |> ignore
  assert_false(clicked)
}

///|
test "a focused button is outlined in the accent colour" {
  let h = harness()
  let build = fn(ui : @ctx.Ui) { @widget.button(ui, "ok") |> ignore }
  h.draw([], build) |> ignore
  h.draw(key(Tab), build) |> ignore
  inspect(
    h.draw([], build),
    content=(
      #|fill_rect (0,0)-(30,25+32/64) round=4,4,4,4 #28282e
      #|stroke_rect (0,0)-(30,25+32/64) round=4,4,4,4 #5c8cff w=1
      #|text (8,4) sans/14 #dedede "ok"
    ),
  )
}

///|
test "the button a screen is about is drawn in the accent colour" {
  let h = harness()
  inspect(
    h.draw([], fn(ui) { @widget.accent_button(ui, "go") |> ignore }),
    content=(
      #|fill_rect (0,0)-(30,25+32/64) round=4,4,4,4 #5c8cff
      #|stroke_rect (0,0)-(30,25+32/64) round=4,4,4,4 #46464e w=1
      #|text (8,4) sans/14 #18181b "go"
    ),
  )
}

///|
test "an unticked box is a box, and a ticked one has a tick in it" {
  let h = harness()
  inspect(
    h.draw([], fn(ui) { @widget.checkbox(ui, "on", false) |> ignore }),
    content=(
      #|fill_rect (8,5+48/64)-(22,19+48/64) round=2,2,2,2 #28282e
      #|stroke_rect (8,5+48/64)-(22,19+48/64) round=2,2,2,2 #46464e w=1
      #|text (30,4) sans/14 #dedede "on"
    ),
  )
  inspect(
    h.draw([], fn(ui) { @widget.checkbox(ui, "on", true) |> ignore }),
    content=(
      #|fill_rect (8,5+48/64)-(22,19+48/64) round=2,2,2,2 #28282e
      #|stroke_rect (8,5+48/64)-(22,19+48/64) round=2,2,2,2 #46464e w=1
      #|stroke_path (11+5/64,13+2/64)-(13+56/64,16+7/64)-(18+59/64,9+43/64) #5c8cff w=2
      #|text (30,4) sans/14 #dedede "on"
    ),
  )
}

///|
test "clicking a box turns it over, and says that it changed" {
  let h = harness()
  let mut value = false
  let mut changed = false
  let build = fn(ui : @ctx.Ui) {
    let (out, response) = @widget.checkbox(ui, "on", value)
    value = out
    changed = response.changed
  }
  h.draw(tap(10, 10), build) |> ignore
  assert_false(value)
  assert_false(changed)
  h.draw(tap(10, 10), build) |> ignore
  assert_true(value)
  assert_true(changed)
  h.draw(tap(10, 10), build) |> ignore
  assert_false(value)
  h.draw([], build) |> ignore
  assert_false(changed)
}

///|
test "a box can be ticked from the keyboard" {
  let h = harness()
  let mut value = false
  let build = fn(ui : @ctx.Ui) {
    let (out, _) = @widget.checkbox(ui, "on", value)
    value = out
  }
  h.draw([], build) |> ignore
  h.draw(key(Tab), build) |> ignore
  h.draw(key(Space), build) |> ignore
  assert_true(value)
}

///|
test "choosing one of a set says so, and choosing it again changes nothing" {
  let h = harness()
  let mut chosen = false
  let mut changed = false
  let build = fn(ui : @ctx.Ui) {
    let (out, response) = @widget.radio(ui, "one", chosen)
    chosen = out
    changed = response.changed
  }
  h.draw(tap(10, 10), build) |> ignore
  h.draw(tap(10, 10), build) |> ignore
  assert_true(chosen)
  assert_true(changed)
  h.draw(tap(10, 10), build) |> ignore
  assert_true(chosen)
  assert_false(changed)
}

///|
test "a chosen one is drawn with its middle filled in" {
  let h = harness()
  inspect(
    h.draw([], fn(ui) { @widget.radio(ui, "one", true) |> ignore }),
    content=(
      #|fill_circle (15,12+48/64) r=7 #28282e
      #|stroke_circle (15,12+48/64) r=7 #46464e w=1
      #|fill_circle (15,12+48/64) r=3+32/64 #5c8cff
      #|text (30,4) sans/14 #dedede "one"
    ),
  )
}

///|
test "a slider is a track with a handle on it" {
  let h = harness()
  inspect(
    h.draw([], fn(ui) { @widget.slider(ui, 0.5) |> ignore }),
    content=(
      #|fill_rect (8,10)-(152,14) round=2,2,2,2 #28282e
      #|fill_rect (8,10)-(80,14) round=2,2,2,2 #5c8cff
      #|fill_circle (80,12) r=8 #28282e
      #|stroke_circle (80,12) r=8 #46464e w=1
    ),
  )
}

///|
test "pressing a slider moves its handle to the pointer" {
  let h = harness()
  let mut value = 0.0
  let mut changed = false
  let build = fn(ui : @ctx.Ui) {
    let (out, response) = @widget.slider(ui, value)
    value = out
    changed = response.changed
  }
  h.draw(hover(80, 12), build) |> ignore
  assert_eq(value, 0)
  h.draw(
    [PointerButton(at=at(80, 12), btn=Primary, down=true, mods=@input.none)],
    build,
  )
  |> ignore
  assert_eq(value, 0.5)
  assert_true(changed)
}

///|
test "a slider dragged past its end stops at its end" {
  let h = harness()
  let mut value = 0.5
  let build = fn(ui : @ctx.Ui) {
    let (out, _) = @widget.slider(ui, value, low=0, high=10)
    value = out
  }
  h.draw(hover(80, 12), build) |> ignore
  h.draw(
    [PointerButton(at=at(80, 12), btn=Primary, down=true, mods=@input.none)],
    build,
  )
  |> ignore
  assert_eq(value, 5)
  // The pointer has left the slider, but the drag it started has not.
  h.draw([PointerMoved(at(500, 12))], build) |> ignore
  assert_eq(value, 10)
  h.draw([PointerMoved(at(-500, 12))], build) |> ignore
  assert_eq(value, 0)
  h.draw(
    [PointerButton(at=at(-500, 12), btn=Primary, down=false, mods=@input.none)],
    build,
  )
  |> ignore
  h.draw([PointerMoved(at(140, 12))], build) |> ignore
  assert_eq(value, 0)
}

///|
test "a slider steps with the arrow keys and jumps with home and end" {
  let h = harness()
  let mut value = 0.5
  let build = fn(ui : @ctx.Ui) {
    let (out, _) = @widget.slider(ui, value)
    value = out
  }
  h.draw([], build) |> ignore
  h.draw(key(Tab), build) |> ignore
  h.draw(key(Right), build) |> ignore
  assert_eq(value, 0.55)
  h.draw(key(Left), build) |> ignore
  assert_eq(value, 0.5)
  h.draw(key(Home), build) |> ignore
  assert_eq(value, 0)
  h.draw(key(End), build) |> ignore
  assert_eq(value, 1)
}

///|
test "a slider with a label draws both, and still answers for the slider" {
  let h = harness()
  let mut value = 0.25
  let build = fn(ui : @ctx.Ui) {
    let (out, _) = @widget.slider_with_label(ui, "size", value)
    value = out
  }
  let drawn = h.draw([], build)
  assert_true(drawn.contains("\"size\""))
  h.draw(hover(80, 12), build) |> ignore
  h.draw(
    [PointerButton(at=at(80, 12), btn=Primary, down=true, mods=@input.none)],
    build,
  )
  |> ignore
  assert_eq(value, 0.5)
}

///|
fn Harness::field(
  self : Harness,
  events : Array[@input.Event],
  value : String,
) -> String {
  let mut out = value
  self.draw(events, fn(ui) {
    let (text, _) = @widget.edit(ui, out, hint="name")
    out = text
  })
  |> ignore
  out
}

///|
test "an empty field shows its hint until something is typed in it" {
  let h = harness()
  inspect(
    h.draw([], fn(ui) { @widget.edit(ui, "", hint="name") |> ignore }),
    content=(
      #|fill_rect (0,0)-(200,25+32/64) round=4,4,4,4 #28282e
      #|stroke_rect (0,0)-(200,25+32/64) round=4,4,4,4 #46464e w=1
      #|text (8,4) sans/14 #8c8c8c "name"
    ),
  )
}

///|
test "a field with text in it draws the text, and a caret when focused" {
  let h = harness()
  let build = fn(ui : @ctx.Ui) { @widget.edit(ui, "ab") |> ignore }
  h.draw([], build) |> ignore
  h.draw(key(Tab), build) |> ignore
  inspect(
    h.draw([], build),
    content=(
      #|fill_rect (0,0)-(200,25+32/64) round=4,4,4,4 #28282e
      #|stroke_rect (0,0)-(200,25+32/64) round=4,4,4,4 #5c8cff w=1
      #|text (8,4) sans/14 #dedede "ab"
      #|stroke_path (22,4)-(22,21+32/64) #5c8cff w=1
    ),
  )
}

///|
test "typing into a focused field puts the characters in it" {
  let h = harness()
  let mut value = ""
  value = h.field([], value)
  value = h.field(tap(20, 10), value)
  value = h.field([Text("h"), Text("i")], value)
  assert_eq(value, "hi")
}

///|
test "a field that has not been clicked into ignores what is typed" {
  let h = harness()
  let mut value = ""
  value = h.field([], value)
  value = h.field([Text("h")], value)
  assert_eq(value, "")
}

///|
test "backspace takes the character before the caret" {
  let h = harness()
  let mut value = ""
  value = h.field([], value)
  value = h.field(tap(20, 10), value)
  value = h.field([Text("abc")], value)
  value = h.field(key(Backspace), value)
  assert_eq(value, "ab")
  value = h.field(key(Backspace), value)
  value = h.field(key(Backspace), value)
  value = h.field(key(Backspace), value)
  assert_eq(value, "")
}

///|
test "the caret moves with the arrows, and typing follows it" {
  let h = harness()
  let mut value = ""
  value = h.field([], value)
  value = h.field(tap(20, 10), value)
  value = h.field([Text("ac")], value)
  value = h.field(key(Left), value)
  value = h.field([Text("b")], value)
  assert_eq(value, "abc")
  value = h.field(key(Home), value)
  value = h.field([Text("z")], value)
  assert_eq(value, "zabc")
  value = h.field(key(End), value)
  value = h.field([Text("!")], value)
  assert_eq(value, "zabc!")
}

///|
test "delete takes the character after the caret" {
  let h = harness()
  let mut value = ""
  value = h.field([], value)
  value = h.field(tap(20, 10), value)
  value = h.field([Text("abc")], value)
  value = h.field(key(Home), value)
  value = h.field(key(Delete), value)
  assert_eq(value, "bc")
  value = h.field(key(End), value)
  value = h.field(key(Delete), value)
  assert_eq(value, "bc")
}

///|
test "shift and an arrow selects, and typing replaces what is selected" {
  let h = harness()
  let mut value = ""
  value = h.field([], value)
  value = h.field(tap(20, 10), value)
  value = h.field([Text("abcd")], value)
  value = h.field(key(Left, shift=true), value)
  value = h.field(key(Left, shift=true), value)
  value = h.field([Text("Z")], value)
  assert_eq(value, "abZ")
}

///|
test "backspace with a selection takes the selection" {
  let h = harness()
  let mut value = ""
  value = h.field([], value)
  value = h.field(tap(20, 10), value)
  value = h.field([Text("abcd")], value)
  value = h.field(key(Home, shift=true), value)
  value = h.field(key(Backspace), value)
  assert_eq(value, "")
}

///|
test "pasting puts the whole clipboard in at once" {
  let h = harness()
  let mut value = ""
  value = h.field([], value)
  value = h.field(tap(20, 10), value)
  value = h.field([Paste("pasted")], value)
  assert_eq(value, "pasted")
}

///|
test "clicking in the middle of the text puts the caret there" {
  let h = harness()
  let mut value = ""
  value = h.field([], value)
  value = h.field(tap(20, 10), value)
  value = h.field([Text("abcd")], value)
  // Eight pixels of padding and seven a character: this lands between the
  // second and the third.
  value = h.field(tap(22, 10), value)
  value = h.field([Text("-")], value)
  assert_eq(value, "ab-cd")
}

///|
test "a selection is drawn behind the text it covers" {
  let h = harness()
  let mut value = ""
  value = h.field([], value)
  value = h.field(tap(20, 10), value)
  value = h.field([Text("abcd")], value)
  let drawn = h.draw(key(Left, shift=true), fn(ui) {
    @widget.edit(ui, value) |> ignore
  })
  assert_true(drawn.contains("#5c8cff60"))
}

///|
test "text too long for the field is scrolled so the caret stays in view" {
  let h = harness()
  let mut value = ""
  value = h.field([], value)
  value = h.field(tap(20, 10), value)
  value = h.field([Text("abcdefghijklmnopqrstuvwxyz0123456789")], value)
  let drawn = h.draw([], fn(ui) { @widget.edit(ui, value) |> ignore })
  assert_true(drawn.contains("text (-60,"))
}
