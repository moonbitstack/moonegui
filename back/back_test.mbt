// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
let ink : @paint.Color = @paint.Color::rgb(255, 128, 0)

///|
let font : @paint.FontId = { size: 16, family: Mono, }

///|
test "numbers print as sixty-fourths so four backends agree" {
  assert_eq(@back.number(0), "0")
  assert_eq(@back.number(3), "3")
  assert_eq(@back.number(1.5), "1+32/64")
  assert_eq(@back.number(0.25), "0+16/64")
  assert_eq(@back.number(-0.5), "-1+32/64")
  assert_eq(@back.number(-2), "-2")
}

///|
test "a number between two sixty-fourths goes to the nearer one" {
  assert_eq(@back.number(1.0 / 128.0), "0+1/64")
  assert_eq(@back.number(1.0 / 1000.0), "0")
  assert_eq(@back.number(0.3), "0+19/64")
}

///|
test "the recorder's font is regular enough to measure by hand" {
  let rec = @back.Rec::new()
  assert_eq(rec.measure("abcd", font), { x: 32, y: 20, })
  assert_eq(rec.line_height(font), 20)
  assert_eq(rec.measure("", font), { x: 0, y: 20, })
}

///|
test "a surrogate pair is one character wide, not two" {
  let rec = @back.Rec::new()
  assert_eq(rec.measure("\u{1F600}", font).x, 8)
  assert_eq(rec.measure("a\u{1F600}b", font).x, 24)
}

///|
test "the longest prefix that fits is a code unit index" {
  let rec = @back.Rec::new()
  assert_eq(rec.measure_prefix("abcdef", font, 24), 3)
  assert_eq(rec.measure_prefix("abcdef", font, 0), 0)
  assert_eq(rec.measure_prefix("abcdef", font, 1000), 6)
}

///|
test "a prefix never stops halfway through a surrogate pair" {
  let rec = @back.Rec::new()
  assert_eq(rec.measure_prefix("a\u{1F600}b", font, 16), 3)
  assert_eq(rec.measure_prefix("a\u{1F600}b", font, 8), 1)
}

///|
test "a shape inside its clip is drawn without one" {
  let rec = @back.Rec::new()
  @back.play(
    [
      {
        clip: @paint.unclipped,
        shape: Rect(
          rect=@emath.Rect::of({ x: 0, y: 0, }, { x: 10, y: 4, }),
          corner=@paint.square,
          fill=ink,
          stroke=@paint.no_stroke,
        ),
      },
    ],
    rec,
  )
  inspect(rec.text(), content="fill_rect (0,0)-(10,4) #ff8000")
}

///|
test "a shape across its clip is drawn between a push and a pop" {
  let rec = @back.Rec::new()
  @back.play(
    [
      {
        clip: @emath.Rect::of({ x: 0, y: 0, }, { x: 5, y: 5, }),
        shape: Circle(
          centre={ x: 4, y: 4, },
          radius=3,
          fill=@paint.clear,
          stroke=@paint.Stroke::new(2, ink),
        ),
      },
    ],
    rec,
  )
  inspect(
    rec.text(),
    content=(
      #|clip (0,0)-(5,5)
      #|stroke_circle (4,4) r=3 #ff8000 w=2
      #|unclip
    ),
  )
}

///|
test "a filled and stroked shape reaches the backend as two commands" {
  let rec = @back.Rec::new()
  @back.play(
    [
      {
        clip: @paint.unclipped,
        shape: Rect(
          rect=@emath.Rect::of({ x: 0, y: 0, }, { x: 8, y: 8, }),
          corner=@paint.Corner::same(2),
          fill=ink,
          stroke=@paint.Stroke::new(1, @paint.Color::grey(0)),
        ),
      },
    ],
    rec,
  )
  inspect(
    rec.text(),
    content=(
      #|fill_rect (0,0)-(8,8) round=2,2,2,2 #ff8000
      #|stroke_rect (0,0)-(8,8) round=2,2,2,2 #000000 w=1
    ),
  )
}

///|
test "each row of laid out text is drawn where the row says" {
  let rec = @back.Rec::new()
  let galley : @paint.Galley = {
    rows: [
      { text: "one", at: @emath.zero, },
      { text: "two", at: { x: 2, y: 20, }, },
    ],
    size: { x: 24, y: 40, },
    font,
  }
  @back.play(
    [
      {
        clip: @paint.unclipped,
        shape: Text(at={ x: 10, y: 5, }, galley~, color=ink),
      },
    ],
    rec,
  )
  inspect(
    rec.text(),
    content=(
      #|text (10,5) mono/16 #ff8000 "one"
      #|text (12,25) mono/16 #ff8000 "two"
    ),
  )
}

///|
test "an image is outlined until a backend can load one" {
  let rec = @back.Rec::new()
  @back.play(
    [
      {
        clip: @paint.unclipped,
        shape: Image(
          rect=@emath.Rect::of({ x: 0, y: 0, }, { x: 4, y: 4, }),
          name="logo",
          tint=ink,
        ),
      },
    ],
    rec,
  )
  inspect(rec.text(), content="stroke_rect (0,0)-(4,4) #ff8000 w=1")
}

///|
test "the recorder forgets one frame before the next" {
  let rec = @back.Rec::new()
  @back.play(
    [
      {
        clip: @paint.unclipped,
        shape: Circle(
          centre=@emath.zero,
          radius=1,
          fill=ink,
          stroke=@paint.no_stroke,
        ),
      },
    ],
    rec,
  )
  assert_eq(rec.lines().length(), 1)
  rec.clear()
  assert_eq(rec.text(), "")
}
