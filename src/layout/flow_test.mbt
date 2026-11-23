// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
let apart : @emath.Vec2 = { x: 8, y: 6, }

///|
test "a flow with no gap of its own takes the spacing across its direction" {
  assert_eq(@layout.row_flow.gap_of(apart), 8)
  assert_eq(@layout.column_flow.gap_of(apart), 6)
  assert_eq(@layout.row_flow.with_gap(2).gap_of(apart), 2)
}

///|
test "a flow can be given a padding, an alignment, a justification and a stretch" {
  let flow = @layout.column_flow
    .with_padding(4)
    .with_cross(@emath.Center)
    .with_justify(@layout.End)
    .with_stretch(true)
  assert_eq(flow.padding, 4)
  assert_eq(flow.cross, @emath.Center)
  assert_eq(flow.justify, @layout.End)
  assert_eq(flow.stretch, true)
  // The direction is still the one it had.
  assert_eq(flow.dir, @layout.TopDown)
}

///|
test "a child is measured against what is left of the line" {
  let room : @emath.Vec2 = { x: 100, y: 40, }
  assert_eq(@layout.child_room(room, true, 0), room)
  assert_eq(@layout.child_room(room, true, 30), { x: 70, y: 40, })
  // A line with nothing left leaves nothing, rather than a negative width.
  assert_eq(@layout.child_room(room, true, 130).x, 0)
  // Down a column it is the height that shrinks.
  assert_eq(@layout.child_room(room, false, 10), { x: 100, y: 30, })
}

///|
test "bounds hold a size between the least and the most" {
  let bounds = @layout.Bounds::new(min={ x: 20, y: 10, }, max={ x: 80, y: 60, })
  assert_eq(bounds.hold({ x: 5, y: 5, }), { x: 20, y: 10, })
  assert_eq(bounds.hold({ x: 50, y: 30, }), { x: 50, y: 30, })
  assert_eq(bounds.hold({ x: 200, y: 200, }), { x: 80, y: 60, })
  assert_eq(
    @layout.Bounds::at_least({ x: 30, y: 30, }).hold({ x: 1, y: 1, }).x,
    30,
  )
  assert_eq(
    @layout.Bounds::at_most({ x: 30, y: 30, }).hold({ x: 99, y: 99, }).x,
    30,
  )
  assert_eq(@layout.unbounded.hold({ x: 1.0e9, y: 1.0e9, }).x, 1.0e9)
}
