// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
let room : @emath.Rect = @emath.Rect::of({ x: 0, y: 0, }, { x: 100, y: 100, })

///|
let gap : @emath.Vec2 = { x: 8, y: 6, }

///|
test "a column places widgets down the left, a gap apart" {
  let placer = @layout.Placer::new(room, layout=@layout.top_down, spacing=gap)
  assert_eq(
    placer.allocate({ x: 30, y: 10, }),
    @emath.Rect::of({ x: 0, y: 0, }, { x: 30, y: 10, }),
  )
  assert_eq(
    placer.allocate({ x: 20, y: 10, }),
    @emath.Rect::of({ x: 0, y: 16, }, { x: 20, y: 26, }),
  )
  assert_eq(placer.used(), @emath.Rect::of({ x: 0, y: 0, }, { x: 30, y: 26, }))
  assert_eq(placer.available(), { x: 100, y: 68, })
  assert_eq(placer.cursor(), { x: 0, y: 32, })
}

///|
test "a row places widgets across the top, a gap apart" {
  let placer = @layout.Placer::new(
    room,
    layout=@layout.left_to_right,
    spacing=gap,
  )
  assert_eq(
    placer.allocate({ x: 30, y: 10, }),
    @emath.Rect::of({ x: 0, y: 0, }, { x: 30, y: 10, }),
  )
  assert_eq(
    placer.allocate({ x: 20, y: 12, }),
    @emath.Rect::of({ x: 38, y: 0, }, { x: 58, y: 12, }),
  )
  assert_eq(placer.available(), { x: 34, y: 100, })
}

///|
test "a row can run the other way, and a column can run upwards" {
  let right = @layout.Placer::new(
    room,
    layout={ dir: RightToLeft, cross: Min, cross_justify: false, },
    spacing=gap,
  )
  assert_eq(
    right.allocate({ x: 30, y: 10, }),
    @emath.Rect::of({ x: 70, y: 0, }, { x: 100, y: 10, }),
  )
  assert_eq(right.available(), { x: 62, y: 100, })
  let up = @layout.Placer::new(
    room,
    layout={ dir: BottomUp, cross: Min, cross_justify: false, },
    spacing=gap,
  )
  assert_eq(
    up.allocate({ x: 30, y: 10, }),
    @emath.Rect::of({ x: 0, y: 90, }, { x: 30, y: 100, }),
  )
  assert_eq(up.available(), { x: 100, y: 84, })
}

///|
test "a justified column stretches every widget to the full width" {
  let placer = @layout.Placer::new(
    room,
    layout=@layout.top_down_justified,
    spacing=gap,
  )
  assert_eq(
    placer.allocate({ x: 30, y: 10, }),
    @emath.Rect::of({ x: 0, y: 0, }, { x: 100, y: 10, }),
  )
}

///|
test "a centred row puts a short widget in the middle of the tall one" {
  let placer = @layout.Placer::new(
    room,
    layout=@layout.centred_row,
    spacing=gap,
  )
  assert_eq(
    placer.allocate({ x: 30, y: 10, }),
    @emath.Rect::of({ x: 0, y: 45, }, { x: 30, y: 55, }),
  )
}

///|
test "a widget larger than the room is given what it asked for" {
  let placer = @layout.Placer::new(room, layout=@layout.top_down, spacing=gap)
  assert_eq(
    placer.allocate({ x: 300, y: 10, }),
    @emath.Rect::of({ x: 0, y: 0, }, { x: 300, y: 10, }),
  )
  assert_eq(placer.used().width(), 300)
}

///|
test "a nested placer starts where its parent has got to" {
  let parent = @layout.Placer::new(room, layout=@layout.top_down, spacing=gap)
  parent.allocate({ x: 10, y: 20, }) |> ignore
  let child = parent.child(@layout.left_to_right)
  assert_eq(child.max(), @emath.Rect::of({ x: 0, y: 26, }, { x: 100, y: 100, }))
  assert_eq(child.spacing(), gap)
  assert_eq(child.layout(), @layout.left_to_right)
  let inside = child.allocate({ x: 12, y: 8, })
  assert_eq(inside, @emath.Rect::of({ x: 0, y: 26, }, { x: 12, y: 34, }))
}

///|
test "a nested placer of a given size takes only that much" {
  let parent = @layout.Placer::new(room, layout=@layout.top_down, spacing=gap)
  let child = parent.child(@layout.top_down, size={ x: 40, y: 30, })
  assert_eq(child.max(), @emath.Rect::of({ x: 0, y: 0, }, { x: 40, y: 30, }))
}

///|
test "a nested row that runs backwards starts at the parent's cursor" {
  let parent = @layout.Placer::new(
    room,
    layout={ dir: RightToLeft, cross: Min, cross_justify: false, },
    spacing=gap,
  )
  let child = parent.child(@layout.top_down, size={ x: 20, y: 10, })
  assert_eq(child.max(), @emath.Rect::of({ x: 80, y: 0, }, { x: 100, y: 10, }))
}

///|
test "a rectangle placed by other means still moves the cursor" {
  let placer = @layout.Placer::new(room, layout=@layout.top_down, spacing=gap)
  placer.advance(@emath.Rect::of({ x: 5, y: 5, }, { x: 50, y: 40, }))
  assert_eq(placer.cursor(), { x: 0, y: 46, })
  assert_eq(placer.used(), @emath.Rect::of({ x: 5, y: 5, }, { x: 50, y: 40, }))
}

///|
test "a direction knows which axis it runs along" {
  assert_true(@layout.Dir::LeftToRight.is_horizontal())
  assert_true(@layout.Dir::RightToLeft.is_horizontal())
  assert_false(@layout.Dir::TopDown.is_horizontal())
  assert_false(@layout.Dir::BottomUp.is_horizontal())
}
