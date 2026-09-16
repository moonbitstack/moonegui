// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "vectors add, subtract and negate" {
  let a : @emath.Vec2 = { x: 3, y: 4, }
  let b : @emath.Vec2 = { x: 1, y: 2, }
  assert_eq(a + b, { x: 4, y: 6, })
  assert_eq(a - b, { x: 2, y: 2, })
  assert_eq(-a, { x: -3, y: -4, })
  assert_eq(a.length(), 5)
  assert_eq(@emath.Vec2::splat(2), { x: 2, y: 2, })
}

///|
test "a rectangle knows its own measurements" {
  let rect = @emath.Rect::of({ x: 10, y: 20, }, { x: 30, y: 50, })
  assert_eq(rect.width(), 20)
  assert_eq(rect.height(), 30)
  assert_eq(rect.size(), { x: 20, y: 30, })
  assert_eq(rect.centre(), { x: 20, y: 35, })
  assert_false(rect.is_empty())
  assert_true(@emath.nothing.is_empty())
}

///|
test "a rectangle is built from a corner or from its centre" {
  assert_eq(
    @emath.Rect::at({ x: 1, y: 2, }, { x: 4, y: 6, }),
    @emath.Rect::of({ x: 1, y: 2, }, { x: 5, y: 8, }),
  )
  assert_eq(
    @emath.Rect::around({ x: 0, y: 0, }, { x: 4, y: 2, }),
    @emath.Rect::of({ x: -2, y: -1, }, { x: 2, y: 1, }),
  )
}

///|
test "the corners belong to a rectangle and the far edges do not" {
  let rect = @emath.Rect::of({ x: 0, y: 0, }, { x: 10, y: 10, })
  assert_true(rect.contains({ x: 0, y: 0, }))
  assert_true(rect.contains({ x: 5, y: 5, }))
  assert_false(rect.contains({ x: 10, y: 5, }))
  assert_false(rect.contains({ x: 5, y: 10, }))
  assert_false(rect.contains({ x: -1, y: 5, }))
}

///|
test "two rectangles that miss each other intersect in nothing" {
  let a = @emath.Rect::of({ x: 0, y: 0, }, { x: 10, y: 10, })
  let b = @emath.Rect::of({ x: 5, y: 5, }, { x: 20, y: 20, })
  assert_eq(a.intersect(b), @emath.Rect::of({ x: 5, y: 5, }, { x: 10, y: 10, }))
  let apart = @emath.Rect::of({ x: 40, y: 40, }, { x: 50, y: 50, })
  assert_true(a.intersect(apart).is_empty())
  assert_eq(a.union(b), @emath.Rect::of({ x: 0, y: 0, }, { x: 20, y: 20, }))
}

///|
test "growing and shrinking are opposites, and translating moves both corners" {
  let rect = @emath.Rect::of({ x: 10, y: 10, }, { x: 20, y: 20, })
  assert_eq(rect.grow(2).shrink(2), rect)
  assert_eq(
    rect.translate({ x: 5, y: -5, }),
    @emath.Rect::of({ x: 15, y: 5, }, { x: 25, y: 15, }),
  )
}

///|
test "shrinking past the middle leaves an empty rectangle, not an inside out one" {
  let rect = @emath.Rect::of({ x: 0, y: 0, }, { x: 4, y: 4, })
  assert_true(rect.shrink(10).is_empty())
}

///|
test "a point outside a rectangle is clamped to its edge" {
  let rect = @emath.Rect::of({ x: 0, y: 0, }, { x: 10, y: 10, })
  assert_eq(rect.clamp({ x: -5, y: 5, }), { x: 0, y: 5, })
  assert_eq(rect.clamp({ x: 50, y: 50, }), { x: 10, y: 10, })
  assert_eq(rect.clamp({ x: 3, y: 4, }), { x: 3, y: 4, })
}

///|
test "alignment places a small thing inside a large one" {
  assert_eq(@emath.Align::Min.offset(100, 20), 0)
  assert_eq(@emath.Align::Center.offset(100, 20), 40)
  assert_eq(@emath.Align::Max.offset(100, 20), 80)
}

///|
/// Something too big for its space overflows symmetrically rather than being
/// pushed back inside: a centred thing stays centred on the same point whatever
/// its size, which is what keeps a row of widgets from jumping about when one
/// of them grows.
test "something larger than the space it is aligned in overflows both sides" {
  assert_eq(@emath.Align::Center.offset(10, 40), -15)
  assert_eq(@emath.Align::Max.offset(10, 40), -30)
  assert_eq(@emath.Align::Min.offset(10, 40), 0)
}

///|
test "a margin shrinks a rectangle by a different amount on each side" {
  let margin : @emath.Margin = { top: 1, right: 2, bottom: 3, left: 4, }
  let rect = @emath.Rect::of({ x: 0, y: 0, }, { x: 20, y: 20, })
  assert_eq(margin.sum(), { x: 6, y: 4, })
  assert_eq(
    margin.shrink_rect(rect),
    @emath.Rect::of({ x: 4, y: 1, }, { x: 18, y: 17, }),
  )
  assert_eq(margin.grow_rect(margin.shrink_rect(rect)), rect)
  assert_eq(@emath.Margin::same(3).sum(), { x: 6, y: 6, })
}

///|
test "interpolation and its inverse agree" {
  assert_eq(@emath.lerp(10, 20, 0.5), 15)
  assert_eq(@emath.inverse_lerp(15, 10, 20), 0.5)
  assert_eq(@emath.clamp(5, 0, 1), 1)
  assert_eq(@emath.clamp(-5, 0, 1), 0)
}

///|
test "an empty range has no inside, and a backwards clamp gives the low end" {
  assert_eq(@emath.inverse_lerp(15, 10, 10), 0)
  assert_eq(@emath.inverse_lerp(5, 10, 20), 0)
  assert_eq(@emath.inverse_lerp(50, 10, 20), 1)
  assert_eq(@emath.clamp(5, 10, 0), 10)
}
