// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
let dot : @paint.Color = @paint.Color::rgb(10, 20, 30)

///|
test "a colour component outside the range is brought into it" {
  assert_eq(@paint.Color::rgb(-5, 300, 30), { r: 0, g: 255, b: 30, a: 255, })
  assert_eq(@paint.Color::rgba(0, 0, 0, 400).a, 255)
  assert_eq(@paint.Color::grey(7), { r: 7, g: 7, b: 7, a: 255, })
}

///|
test "a colour with no alpha draws nothing" {
  assert_true(@paint.clear.is_clear())
  assert_false(dot.is_clear())
  assert_true(dot.with_alpha(0).is_clear())
  assert_eq(dot.with_alpha(128).a, 128)
}

///|
test "mixing runs from one colour to the other and stops at the ends" {
  let black = @paint.Color::grey(0)
  let white = @paint.Color::grey(100)
  assert_eq(black.lerp(white, 0), black)
  assert_eq(black.lerp(white, 1), white)
  assert_eq(black.lerp(white, 0.5).r, 50)
  assert_eq(black.lerp(white, 5), white)
  assert_eq(black.lerp(white, -5), black)
}

///|
test "a stroke with no width or no colour is no stroke at all" {
  assert_true(@paint.no_stroke.is_empty())
  assert_true(@paint.Stroke::new(0, dot).is_empty())
  assert_true(@paint.Stroke::new(2, @paint.clear).is_empty())
  assert_false(@paint.Stroke::new(1, dot).is_empty())
}

///|
test "a shape's bounds take in half of its stroke" {
  let rect = @emath.Rect::of({ x: 10, y: 10, }, { x: 20, y: 20, })
  let shape : @paint.Shape = Rect(
    rect~,
    corner=@paint.square,
    fill=dot,
    stroke=@paint.Stroke::new(4, dot),
  )
  assert_eq(shape.bounds(), rect.grow(2))
}

///|
test "a circle's bounds are the square around it" {
  let shape : @paint.Shape = Circle(
    centre={ x: 10, y: 10, },
    radius=5,
    fill=dot,
    stroke=@paint.no_stroke,
  )
  assert_eq(shape.bounds(), @emath.Rect::of({ x: 5, y: 5, }, { x: 15, y: 15, }))
}

///|
test "a path's bounds hold every point, and an empty path holds nothing" {
  let shape : @paint.Shape = Path(
    points=[{ x: 0, y: 5, }, { x: 10, y: -5, }, { x: 4, y: 2, }],
    closed=false,
    fill=@paint.clear,
    stroke=@paint.no_stroke,
  )
  assert_eq(shape.bounds(), @emath.Rect::of({ x: 0, y: -5, }, { x: 10, y: 5, }))
  let empty : @paint.Shape = Path(
    points=[],
    closed=false,
    fill=@paint.clear,
    stroke=@paint.no_stroke,
  )
  assert_true(empty.bounds().is_empty())
}

///|
test "laid out text is bounded by the size it was laid out to" {
  let galley : @paint.Galley = {
    rows: [{ text: "hi", at: @emath.zero, }],
    size: { x: 14, y: 17, },
    font: @paint.body,
  }
  let shape : @paint.Shape = Text(at={ x: 3, y: 4, }, galley~, color=dot)
  assert_eq(shape.bounds(), @emath.Rect::of({ x: 3, y: 4, }, { x: 17, y: 21, }))
}

///|
test "a shape entirely inside its clip carries no clip at all" {
  let painter = @paint.Painter::new(
    clip=@emath.Rect::of({ x: 0, y: 0, }, { x: 100, y: 100, }),
  )
  painter.rect(@emath.Rect::of({ x: 10, y: 10, }, { x: 20, y: 20, }), fill=dot)
  assert_eq(painter.count(), 1)
  assert_eq(painter.shapes()[0].clip, @paint.unclipped)
}

///|
test "a shape that cannot be seen is never collected" {
  let painter = @paint.Painter::new(
    clip=@emath.Rect::of({ x: 0, y: 0, }, { x: 100, y: 100, }),
  )
  painter.rect(
    @emath.Rect::of({ x: 200, y: 200, }, { x: 300, y: 300, }),
    fill=dot,
  )
  assert_eq(painter.count(), 0)
}

///|
test "a shape across the edge of its clip carries the clip" {
  let clip = @emath.Rect::of({ x: 0, y: 0, }, { x: 100, y: 100, })
  let painter = @paint.Painter::new(clip~)
  painter.rect(
    @emath.Rect::of({ x: 50, y: 50, }, { x: 150, y: 150, }),
    fill=dot,
  )
  assert_eq(painter.count(), 1)
  assert_eq(painter.shapes()[0].clip, clip)
}

///|
test "a nested painter draws into the same list, clipped smaller" {
  let painter = @paint.Painter::new(
    clip=@emath.Rect::of({ x: 0, y: 0, }, { x: 100, y: 100, }),
  )
  let inside = painter.sub(@emath.Rect::of({ x: 0, y: 0, }, { x: 50, y: 50, }))
  assert_eq(inside.clip(), @emath.Rect::of({ x: 0, y: 0, }, { x: 50, y: 50, }))
  inside.rect(@emath.Rect::of({ x: 60, y: 10, }, { x: 70, y: 20, }), fill=dot)
  assert_eq(painter.count(), 0)
  inside.rect(@emath.Rect::of({ x: 10, y: 10, }, { x: 20, y: 20, }), fill=dot)
  assert_eq(painter.count(), 1)
}

///|
test "a nested painter cannot widen the clip it was made from" {
  let painter = @paint.Painter::new(
    clip=@emath.Rect::of({ x: 0, y: 0, }, { x: 50, y: 50, }),
  )
  let wider = painter.sub(@emath.Rect::of({ x: 0, y: 0, }, { x: 500, y: 500, }))
  assert_eq(wider.clip(), @emath.Rect::of({ x: 0, y: 0, }, { x: 50, y: 50, }))
}

///|
test "the painter collects every kind of shape and forgets them on clear" {
  let painter = @paint.Painter::new()
  let stroke = @paint.Stroke::new(1, dot)
  painter.rect(@emath.Rect::of({ x: 0, y: 0, }, { x: 1, y: 1, }), fill=dot)
  painter.circle({ x: 0, y: 0, }, 2, fill=dot)
  painter.line({ x: 0, y: 0, }, { x: 5, y: 5, }, stroke)
  painter.path([{ x: 0, y: 0, }, { x: 1, y: 1, }], closed=true, fill=dot)
  painter.galley(
    @emath.zero,
    { rows: [], size: { x: 1, y: 1, }, font: @paint.body, },
    dot,
  )
  assert_eq(painter.count(), 5)
  painter.clear()
  assert_eq(painter.count(), 0)
}
