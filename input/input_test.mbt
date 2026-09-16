// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
let screen : @emath.Rect = @emath.Rect::of({ x: 0, y: 0, }, { x: 100, y: 100, })

///|
fn frame(events : Array[@input.Event], time? : Double = 0) -> @input.Raw {
  { screen, events, time, dt: 0.016, focused: true, }
}

///|
fn at(x : Double, y : Double) -> @emath.Vec2 {
  { x, y, }
}

///|
test "a frame with nothing in it leaves the pointer where it was" {
  let state = @input.State::new()
  state.begin(frame([PointerMoved(at(10, 10))]))
  assert_eq(state.pointer(), Some(at(10, 10)))
  state.begin(frame([]))
  assert_eq(state.pointer(), Some(at(10, 10)))
  assert_eq(state.pointer_delta(), @emath.zero)
  assert_eq(state.screen(), screen)
}

///|
test "the pointer's movement is the distance covered in the frame" {
  let state = @input.State::new()
  state.begin(frame([PointerMoved(at(10, 10))]))
  assert_eq(state.pointer_delta(), @emath.zero)
  state.begin(frame([PointerMoved(at(15, 10)), PointerMoved(at(20, 10))]))
  assert_eq(state.pointer_delta(), at(10, 0))
}

///|
test "a press and a release in the same place is a click" {
  let state = @input.State::new()
  state.begin(
    frame([
      PointerButton(at=at(5, 5), btn=Primary, down=true, mods=@input.none),
      PointerButton(at=at(5, 5), btn=Primary, down=false, mods=@input.none),
    ]),
  )
  assert_true(state.pressed(Primary))
  assert_true(state.released(Primary))
  assert_true(state.clicked(Primary))
  assert_false(state.is_down(Primary))
}

///|
test "a press in one frame and a release in the next is still a click" {
  let state = @input.State::new()
  state.begin(
    frame([PointerButton(at=at(5, 5), btn=Primary, down=true, mods=@input.none)]),
  )
  assert_true(state.is_down(Primary))
  assert_false(state.clicked(Primary))
  state.begin(
    frame([
      PointerButton(at=at(7, 6), btn=Primary, down=false, mods=@input.none),
    ]),
  )
  assert_true(state.clicked(Primary))
  assert_eq(state.press_origin(Primary), at(5, 5))
}

///|
test "a release far from the press is a drag, and a drag is not a click" {
  let state = @input.State::new()
  state.begin(
    frame([PointerButton(at=at(5, 5), btn=Primary, down=true, mods=@input.none)]),
  )
  state.begin(
    frame([
      PointerButton(at=at(50, 5), btn=Primary, down=false, mods=@input.none),
    ]),
  )
  assert_true(state.released(Primary))
  assert_false(state.clicked(Primary))
}

///|
test "two clicks close together in time are a double click" {
  let state = @input.State::new()
  let press = fn(time : Double) {
    state.begin(
      frame(
        [
          PointerButton(at=at(5, 5), btn=Primary, down=true, mods=@input.none),
          PointerButton(at=at(5, 5), btn=Primary, down=false, mods=@input.none),
        ],
        time~,
      ),
    )
  }
  press(1.0)
  assert_true(state.clicked(Primary))
  assert_false(state.double_clicked(Primary))
  press(1.2)
  assert_true(state.double_clicked(Primary))
  press(3.0)
  assert_false(state.double_clicked(Primary))
}

///|
test "the three buttons are counted apart" {
  let state = @input.State::new()
  state.begin(
    frame([
      PointerButton(at=at(5, 5), btn=Secondary, down=true, mods=@input.none),
    ]),
  )
  assert_true(state.is_down(Secondary))
  assert_false(state.is_down(Primary))
  assert_false(state.is_down(Middle))
}

///|
test "the pointer leaving takes every button up with it" {
  let state = @input.State::new()
  state.begin(
    frame([
      PointerMoved(at(5, 5)),
      PointerButton(at=at(5, 5), btn=Primary, down=true, mods=@input.none),
    ]),
  )
  assert_true(state.is_down(Primary))
  state.begin(frame([PointerGone]))
  assert_eq(state.pointer(), None)
  assert_false(state.is_down(Primary))
}

///|
test "typing gathers into one string and is gone by the next frame" {
  let state = @input.State::new()
  state.begin(frame([Text("a"), Text("b")]))
  assert_eq(state.typed(), "ab")
  assert_eq(state.pasted(), None)
  state.begin(frame([Paste("hello")]))
  assert_eq(state.typed(), "")
  assert_eq(state.pasted(), Some("hello"))
}

///|
test "a key and its modifiers arrive together" {
  let state = @input.State::new()
  let shift : @input.Mods = { ctrl: false, alt: false, shift: true, }
  state.begin(
    frame([
      KeyDown(key=Left, mods=shift, repeat=false),
      KeyDown(key=Enter, mods=@input.none, repeat=false),
    ]),
  )
  assert_true(state.key_pressed(Left))
  assert_true(state.key_pressed(Enter))
  assert_false(state.key_pressed(Right))
  assert_eq(state.key_down(Left), Some(shift))
  assert_eq(state.key_down(Enter), Some(@input.none))
  assert_eq(state.key_down(Right), None)
  assert_eq(state.keys().length(), 2)
}

///|
test "a key held into the next frame is not pressed again" {
  let state = @input.State::new()
  state.begin(frame([KeyDown(key=Down, mods=@input.none, repeat=false)]))
  assert_true(state.key_pressed(Down))
  state.begin(frame([]))
  assert_false(state.key_pressed(Down))
  assert_eq(state.key_down(Down), None)
}

///|
test "scrolling in one frame is added up" {
  let state = @input.State::new()
  state.begin(frame([Scroll(at(0, -3)), Scroll(at(0, -4))]))
  assert_eq(state.scroll(), at(0, -7))
  state.begin(frame([]))
  assert_eq(state.scroll(), @emath.zero)
}

///|
test "losing the window's focus is remembered until it comes back" {
  let state = @input.State::new()
  assert_true(state.has_focus())
  state.begin(frame([Focus(false)]))
  assert_false(state.has_focus())
  state.begin(frame([Focus(true)]))
  assert_true(state.has_focus())
}

///|
test "the clock comes from the host, not from counting frames" {
  let state = @input.State::new()
  state.begin(frame([], time=12.5))
  assert_eq(state.time(), 12.5)
  assert_eq(state.dt(), 0.016)
}

///|
test "no modifier at all is no modifier" {
  assert_true(@input.none.is_none())
  let ctrl : @input.Mods = { ctrl: true, alt: false, shift: false, }
  assert_false(ctrl.is_none())
  assert_eq(@input.Btn::Primary.index(), 0)
  assert_eq(@input.Btn::Secondary.index(), 1)
  assert_eq(@input.Btn::Middle.index(), 2)
}
