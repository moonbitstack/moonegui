// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// The modifier keys held down.
pub(all) struct Mods {
  ctrl : Bool
  alt : Bool
  shift : Bool
} derive(Eq, Debug)

///|
/// Nothing held.
pub let none : Mods = { ctrl: false, alt: false, shift: false, }

///|
/// True when no modifier is held.
pub fn Mods::is_none(self : Mods) -> Bool {
  self == none
}

///|
/// A pointer button. A GUI needs three; a mouse with more is telling the host
/// something the library has no use for.
pub(all) enum Btn {
  Primary
  Secondary
  Middle
} derive(Eq, Debug)

///|
/// Which button, as a number, for the arrays that track them.
pub fn Btn::index(self : Btn) -> Int {
  match self {
    Primary => 0
    Secondary => 1
    Middle => 2
  }
}

///|
/// A key that does something other than produce a character. Characters arrive
/// as `Text`, because what a key produces depends on the keyboard layout and
/// the host is the one that knows it.
pub(all) enum Key {
  Enter
  Tab
  Backspace
  Delete
  Escape
  Space
  Left
  Right
  Up
  Down
  Home
  End
  PageUp
  PageDown
} derive(Eq, Debug)

///|
/// Something that happened since the last frame.
pub(all) enum Event {
  PointerMoved(@emath.Vec2)
  PointerButton(at~ : @emath.Vec2, btn~ : Btn, down~ : Bool, mods~ : Mods)
  /// The pointer left the surface: a widget under it is no longer hovered, and
  /// a drag that was in progress has to be ended rather than left hanging.
  PointerGone
  Scroll(@emath.Vec2)
  KeyDown(key~ : Key, mods~ : Mods, repeat~ : Bool)
  KeyUp(key~ : Key, mods~ : Mods)
  Text(String)
  Paste(String)
  Focus(Bool)
} derive(Eq, Debug)

///|
/// What the host hands over at the start of a frame.
pub(all) struct Raw {
  screen : @emath.Rect
  events : Array[Event]
  /// Seconds since the program started.
  time : Double
  /// Seconds since the last frame.
  dt : Double
  focused : Bool
}

///|
/// A frame's worth of input, with a screen of this size and nothing happening.
pub fn Raw::new(
  screen : @emath.Rect,
  time? : Double = 0,
  dt? : Double = 0.016,
) -> Raw {
  { screen, events: [], time, dt, focused: true, }
}

///|
/// How far the pointer may travel between press and release and still count as
/// a click rather than a drag.
pub const DRAG_THRESHOLD : Double = 6

///|
/// How long two clicks may be apart and still count as a double click.
pub const DOUBLE_CLICK_SECONDS : Double = 0.35

///|
/// What the widgets ask about the input, derived from the raw events.
///
/// Deriving this once per frame rather than letting every widget read the event
/// list is what makes a widget's question — was I clicked — a lookup instead of
/// a search, and it is where press and release become a click.
pub struct State {
  mut screen : @emath.Rect
  mut time : Double
  mut dt : Double
  mut focused : Bool
  mut pointer : @emath.Vec2?
  mut delta : @emath.Vec2
  mut scroll : @emath.Vec2
  down : Array[Bool]
  press_at : Array[@emath.Vec2]
  press_time : Array[Double]
  pressed : Array[Bool]
  released : Array[Bool]
  clicked : Array[Bool]
  double_clicked : Array[Bool]
  mut last_click : Double
  keys : Array[Key]
  mut typed : String
  mut pasted : String?
  events : Array[Event]
}

///|
/// Input state with nothing held and the pointer nowhere.
pub fn State::new() -> State {
  {
    screen: @emath.nothing,
    time: 0,
    dt: 0,
    focused: true,
    pointer: None,
    delta: @emath.zero,
    scroll: @emath.zero,
    down: [false, false, false],
    press_at: [@emath.zero, @emath.zero, @emath.zero],
    press_time: [0, 0, 0],
    pressed: [false, false, false],
    released: [false, false, false],
    clicked: [false, false, false],
    double_clicked: [false, false, false],
    last_click: -1000,
    keys: [],
    typed: "",
    pasted: None,
    events: [],
  }
}

///|
/// Fold a frame's events into the state.
pub fn State::begin(self : State, raw : Raw) -> Unit {
  self.screen = raw.screen
  self.time = raw.time
  self.dt = raw.dt
  self.focused = raw.focused
  self.scroll = @emath.zero
  self.delta = @emath.zero
  self.typed = ""
  self.pasted = None
  self.keys.clear()
  self.events.clear()
  for i in 0..<3 {
    self.pressed[i] = false
    self.released[i] = false
    self.clicked[i] = false
    self.double_clicked[i] = false
  }
  for event in raw.events {
    self.events.push(event)
    match event {
      PointerMoved(at) => {
        match self.pointer {
          Some(was) => self.delta = self.delta + (at - was)
          None => ()
        }
        self.pointer = Some(at)
      }
      PointerButton(at~, btn~, down~, ..) => {
        let i = btn.index()
        self.pointer = Some(at)
        self.down[i] = down
        if down {
          self.pressed[i] = true
          self.press_at[i] = at
          self.press_time[i] = raw.time
        } else {
          self.released[i] = true
          // A release counts as a click when the pointer stayed put: a press
          // that travelled was a drag, and a drag is not a click.
          if (at - self.press_at[i]).length() <= DRAG_THRESHOLD {
            self.clicked[i] = true
            if raw.time - self.last_click <= DOUBLE_CLICK_SECONDS {
              self.double_clicked[i] = true
            }
            self.last_click = raw.time
          }
        }
      }
      PointerGone => {
        self.pointer = None
        for i in 0..<3 {
          self.down[i] = false
        }
      }
      Scroll(by) => self.scroll = self.scroll + by
      KeyDown(key~, ..) => self.keys.push(key)
      KeyUp(..) => ()
      Text(text) => self.typed = self.typed + text
      Paste(text) => self.pasted = Some(text)
      Focus(has) => self.focused = has
    }
  }
}

///|
/// Where the pointer is, if it is anywhere.
pub fn State::pointer(self : State) -> @emath.Vec2? {
  self.pointer
}

///|
/// How far the pointer moved this frame.
pub fn State::pointer_delta(self : State) -> @emath.Vec2 {
  self.delta
}

///|
/// True while the button is held.
pub fn State::is_down(self : State, btn : Btn) -> Bool {
  self.down[btn.index()]
}

///|
/// True on the frame the button went down.
pub fn State::pressed(self : State, btn : Btn) -> Bool {
  self.pressed[btn.index()]
}

///|
/// True on the frame the button came up.
pub fn State::released(self : State, btn : Btn) -> Bool {
  self.released[btn.index()]
}

///|
/// True on the frame a press and release landed in the same place.
pub fn State::clicked(self : State, btn : Btn) -> Bool {
  self.clicked[btn.index()]
}

///|
/// True when that click was the second of a pair.
pub fn State::double_clicked(self : State, btn : Btn) -> Bool {
  self.double_clicked[btn.index()]
}

///|
/// Where the button went down, which is what tells a drag from a click.
pub fn State::press_origin(self : State, btn : Btn) -> @emath.Vec2 {
  self.press_at[btn.index()]
}

///|
/// How far the surface was scrolled this frame.
pub fn State::scroll(self : State) -> @emath.Vec2 {
  self.scroll
}

///|
/// The keys pressed this frame.
pub fn State::keys(self : State) -> Array[Key] {
  self.keys
}

///|
/// The modifiers held the last time this key went down this frame, if it did.
///
/// A key and its modifiers arrive together, so asking for them together is the
/// only way a widget can tell a plain arrow from a shifted one.
pub fn State::key_down(self : State, key : Key) -> Mods? {
  let mut found : Mods? = None
  for event in self.events {
    match event {
      KeyDown(key=went_down, mods~, ..) =>
        if went_down == key {
          found = Some(mods)
        }
      _ => ()
    }
  }
  found
}

///|
/// True when this key was pressed this frame.
pub fn State::key_pressed(self : State, key : Key) -> Bool {
  for pressed in self.keys {
    if pressed == key {
      return true
    }
  }
  false
}

///|
/// The text typed this frame.
pub fn State::typed(self : State) -> String {
  self.typed
}

///|
/// The text pasted this frame, if any.
pub fn State::pasted(self : State) -> String? {
  self.pasted
}

///|
/// The surface's rectangle.
pub fn State::screen(self : State) -> @emath.Rect {
  self.screen
}

///|
/// Seconds since the program started.
pub fn State::time(self : State) -> Double {
  self.time
}

///|
/// Seconds since the last frame.
pub fn State::dt(self : State) -> Double {
  self.dt
}

///|
/// Whether the surface has the host's focus.
pub fn State::has_focus(self : State) -> Bool {
  self.focused
}

///|
pub extend Btn with Debug::{to_repr}

///|
pub extend Btn with Eq::{not_equal, equal}

///|
pub extend Event with Debug::{to_repr}

///|
pub extend Event with Eq::{not_equal, equal}

///|
pub extend Key with Debug::{to_repr}

///|
pub extend Key with Eq::{not_equal, equal}

///|
pub extend Mods with Debug::{to_repr}

///|
pub extend Mods with Eq::{not_equal, equal}
