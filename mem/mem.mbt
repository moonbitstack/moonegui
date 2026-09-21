// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What a widget can remember between frames.
///
/// A closed set rather than anything at all: MoonBit has no downcasting, and a
/// closed set can be printed, compared and put in a snapshot, which is worth
/// more here than letting a widget store an arbitrary value.
pub(all) enum State {
  Num(Double)
  Flag(Bool)
  Point(@emath.Vec2)
  /// A text field's cursor and the other end of its selection, as code unit
  /// indices. The text itself belongs to the caller.
  Cursor(at~ : Int, other~ : Int)
} derive(Eq, Debug)

///|
/// Everything that survives a frame.
pub struct Memory {
  data : Map[@id.Id, State]
  used : Map[@id.Id, Bool]
  mut focus : @id.Id
  mut dragged : @id.Id
  mut pressed_on : @id.Id
}

///|
/// Memory with nothing in it.
pub fn Memory::new() -> Memory {
  {
    data: Map([]),
    used: Map([]),
    focus: @id.nothing,
    dragged: @id.nothing,
    pressed_on: @id.nothing,
  }
}

///|
/// What this widget remembered, if anything. Asking counts as using it, which
/// is what keeps it from being cleaned up at the end of the frame.
pub fn Memory::get(self : Memory, id : @id.Id) -> State? {
  self.used[id] = true
  self.data.get(id)
}

///|
/// Remember something for this widget.
pub fn Memory::set(self : Memory, id : @id.Id, state : State) -> Unit {
  self.used[id] = true
  self.data[id] = state
}

///|
/// A remembered number, or the default when there is none.
pub fn Memory::num(self : Memory, id : @id.Id, default : Double) -> Double {
  match self.get(id) {
    Some(Num(value)) => value
    _ => default
  }
}

///|
/// A remembered flag, or the default.
pub fn Memory::flag(self : Memory, id : @id.Id, default : Bool) -> Bool {
  match self.get(id) {
    Some(Flag(value)) => value
    _ => default
  }
}

///|
/// A remembered point, or the default.
pub fn Memory::point(
  self : Memory,
  id : @id.Id,
  default : @emath.Vec2,
) -> @emath.Vec2 {
  match self.get(id) {
    Some(Point(value)) => value
    _ => default
  }
}

///|
/// A remembered cursor, or the default.
pub fn Memory::cursor(self : Memory, id : @id.Id, default : Int) -> (Int, Int) {
  match self.get(id) {
    Some(Cursor(at~, other~)) => (at, other)
    _ => (default, default)
  }
}

///|
/// Say that this widget was here this frame although it remembers nothing.
///
/// Focus belongs to widgets that store no state at all — a button is the usual
/// one — and without this the end of the frame would find nothing under that id
/// and take its focus away again.
pub fn Memory::keep(self : Memory, id : @id.Id) -> Unit {
  self.used[id] = true
}

///|
/// Which widget has keyboard focus.
pub fn Memory::focused(self : Memory) -> @id.Id {
  self.focus
}

///|
/// Give a widget keyboard focus.
pub fn Memory::focus_on(self : Memory, id : @id.Id) -> Unit {
  self.focus = id
  self.used[id] = true
}

///|
/// Take focus away from whatever has it.
pub fn Memory::blur(self : Memory) -> Unit {
  self.focus = @id.nothing
}

///|
/// Which widget is being dragged.
pub fn Memory::dragged(self : Memory) -> @id.Id {
  self.dragged
}

///|
/// Record that a widget is being dragged.
pub fn Memory::drag(self : Memory, id : @id.Id) -> Unit {
  self.dragged = id
  if !id.is_nothing() {
    self.used[id] = true
  }
}

///|
/// Which widget the pointer went down on, which is what decides whether a
/// release counts as a click on it.
pub fn Memory::pressed_on(self : Memory) -> @id.Id {
  self.pressed_on
}

///|
/// Record where a press landed.
pub fn Memory::press_on(self : Memory, id : @id.Id) -> Unit {
  self.pressed_on = id
  if !id.is_nothing() {
    self.used[id] = true
  }
}

///|
/// Forget every widget that did not appear this frame.
///
/// A widget that is gone is gone: leaving its state behind would mean a list
/// whose rows come and go slowly fills memory with cursors and scroll offsets
/// nothing will ever read again.
pub fn Memory::end_frame(self : Memory) -> Unit {
  let stale : Array[@id.Id] = []
  for id, _ in self.data {
    if !self.used.contains(id) {
      stale.push(id)
    }
  }
  for id in stale {
    self.data.remove(id)
  }
  if !self.focus.is_nothing() && !self.used.contains(self.focus) {
    self.focus = @id.nothing
  }
  self.used.clear()
}

///|
/// How many widgets are remembering something.
pub fn Memory::count(self : Memory) -> Int {
  self.data.length()
}

///|
/// Forget everything, which is what a host does when it tears the interface
/// down and builds a different one.
pub fn Memory::reset(self : Memory) -> Unit {
  self.data.clear()
  self.used.clear()
  self.focus = @id.nothing
  self.dragged = @id.nothing
  self.pressed_on = @id.nothing
}

///|
pub extend State with Debug::{to_repr}

///|
pub extend State with Eq::{not_equal, equal}
