// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
fn one_button() -> Array[@view.View] {
  [@view.button("Press", @view.Tag::new(1))]
}

///|
test "a frame that changed nothing builds nothing" {
  let s = stage()
  s.draw([], one_button()) |> ignore
  assert_eq(s.interp.rebuilt(), 1)
  assert_eq(s.interp.reused(), 0)
  s.draw([], one_button()) |> ignore
  assert_eq(s.interp.rebuilt(), 0)
  assert_eq(s.interp.reused(), 1)
}

///|
test "a replayed frame draws exactly what the frame before drew" {
  let s = stage()
  let first = s.draw([], one_button())
  let second = s.draw([], one_button())
  assert_eq(second, first)
}

///|
test "one changed node is built again and its neighbours are not" {
  let s = stage()
  let before = [
    @view.button("One", @view.Tag::new(1)),
    @view.button("Two", @view.Tag::new(2)),
    @view.button("Three", @view.Tag::new(3)),
  ]
  s.draw([], before) |> ignore
  assert_eq(s.interp.rebuilt(), 3)
  let after = [
    @view.button("One", @view.Tag::new(1)),
    @view.button("Second", @view.Tag::new(2)),
    @view.button("Three", @view.Tag::new(3)),
  ]
  s.draw([], after) |> ignore
  assert_eq(s.interp.rebuilt(), 1)
  assert_eq(s.interp.reused(), 2)
}

///|
test "a node whose word changed but whose size did not is built again" {
  let s = stage()
  let first = s.draw([], [@view.button("abc", @view.Tag::new(1))])
  let second = s.draw([], [@view.button("abd", @view.Tag::new(1))])
  // Same length, so the rectangle is the same and only the tree says otherwise.
  assert_eq(s.interp.rebuilt(), 1)
  assert_true(second != first)
  assert_true(second.contains("\"abd\""))
}

///|
test "a node that moves is built again even though nothing about it changed" {
  let s = stage()
  let short = [@view.text("a"), @view.button("Press", @view.Tag::new(1))]
  let tall = [
    @view.text("a"),
    @view.text("b"),
    @view.button("Press", @view.Tag::new(1)),
  ]
  s.draw([], short) |> ignore
  s.draw([], tall) |> ignore
  // The button's own data did not change; the room above it did.
  assert_eq(s.interp.rebuilt(), 2)
  assert_eq(s.interp.reused(), 1)
}

///|
test "a control the pointer is over is built again, and stops looking hovered when it leaves" {
  let s = stage()
  let plain = s.draw([], one_button())
  // The pointer arrives: the control is drawn hovered, one frame after it was
  // matched to the rectangle of the frame before.
  s.draw(hover(10, 10), one_button()) |> ignore
  let lit = s.draw([], one_button())
  assert_true(lit != plain)
  // The pointer leaves: the control has to be built again to lose the highlight,
  // which is what the `live` mark on the memo is for.
  s.draw(hover(150, 100), one_button()) |> ignore
  let after = s.draw([], one_button())
  assert_eq(after, plain)
  assert_eq(s.interp.rebuilt(), 0)
}

///|
test "a key press builds the controls that could take the keyboard" {
  let s = stage()
  let views = [@view.button("Press", @view.Tag::new(1)), @view.text("label")]
  s.draw([], views) |> ignore
  s.draw([@input.KeyDown(key=Tab, mods=@input.none, repeat=false)], views)
  |> ignore
  // The button can be reached with Tab; the label cannot.
  assert_eq(s.interp.rebuilt(), 1)
  assert_eq(s.interp.reused(), 1)
}

///|
test "a click on a replayed control still reaches it" {
  let s = stage()
  s.draw([], one_button()) |> ignore
  s.draw([], one_button()) |> ignore
  s.draw(tap(10, 10), one_button()) |> ignore
  let events = s.interp.events()
  assert_eq(events.length(), 1)
  assert_eq(events[0], @view.Clicked(@view.Tag::new(1)))
}

///|
test "a control that is gone leaves nothing behind" {
  let s = stage()
  s.draw([], one_button()) |> ignore
  s.draw([], []) |> ignore
  assert_eq(s.interp.reused(), 0)
  assert_eq(s.interp.rebuilt(), 0)
}

///|
test "an event says what the new value is" {
  let s = stage()
  let views = [@view.checkbox("Wrap", @view.Tag::new(7), false)]
  s.draw([], views) |> ignore
  s.draw(tap(10, 10), views) |> ignore
  let events = s.interp.events()
  assert_eq(events.length(), 1)
  assert_eq(events[0], @view.Toggled(tag=@view.Tag::new(7), value=true))
}

///|
test "typing in a field reports the whole new text" {
  let s = stage()
  let views = [@view.edit("ab", @view.Tag::new(3))]
  s.draw([], views) |> ignore
  // Past the end of the word, so the caret lands after it rather than before.
  s.draw(tap(60, 10), views) |> ignore
  s.draw([@input.Text("c")], views) |> ignore
  let events = s.interp.events()
  assert_eq(events.length(), 1)
  assert_eq(events[0], @view.Edited(tag=@view.Tag::new(3), text="abc"))
}

///|
test "a page of tabs reports which one was pressed" {
  let s = stage()
  let views = [@view.tabs(["one", "two"], @view.Tag::new(4), 0)]
  s.draw([], views) |> ignore
  // The second tab starts after the first: twenty-one points of word, sixteen
  // of padding and four of gap.
  s.draw(tap(45, 10), views) |> ignore
  let events = s.interp.events()
  assert_eq(events.length(), 1)
  assert_eq(events[0], @view.Chosen(tag=@view.Tag::new(4), at=1))
}

///|
test "a folded section reports that it was opened" {
  let s = stage()
  let views = [@view.group("More", false, @view.Tag::new(5), @view.text("a"))]
  s.draw([], views) |> ignore
  s.draw(tap(30, 10), views) |> ignore
  let events = s.interp.events()
  assert_eq(events.length(), 1)
  assert_eq(events[0], @view.Opened(tag=@view.Tag::new(5), open=true))
}

///|
test "forgetting everything builds everything again" {
  let s = stage()
  s.draw([], one_button()) |> ignore
  s.draw([], one_button()) |> ignore
  s.interp.reset()
  s.draw([], one_button()) |> ignore
  assert_eq(s.interp.rebuilt(), 1)
}

///|
test "a drag reports every new value while it is happening" {
  let s = stage()
  let views = [@view.slider(@view.Tag::new(9), 0.0, width=160)]
  s.draw([], views) |> ignore
  s.draw(tap(20, 12), views) |> ignore
  let down : Array[@input.Event] = [
    PointerMoved(at(120, 12)),
    PointerButton(at=at(120, 12), btn=Primary, down=true, mods=@input.none),
  ]
  s.draw(down, views) |> ignore
  assert_eq(s.interp.events().length(), 1)
  match s.interp.events()[0] {
    Moved(tag~, value~) => {
      assert_eq(tag, @view.Tag::new(9))
      assert_true(value > 0.5)
    }
    _ => fail("a moved slider reports a move")
  }
}
