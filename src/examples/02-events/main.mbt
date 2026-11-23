// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What the program holds between frames.
struct Form {
  mut name : String
  mut ticked : Bool
}

///|
let form : Form = { name: "", ticked: false, }

///|
fn views(state : Form) -> Array[@view.View] {
  [
    @view.edit(state.name, @view.Tag::new(1), hint="your name"),
    @view.checkbox("Remember me", @view.Tag::new(2), state.ticked),
    @view.button("Save", @view.Tag::new(3)),
  ]
}

///|
/// The one place the state changes.
fn apply(event : @view.Event) -> Unit {
  match event {
    Edited(text~, ..) => form.name = text
    Toggled(value~, ..) => form.ticked = value
    Clicked(_) => println("saved " + form.name)
    _ => ()
  }
}

///|
/// A press and a release in the same place, which is a click.
fn tap(x : Double, y : Double) -> Array[@input.Event] {
  let at : @emath.Vec2 = { x, y, }
  [
    PointerMoved(at),
    PointerButton(at~, btn=Primary, down=true, mods=@input.none),
    PointerButton(at~, btn=Primary, down=false, mods=@input.none),
  ]
}

///|
fn main {
  let screen = @emath.Rect::of({ x: 0, y: 0, }, { x: 320, y: 200, })
  let rec = @back.Rec::new()
  let ctx = @ctx.Ctx::new(rec)
  let interp = @view.Interp::new()
  let mut time = 0.0
  let frame = fn(events : Array[@input.Event]) {
    ctx.run({ screen, events, time, dt: 0.016, focused: true, }, fn(ui) {
      interp.show(ui, views(form))
    })
    |> ignore
    time = time + 1
    for event in interp.events() {
      apply(event)
    }
  }
  // The first frame only says where things are: a click is matched against the
  // rectangles of the frame before.
  frame([])
  frame(tap(20, 10))
  frame([@input.Text("ada")])
  frame(tap(20, 50))
  frame(tap(20, 75))
  println(form.name + " " + form.ticked.to_string())
}
