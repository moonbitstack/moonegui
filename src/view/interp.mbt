// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What one node of the tree produced the last time it was built.
struct Memo {
  view : View
  rect : @emath.Rect
  room : @emath.Vec2
  size : @emath.Vec2
  shapes : Array[@paint.Clipped]
  widgets : Array[@hit.WidgetRect]
  /// True when one of its controls was hovered, pressed or focused as it was
  /// drawn: such a node draws differently the moment the pointer leaves, so it
  /// has to be built again rather than replayed.
  live : Bool
  focusable : Bool
}

///|
/// Draws a tree, and remembers enough of the last frame not to draw the parts
/// of it that did not change.
///
/// The tree is compared whole: a node whose data is the same as last time, in
/// the same rectangle, with nothing this frame able to touch it, is not built
/// again — what it drew is put back where it was. Everything above it still
/// runs, because its own data holds the whole subtree, which is why an edit
/// deep in a tree costs the path down to it and not the tree.
pub struct Interp {
  memo : Map[@id.Id, Memo]
  used : Map[@id.Id, Bool]
  events : Array[Event]
  seed : @id.Id
  mut rebuilt : Int32
  mut reused : Int32
}

///|
/// An interpreter with no names taken.
pub fn Interp::new() -> Interp {
  Interp::with_seed("moonegui-view")
}

///|
/// An interpreter whose ids are seeded from this name, so that two interfaces
/// in one program do not share theirs.
pub fn Interp::with_seed(name : String) -> Interp {
  {
    memo: Map([]),
    used: Map([]),
    events: [],
    seed: @id.root(name),
    rebuilt: 0,
    reused: 0,
  }
}

///|
/// Draw a tree into a region, starting at its top left.
pub fn Interp::show(self : Interp, ui : @ctx.Ui, views : Array[View]) -> Unit {
  self.show_at(ui, ui.rect(), views)
}

///|
/// Draw a tree into this rectangle.
pub fn Interp::show_at(
  self : Interp,
  ui : @ctx.Ui,
  rect : @emath.Rect,
  views : Array[View],
) -> Unit {
  self.events.clear()
  self.rebuilt = 0
  self.reused = 0
  self.used.clear()
  self.stack(ui, self.seed, rect, @layout.column_flow, views)
  self.forget_unused()
}

///|
/// What happened this frame, in the order it happened.
pub fn Interp::events(self : Interp) -> Array[Event] {
  self.events
}

///|
/// Hand every event of this frame to a function.
pub fn Interp::drain(self : Interp, handle : (Event) -> Unit) -> Unit {
  for event in self.events {
    handle(event)
  }
}

///|
/// How many nodes were built this frame.
pub fn Interp::rebuilt(self : Interp) -> Int32 {
  self.rebuilt
}

///|
/// How many nodes were replayed from the frame before.
pub fn Interp::reused(self : Interp) -> Int32 {
  self.reused
}

///|
/// Forget everything, for an interface that was torn down.
pub fn Interp::reset(self : Interp) -> Unit {
  self.memo.clear()
  self.used.clear()
  self.events.clear()
  self.rebuilt = 0
  self.reused = 0
}

///|
fn Interp::forget_unused(self : Interp) -> Unit {
  let stale : Array[@id.Id] = []
  for id, _ in self.memo {
    if !self.used.contains(id) {
      stale.push(id)
    }
  }
  for id in stale {
    self.memo.remove(id)
  }
}

///|
/// Build one node, or put back what it drew last time.
fn Interp::place(
  self : Interp,
  ui : @ctx.Ui,
  view : View,
  path : @id.Id,
  rect : @emath.Rect,
  room : @emath.Vec2,
) -> Unit {
  if self.reusable(ui, view, path, rect) {
    self.reused = self.reused + 1
    self.replay(ui, path)
    return
  }
  self.rebuilt = self.rebuilt + 1
  let size = view.size(ui, room~)
  let from_shapes = ui.painter().count()
  let from_widgets = ui.ctx().rects().count()
  self.paint(ui, view, path, rect, size)
  self.remember(ui, path, view, rect, room, size, from_shapes, from_widgets)
}

///|
fn Interp::measure(
  self : Interp,
  ui : @ctx.Ui,
  view : View,
  path : @id.Id,
  room : @emath.Vec2,
) -> @emath.Vec2 {
  match self.memo.get(path) {
    Some(entry) =>
      if entry.view == view && entry.room == room {
        entry.size
      } else {
        view.size(ui, room~)
      }
    None => view.size(ui, room~)
  }
}

///|
fn Interp::reusable(
  self : Interp,
  ui : @ctx.Ui,
  view : View,
  path : @id.Id,
  rect : @emath.Rect,
) -> Bool {
  match self.memo.get(path) {
    Some(entry) =>
      entry.view == view &&
      entry.rect == rect &&
      !entry.live &&
      !live_now(ui.ctx(), entry.widgets) &&
      !touched(ui, entry)
    None => false
  }
}

///|
fn Interp::replay(self : Interp, ui : @ctx.Ui, path : @id.Id) -> Unit {
  match self.memo.get(path) {
    Some(entry) => {
      // The widgets still have to be where the pointer can find them, which is
      // the only work a replayed node does.
      for widget in entry.widgets {
        ui
        .ctx()
        .interact(widget.id, widget.rect, widget.sense, enabled=widget.enabled)
        |> ignore
      }
      ui.painter().replay(entry.shapes)
      self.used[path] = true
    }
    None => ()
  }
}

///|
fn Interp::remember(
  self : Interp,
  ui : @ctx.Ui,
  path : @id.Id,
  view : View,
  rect : @emath.Rect,
  room : @emath.Vec2,
  size : @emath.Vec2,
  from_shapes : Int32,
  from_widgets : Int32,
) -> Unit {
  let widgets : Array[@hit.WidgetRect] = []
  let all = ui.ctx().rects().items()
  let mut at = from_widgets
  while at < all.length() {
    widgets.push(all[at])
    at = at + 1
  }
  let mut focusable = false
  for widget in widgets {
    if widget.sense.focus && widget.enabled {
      focusable = true
    }
  }
  self.memo[path] = {
    view,
    rect,
    room,
    size,
    shapes: ui.painter().since(from_shapes),
    widgets,
    live: live_now(ui.ctx(), widgets),
    focusable,
  }
  self.used[path] = true
}

///|
/// Whether one of these controls is the one the pointer or the keyboard is on.
fn live_now(ctx : @ctx.Ctx, widgets : Array[@hit.WidgetRect]) -> Bool {
  let over = ctx.hovered()
  let focus = ctx.focused()
  let pressed = ctx.memory().pressed_on()
  let dragging = ctx.memory().dragged()
  for widget in widgets {
    let id = widget.id
    if id == over || id == focus || id == pressed || id == dragging {
      return true
    }
  }
  false
}

///|
/// Whether anything the host reported this frame could change how this node
/// looks.
///
/// A pointer anywhere inside it, a pointer leaving the surface, or — for a node
/// with something focusable in it — any key at all. Being generous here costs a
/// rebuild; being wrong costs a frame that shows what was true once.
fn touched(ui : @ctx.Ui, entry : Memo) -> Bool {
  let input = ui.ctx().input()
  let pointer = input.pointer()
  for event in input.events() {
    match event {
      PointerMoved(at) => if entry.rect.contains(at) { return true }
      PointerButton(at~, ..) => if entry.rect.contains(at) { return true }
      PointerGone => return true
      Scroll(_) =>
        match pointer {
          Some(at) => if entry.rect.contains(at) { return true }
          None => ()
        }
      _ => if entry.focusable { return true }
    }
  }
  false
}
