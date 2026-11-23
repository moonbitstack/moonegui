// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// One frame of a small interface, written down instead of drawn.
fn main {
  let screen = @emath.Rect::of({ x: 0, y: 0, }, { x: 320, y: 200, })
  let rec = @back.Rec::new()
  let ctx = @ctx.Ctx::new(rec)
  let interp = @view.Interp::new()
  let views : Array[@view.View] = [
    @view.heading("Headless"),
    @view.text("No window, no canvas, no font file."),
    @view.separator(),
    @view.row([
      @view.button("Save", @view.Tag::new(1)),
      @view.button("Cancel", @view.Tag::new(2)),
    ]),
    @view.progress(0.5, width=200, label="half way"),
  ]
  let out = ctx.run(@input.Raw::new(screen), fn(ui) { interp.show(ui, views) })
  @back.play(out.shapes, rec)
  println(rec.text())
}
