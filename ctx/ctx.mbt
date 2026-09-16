// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What one frame produced.
pub(all) struct Output {
  shapes : Array[@paint.Clipped]
  /// True when something is still moving and the host should come back rather
  /// than waiting for the next input.
  repaint : Bool
} derive(Eq, Debug)

///|
/// What survives between frames.
///
/// The list of rectangles from the previous frame is the important part: this
/// frame's widgets do not exist yet when the pointer has to be matched to one,
/// so the match is made against where they were last time. That is where the
/// one-frame delay of immediate mode comes from, and it is why a widget that
/// moves under a stationary pointer is hovered one frame late.
pub struct Ctx {
  back : &@back.Backend
  memory : @mem.Memory
  input : @input.State
  painter : @paint.Painter
  mut style : Style
  mut previous : @hit.Rects
  mut current : @hit.Rects
  mut over : @id.Id
  mut focus_ring : Array[@id.Id]
  mut repaint : Bool
  mut frame : Int
}

///|
/// A context that draws through this backend.
pub fn Ctx::new(back : &@back.Backend, style? : Style = dark) -> Ctx {
  {
    back,
    memory: @mem.Memory::new(),
    input: @input.State::new(),
    painter: @paint.Painter::new(),
    style,
    previous: @hit.Rects::new(),
    current: @hit.Rects::new(),
    over: @id.nothing,
    focus_ring: [],
    repaint: false,
    frame: 0,
  }
}

///|
/// Start a frame and hand back the root of the interface.
pub fn Ctx::begin(self : Ctx, raw : @input.Raw) -> Ui {
  self.input.begin(raw)
  self.painter.clear()
  self.current.clear()
  self.focus_ring = []
  self.repaint = false
  self.frame = self.frame + 1
  // What the pointer is over is decided once, against the frame before, so that
  // every widget this frame gets a consistent answer.
  self.over = match self.input.pointer() {
    Some(at) =>
      match self.previous.at(at) {
        Some(widget) => widget.id
        None => @id.nothing
      }
    None => @id.nothing
  }
  if self.input.pressed(Primary) {
    self.memory.press_on(self.over)
    // A press on nothing takes focus away from whatever had it, the way
    // clicking the background of a window does.
    if self.over.is_nothing() {
      self.memory.blur()
    }
  }
  if self.input.is_down(Primary) {
    let pressed_on = self.memory.pressed_on()
    if !pressed_on.is_nothing() && self.memory.dragged().is_nothing() {
      match self.previous.find(pressed_on) {
        Some(widget) =>
          if widget.sense.drag &&
            (
              self.input.pointer_delta().length() > 0 ||
              self.input.is_down(Primary)
            ) {
            self.memory.drag(pressed_on)
          }
        None => ()
      }
    }
  } else {
    self.memory.drag(@id.nothing)
  }
  Ui::root(self, raw.screen)
}

///|
/// Finish a frame.
pub fn Ctx::end(self : Ctx) -> Output {
  self.move_focus()
  if !self.input.is_down(Primary) {
    self.memory.press_on(@id.nothing)
  }
  self.memory.end_frame()
  let previous = self.previous
  self.previous = self.current
  self.current = previous
  { shapes: copy_shapes(self.painter.shapes()), repaint: self.repaint, }
}

///|
/// Run one frame: hand the body a `Ui`, take back what it drew.
pub fn Ctx::run(self : Ctx, raw : @input.Raw, body : (Ui) -> Unit) -> Output {
  let ui = self.begin(raw)
  body(ui)
  self.end()
}

///|
/// The style the widgets are drawing with.
pub fn Ctx::style(self : Ctx) -> Style {
  self.style
}

///|
/// Draw with a different style from now on.
pub fn Ctx::set_style(self : Ctx, style : Style) -> Unit {
  self.style = style
}

///|
/// What the widgets remember.
pub fn Ctx::memory(self : Ctx) -> @mem.Memory {
  self.memory
}

///|
/// The input as the widgets see it.
pub fn Ctx::input(self : Ctx) -> @input.State {
  self.input
}

///|
/// The backend, for the measuring a widget cannot do itself.
pub fn Ctx::backend(self : Ctx) -> &@back.Backend {
  self.back
}

///|
/// Ask the host to come back for another frame even if nothing happens.
pub fn Ctx::request_repaint(self : Ctx) -> Unit {
  self.repaint = true
}

///|
/// Which widget the pointer is over, from the frame before.
pub fn Ctx::hovered(self : Ctx) -> @id.Id {
  self.over
}

///|
/// Which widget has keyboard focus.
pub fn Ctx::focused(self : Ctx) -> @id.Id {
  self.memory.focused()
}

///|
/// How many frames have run.
pub fn Ctx::frame(self : Ctx) -> Int {
  self.frame
}

///|
/// Register a widget and work out what happened to it.
pub fn Ctx::interact(
  self : Ctx,
  id : @id.Id,
  rect : @emath.Rect,
  sense : @hit.Sense,
  enabled? : Bool = true,
) -> @hit.Response {
  let widget : @hit.WidgetRect = { id, rect, sense, enabled, layer: 0, }
  self.current.add(widget)
  if sense.focus && enabled {
    self.focus_ring.push(id)
    self.memory.keep(id)
  }
  let response = @hit.interact(
    widget,
    self.over,
    self.memory.pressed_on(),
    self.memory.dragged(),
    self.memory.focused(),
    self.input,
  )
  if response.clicked && sense.focus {
    self.memory.focus_on(id)
  }
  response
}

///|
/// Move focus when Tab was pressed.
///
/// The ring is the widgets that asked for focus, in the order they were built,
/// so the keyboard walks the interface the way it reads.
fn Ctx::move_focus(self : Ctx) -> Unit {
  if !self.input.key_pressed(Tab) || self.focus_ring.length() == 0 {
    return
  }
  let back = shift_held(self.input)
  let ring = self.focus_ring
  let focus = self.memory.focused()
  let mut at = -1
  for i in 0..<ring.length() {
    if ring[i] == focus {
      at = i
    }
  }
  let count = ring.length()
  let next = if at < 0 {
    if back {
      count - 1
    } else {
      0
    }
  } else if back {
    (at - 1 + count) % count
  } else {
    (at + 1) % count
  }
  self.memory.focus_on(ring[next])
}

///|
fn shift_held(state : @input.State) -> Bool {
  match state.key_down(Tab) {
    Some(mods) => mods.shift
    None => false
  }
}

///|
/// A frame's shapes, copied out so that the next frame's painter cannot change
/// what the host is still holding.
fn copy_shapes(shapes : Array[@paint.Clipped]) -> Array[@paint.Clipped] {
  let out : Array[@paint.Clipped] = []
  for shape in shapes {
    out.push(shape)
  }
  out
}
