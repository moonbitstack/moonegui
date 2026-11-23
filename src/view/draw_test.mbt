// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// One interface, written the way a frame writes it.
fn code_style(ui : @ctx.Ui) -> Unit {
  @widget.heading(ui, "Account") |> ignore
  @widget.edit(ui, "leo", hint="name") |> ignore
  @widget.checkbox(ui, "Remember", true) |> ignore
  @widget.separator(ui) |> ignore
  @widget.slider(ui, 0.5) |> ignore
}

///|
/// The same interface, written as a tree.
fn tree_style() -> Array[@view.View] {
  [
    @view.heading("Account"),
    @view.edit("leo", @view.Tag::new(1), hint="name"),
    @view.checkbox("Remember", @view.Tag::new(2), true),
    @view.separator(),
    @view.slider(@view.Tag::new(3), 0.5),
  ]
}

///|
/// The same interface written both ways draws the same commands, byte for byte.
///
/// This is the whole point of having two ways to write one interface: the tree
/// is not a second renderer, it is a way of saying what a frame says.
test "the same interface written both ways draws the same commands" {
  let rec = @back.Rec::new()
  let ctx = @ctx.Ctx::new(rec)
  let out = ctx.run(@input.Raw::new(screen), code_style)
  rec.clear()
  @back.play(out.shapes, rec)
  let by_hand = rec.text()
  assert_true(by_hand.contains("slider") || by_hand.contains("circle"))
  let s = stage()
  let by_tree = s.draw([], tree_style())
  assert_eq(by_tree, by_hand)
}

///|
test "a switch draws its knob at the end the value says" {
  let s = stage()
  inspect(
    s.draw([], [@view.switch(@view.Tag::new(1), false)]),
    content=(
      #|fill_rect (8,5)-(36,19) round=7,7,7,7 #28282e
      #|stroke_rect (8,5)-(36,19) round=7,7,7,7 #46464e w=1
      #|fill_circle (15,12) r=5 #8c8c8c
    ),
  )
  let on = stage()
  inspect(
    on.draw([], [@view.switch(@view.Tag::new(1), true)]),
    content=(
      #|fill_rect (8,5)-(36,19) round=7,7,7,7 #5c8cff
      #|stroke_rect (8,5)-(36,19) round=7,7,7,7 #46464e w=1
      #|fill_circle (29,12) r=5 #18181b
    ),
  )
}

///|
test "a progress bar fills the part it is told about" {
  let s = stage()
  inspect(
    s.draw([], [@view.progress(0.5, width=100)]),
    content=(
      #|fill_rect (0,0)-(100,7) round=3+32/64,3+32/64,3+32/64,3+32/64 #28282e
      #|stroke_rect (0,0)-(100,7) round=3+32/64,3+32/64,3+32/64,3+32/64 #46464e w=1
      #|fill_rect (0,0)-(50,7) round=3+32/64,3+32/64,3+32/64,3+32/64 #5c8cff
    ),
  )
}

///|
test "a progress bar past either end stays inside its track" {
  let s = stage()
  let over = s.draw([], [@view.progress(2.0, width=100)])
  assert_true(over.contains("(0,0)-(100,7) round=3+32/64"))
  let under = stage()
  let none = under.draw([], [@view.progress(-1.0, width=100)])
  assert_false(none.contains("#5c8cff"))
}

///|
test "a spinner is eight bars, and the phase moves which one leads" {
  let s = stage()
  let first = s.lines([], [@view.spinner(0.0)])
  assert_eq(first.length(), 8)
  let later = stage()
  let second = later.lines([], [@view.spinner(0.5)])
  assert_true(first[0] != second[0])
}

///|
test "a link is underlined in the accent colour" {
  let s = stage()
  inspect(
    s.draw([], [@view.hyperlink("here", @view.Tag::new(1))]),
    content=(
      #|text (8,4) sans/14 #5c8cff "here"
      #|fill_rect (8,20+32/64)-(36,21+32/64) #5c8cff
    ),
  )
}

///|
test "a badge is a pill with the word in it" {
  let s = stage()
  inspect(
    s.draw([], [@view.badge("new")]),
    content=(
      #|fill_rect (0,0)-(33,21+32/64) round=10+48/64,10+48/64,10+48/64,10+48/64 #5c8cff
      #|stroke_rect (0,0)-(33,21+32/64) round=10+48/64,10+48/64,10+48/64,10+48/64 #46464e w=1
      #|text (6,2) sans/14 #18181b "new"
    ),
  )
}

///|
test "an open drop-down draws its list under the field" {
  let s = stage()
  let views = [@view.combo(["one", "two"], @view.Tag::new(1), 1, open=true)]
  let lines = s.lines([], views)
  assert_eq(lines.length(), 8)
  assert_eq(lines[4], "fill_rect (0,25+32/64)-(160,51) round=4,4,4,4 #28282e")
  assert_eq(lines[5], "text (8,29+32/64) sans/14 #dedede \"one\"")
  // The chosen row is tinted, and it is the second one.
  assert_eq(lines[6], "fill_rect (0,51)-(160,76+32/64) round=4,4,4,4 #5c8cff46")
}

///|
test "pressing a row of an open drop-down chooses it and closes the list" {
  let s = stage()
  let views = [@view.combo(["one", "two"], @view.Tag::new(1), 1, open=true)]
  s.draw([], views) |> ignore
  s.draw(tap(20, 30), views) |> ignore
  let events = s.interp.events()
  assert_eq(events.length(), 2)
  assert_eq(events[0], @view.Chosen(tag=@view.Tag::new(1), at=0))
  assert_eq(events[1], @view.Opened(tag=@view.Tag::new(1), open=false))
}

///|
test "a folding header points at what it is doing" {
  let shut = stage()
  let folded = shut.lines([], [
    @view.group("More", false, @view.Tag::new(1), @view.text("body")),
  ])
  assert_eq(folded.length(), 2)
  let open = stage()
  let shown = open.lines([], [
    @view.group("More", true, @view.Tag::new(1), @view.text("body")),
  ])
  assert_eq(shown.length(), 3)
  assert_eq(shown[2], "text (0,31+32/64) sans/14 #dedede \"body\"")
}

///|
test "a list tints the row that is chosen" {
  let s = stage()
  inspect(
    s.draw([], [@view.list(["one", "two"], @view.Tag::new(1), 1)]),
    content=(
      #|text (8,4) sans/14 #dedede "one"
      #|fill_rect (0,25+32/64)-(37,51) #5c8cff3c
      #|text (8,29+32/64) sans/14 #dedede "two"
    ),
  )
}

///|
test "a table rules off its header and tints the row that is chosen" {
  let s = stage()
  inspect(
    s.draw([], [
      @view.table(["a", "b"], [["1", "2"]], @view.Tag::new(1), 0, width=160),
    ]),
    content=(
      #|text (8,4) sans/14 #8c8c8c "a"
      #|text (88,4) sans/14 #8c8c8c "b"
      #|fill_rect (0,24+32/64)-(160,25+32/64) #46464e
      #|fill_rect (0,25+32/64)-(160,51) #5c8cff3c
      #|text (8,29+32/64) sans/14 #dedede "1"
      #|text (88,29+32/64) sans/14 #dedede "2"
    ),
  )
}

///|
test "a field of several lines draws a line where each was written" {
  let s = stage()
  inspect(
    s.draw([], [@view.text_area("ab\ncd", @view.Tag::new(1), rows=2, width=100)]),
    content=(
      #|fill_rect (0,0)-(100,43) round=4,4,4,4 #28282e
      #|stroke_rect (0,0)-(100,43) round=4,4,4,4 #46464e w=1
      #|text (8,4) sans/14 #dedede "ab"
      #|text (8,21+32/64) sans/14 #dedede "cd"
    ),
  )
}

///|
test "a panel paints its ground before what is in it" {
  let s = stage()
  let lines = s.lines([], [@view.panel(@view.text("in"), title="Title")])
  assert_eq(lines[0], "fill_rect (0,0)-(30,65) round=4,4,4,4 #28282e")
  assert_eq(lines[2], "text (8,8) sans/21 #dedede \"Title\"")
  assert_eq(lines[3], "text (8,40+16/64) sans/14 #dedede \"in\"")
}

///|
test "a scrolling region clips what does not fit and shifts what does" {
  let s = stage()
  let views = [
    @view.scroll(
      @view.Tag::new(1),
      30,
      @view.column([@view.text("a"), @view.text("b"), @view.text("c")]),
    ),
  ]
  let lines = s.lines([], views)
  assert_eq(lines[0], "text (0,0) sans/14 #dedede \"a\"")
  assert_eq(lines[1], "clip (0,0)-(192,30)")
  // The third line starts past the window and is dropped rather than drawn.
  assert_false(s.rec.text().contains("\"c\""))
}

///|
test "the wheel moves a scrolling region" {
  let s = stage()
  let views = [
    @view.scroll(
      @view.Tag::new(1),
      30,
      @view.column([@view.text("a"), @view.text("b"), @view.text("c")]),
    ),
  ]
  s.draw([], views) |> ignore
  let wheel : Array[@input.Event] = [
    Scroll(at(0, -1)),
    PointerMoved(at(10, 10)),
  ]
  s.draw(wheel, views) |> ignore
  // A line and a half of scrolling: the first line is now above the window.
  assert_true(s.rec.text().contains("clip"))
  let moved = s.lines([], views)
  assert_true(moved[0] != "text (0,0) sans/14 #dedede \"a\"")
}
