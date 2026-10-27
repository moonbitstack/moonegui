// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
let one : @id.Id = @id.root("one")

///|
let two : @id.Id = @id.root("two")

///|
test "what a widget remembers comes back under its own id" {
  let memory = @mem.Memory::new()
  memory.set(one, Num(3.5))
  memory.set(two, Flag(true))
  assert_eq(memory.get(one), Some(Num(3.5)))
  assert_eq(memory.get(two), Some(Flag(true)))
  assert_eq(memory.get(@id.root("three")), None)
  assert_eq(memory.count(), 2)
}

///|
test "a widget asking for something it never stored gets its default" {
  let memory = @mem.Memory::new()
  assert_eq(memory.num(one, 7), 7)
  assert_eq(memory.flag(one, true), true)
  assert_eq(memory.point(one, { x: 1, y: 2, }), { x: 1, y: 2, })
  assert_eq(memory.cursor(one, 4), (4, 4))
}

///|
test "a value of the wrong kind is treated as no value at all" {
  let memory = @mem.Memory::new()
  memory.set(one, Flag(true))
  assert_eq(memory.num(one, 9), 9)
  memory.set(one, Cursor(at=2, other=5))
  assert_eq(memory.cursor(one, 0), (2, 5))
  assert_eq(memory.flag(one, false), false)
}

///|
test "a widget that did not appear this frame is forgotten" {
  let memory = @mem.Memory::new()
  memory.set(one, Num(1))
  memory.set(two, Num(2))
  memory.end_frame()
  assert_eq(memory.count(), 2)
  memory.get(one) |> ignore
  memory.end_frame()
  assert_eq(memory.count(), 1)
  assert_eq(memory.get(two), None)
}

///|
test "focus follows the widget, and is dropped when the widget is" {
  let memory = @mem.Memory::new()
  memory.focus_on(one)
  assert_eq(memory.focused(), one)
  memory.get(one) |> ignore
  memory.end_frame()
  assert_eq(memory.focused(), one)
  memory.end_frame()
  assert_true(memory.focused().is_nothing())
}

///|
test "focus is given up when something is clicked that cannot take it" {
  let memory = @mem.Memory::new()
  memory.focus_on(one)
  memory.blur()
  assert_true(memory.focused().is_nothing())
}

///|
test "the widget being dragged and the one pressed on are remembered apart" {
  let memory = @mem.Memory::new()
  memory.press_on(one)
  memory.drag(two)
  assert_eq(memory.pressed_on(), one)
  assert_eq(memory.dragged(), two)
  memory.drag(@id.nothing)
  assert_true(memory.dragged().is_nothing())
  assert_eq(memory.pressed_on(), one)
}

///|
test "a drag survives the frame end, since a drag outlasts a frame" {
  let memory = @mem.Memory::new()
  memory.drag(one)
  memory.press_on(one)
  memory.end_frame()
  assert_eq(memory.dragged(), one)
  assert_eq(memory.pressed_on(), one)
}

///|
test "resetting leaves nothing behind" {
  let memory = @mem.Memory::new()
  memory.set(one, Num(1))
  memory.focus_on(one)
  memory.drag(one)
  memory.reset()
  assert_eq(memory.count(), 0)
  assert_true(memory.focused().is_nothing())
  assert_true(memory.dragged().is_nothing())
}
