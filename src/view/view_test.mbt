// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
let screen : @emath.Rect = @emath.Rect::of({ x: 0, y: 0, }, { x: 200, y: 120, })

///|
/// An interpreter, a recorder and a clock, which is all a frame needs.
struct Stage {
  ctx : @ctx.Ctx
  rec : @back.Rec
  interp : @view.Interp
  mut time : Double
}

///|
fn stage() -> Stage {
  let rec = @back.Rec::new()
  { ctx: @ctx.Ctx::new(rec), rec, interp: @view.Interp::new(), time: 0, }
}

///|
fn Stage::draw(
  self : Stage,
  events : Array[@input.Event],
  views : Array[@view.View],
) -> String {
  let interp = self.interp
  let out = self.ctx.run(
    { screen, events, time: self.time, dt: 0.016, focused: true, },
    fn(ui) { interp.show(ui, views) },
  )
  self.time = self.time + 1
  self.rec.clear()
  @back.play(out.shapes, self.rec)
  self.rec.text()
}

///|
/// Draw a frame and hand back the commands one by one.
fn Stage::lines(
  self : Stage,
  events : Array[@input.Event],
  views : Array[@view.View],
) -> Array[String] {
  self.draw(events, views) |> ignore
  self.rec.lines()
}

///|
fn at(x : Double, y : Double) -> @emath.Vec2 {
  { x, y, }
}

///|
fn tap(x : Double, y : Double) -> Array[@input.Event] {
  [
    PointerMoved(at(x, y)),
    PointerButton(at=at(x, y), btn=Primary, down=true, mods=@input.none),
    PointerButton(at=at(x, y), btn=Primary, down=false, mods=@input.none),
  ]
}

///|
fn hover(x : Double, y : Double) -> Array[@input.Event] {
  [PointerMoved(at(x, y))]
}

///|
test "a column of two buttons draws each under the one before" {
  let s = stage()
  let views = [
    @view.button("One", @view.Tag::new(1)),
    @view.button("Two", @view.Tag::new(2)),
  ]
  inspect(
    s.draw([], views),
    content=(
      #|fill_rect (0,0)-(37,25+32/64) round=4,4,4,4 #28282e
      #|stroke_rect (0,0)-(37,25+32/64) round=4,4,4,4 #46464e w=1
      #|text (8,4) sans/14 #dedede "One"
      #|fill_rect (0,31+32/64)-(37,57) round=4,4,4,4 #28282e
      #|stroke_rect (0,31+32/64)-(37,57) round=4,4,4,4 #46464e w=1
      #|text (8,35+32/64) sans/14 #dedede "Two"
    ),
  )
}
