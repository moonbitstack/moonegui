// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// The size each of these nodes asks for, measured on a screen of the size the
/// other tests use.
fn measured(
  views : Array[@view.View],
  room~ : @emath.Vec2 = screen.size(),
) -> Array[@emath.Vec2] {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let sizes : Array[@emath.Vec2] = []
  ctx.run(@input.Raw::new(screen), fn(ui) {
    for view in views {
      sizes.push(view.size(ui, room~))
    }
  })
  |> ignore
  sizes
}

///|
fn width_of(view : @view.View) -> Double {
  measured([view])[0].x
}

///|
fn height_of(view : @view.View) -> Double {
  measured([view])[0].y
}

///|
test "a control asks for its text and its padding, and no less than a pointer" {
  // The recording backend's font is seven points a character at size fourteen,
  // and its lines are half again as tall as the font.
  assert_eq(width_of(@view.button("One", @view.Tag::new(1))), 37)
  assert_eq(height_of(@view.button("One", @view.Tag::new(1))), 25.5)
  assert_eq(width_of(@view.text("abc")), 21)
  assert_eq(height_of(@view.text("abc")), 17.5)
}

///|
test "a heading is half again the body text" {
  assert_eq(width_of(@view.heading("abc")), 31.5)
  assert_eq(height_of(@view.heading("abc")), 26.25)
}

///|
test "a caption is smaller than the body text" {
  let caption = measured([@view.caption("abc")])[0]
  let body = measured([@view.text("abc")])[0]
  assert_true(caption.x < body.x)
  assert_true(caption.y < body.y)
}

///|
test "a row is its children side by side, and as tall as the tallest" {
  let size = measured([
      @view.row([
        @view.button("One", @view.Tag::new(1)),
        @view.button("Two", @view.Tag::new(2)),
      ]),
    ])[0]
  assert_eq(size.x, 37 + 8 + 37)
  assert_eq(size.y, 25.5)
}

///|
test "a column is its children stacked, with the style's gap between them" {
  let size = measured([
      @view.column([@view.text("a"), @view.text("b"), @view.text("c")]),
    ])[0]
  assert_eq(size.x, 7)
  assert_eq(size.y, 17.5 + 6 + 17.5 + 6 + 17.5)
}

///|
test "a gap of its own replaces the style's" {
  let size = measured([
      @view.column_with(@layout.column_flow.with_gap(20), [
        @view.text("a"),
        @view.text("b"),
      ]),
    ])[0]
  assert_eq(size.y, 17.5 + 20 + 17.5)
}

///|
test "padding is inside the row, not around the whole screen" {
  let size = measured([
      @view.row_with(@layout.row_flow.with_padding(10), [
        @view.button("a", @view.Tag::new(1)),
        @view.button("b", @view.Tag::new(2)),
      ]),
    ])[0]
  assert_eq(size.x, 20 + (23 + 8 + 23))
  assert_eq(size.y, 20 + 25.5)
}

///|
test "a stretched column fills the room across, and so do its children" {
  let size = measured([
      @view.column_with(@layout.column_flow.with_stretch(true), [
        @view.button("a", @view.Tag::new(1)),
      ]),
    ])[0]
  assert_eq(size.x, 200)
  assert_eq(size.y, 25.5)
}

///|
test "a grid is its columns across and its rows down" {
  let children : Array[@view.View] = []
  for i in 0..<4 {
    children.push(@view.button("a", @view.Tag::new(i)))
  }
  let size = measured([@view.grid(2, children)])[0]
  // Two columns filling the room, and two rows with the row gap between them.
  assert_eq(size.x, 200)
  assert_eq(size.y, 25.5 + 8 + 25.5)
}

///|
test "a box is never smaller than its least size nor bigger than its most" {
  let small = @view.sized(
    @layout.Bounds::at_least({ x: 120, y: 40, }),
    @view.text("a"),
  )
  assert_eq(width_of(small), 120)
  assert_eq(height_of(small), 40)
  let big = @view.sized(
    @layout.Bounds::at_most({ x: 5, y: 5, }),
    @view.button("long", @view.Tag::new(1)),
  )
  assert_eq(width_of(big), 5)
  assert_eq(height_of(big), 5)
}

///|
test "text breaks to the room it is given when it is asked to" {
  let roomy = measured([@view.paragraph("aa bb cc")], room={ x: 400, y: 400, })[0]
  assert_eq(roomy.y, 17.5)
  // Forty points is five characters: "aa bb" does not fit, so the break goes at
  // the space after "aa" and what is left fits on one line of its own.
  let narrow = measured([@view.paragraph("aa bb cc")], room={ x: 40, y: 400, })[0]
  assert_eq(narrow.y, 17.5 * 2)
}

///|
test "a scrolling region is as tall as it was told and as wide as the room" {
  let size = measured([
      @view.scroll(
        @view.Tag::new(1),
        80,
        @view.column([@view.text("a"), @view.text("b")]),
      ),
    ])[0]
  assert_eq(size.x, 200)
  assert_eq(size.y, 80)
}

///|
test "a list is as tall as its rows until it is told to be shorter" {
  let items = ["one", "two", "three"]
  assert_eq(height_of(@view.list(items, @view.Tag::new(1), 0)), 25.5 * 3)
  assert_eq(height_of(@view.list(items, @view.Tag::new(1), 0, height=40)), 40)
}

///|
test "a folded section does not ask for room for what is hidden" {
  let shut = height_of(
    @view.group("More", false, @view.Tag::new(1), @view.text("a")),
  )
  let open = height_of(
    @view.group("More", true, @view.Tag::new(1), @view.text("a")),
  )
  assert_eq(shut, 25.5)
  assert_eq(open, 25.5 + 6 + 17.5)
}

///|
test "a table asks for a row for the header and one for each row" {
  let table = @view.table(
    ["a", "b"],
    [["1", "2"], ["3", "4"]],
    @view.Tag::new(1),
    0,
  )
  assert_eq(height_of(table), 25.5 * 3)
}
