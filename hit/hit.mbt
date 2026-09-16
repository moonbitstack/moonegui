// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What a widget is willing to notice.
pub(all) struct Sense {
  hover : Bool
  click : Bool
  drag : Bool
  focus : Bool
} derive(Eq, Debug)

///|
/// A widget the pointer passes straight through: a label, a rule, a background.
pub let inert : Sense = {
  hover: false,
  click: false,
  drag: false,
  focus: false,
}

///|
/// A widget that only wants to know when the pointer is over it.
pub let hover : Sense = {
  hover: true,
  click: false,
  drag: false,
  focus: false,
}

///|
/// A widget that can be clicked.
pub let click : Sense = { hover: true, click: true, drag: false, focus: true, }

///|
/// A widget that can be dragged.
pub let drag : Sense = { hover: true, click: false, drag: true, focus: false, }

///|
/// A widget that can be clicked and dragged, which is what a slider handle and
/// a scrollbar both need.
pub let click_and_drag : Sense = {
  hover: true,
  click: true,
  drag: true,
  focus: true,
}

///|
/// True when the widget notices nothing at all.
pub fn Sense::is_inert(self : Sense) -> Bool {
  !self.hover && !self.click && !self.drag && !self.focus
}

///|
/// Where a widget was, and what it was willing to notice there.
pub(all) struct WidgetRect {
  id : @id.Id
  rect : @emath.Rect
  sense : Sense
  enabled : Bool
  /// Which layer it was drawn in; a higher layer is nearer the viewer.
  layer : Int
} derive(Eq, Debug)

///|
/// Every widget of one frame, in the order they were built.
pub struct Rects {
  items : Array[WidgetRect]
  by_id : Map[@id.Id, WidgetRect]
}

///|
/// An empty set of rectangles.
pub fn Rects::new() -> Rects {
  { items: [], by_id: Map([]), }
}

///|
/// Record a widget.
pub fn Rects::add(self : Rects, widget : WidgetRect) -> Unit {
  self.items.push(widget)
  self.by_id[widget.id] = widget
}

///|
/// Where this widget was, if it was anywhere.
pub fn Rects::find(self : Rects, id : @id.Id) -> WidgetRect? {
  self.by_id.get(id)
}

///|
/// How many widgets were recorded.
pub fn Rects::count(self : Rects) -> Int {
  self.items.length()
}

///|
/// Everything recorded.
pub fn Rects::items(self : Rects) -> Array[WidgetRect] {
  self.items
}

///|
/// Forget the frame.
pub fn Rects::clear(self : Rects) -> Unit {
  self.items.clear()
  self.by_id.clear()
}

///|
/// The widget under a point.
///
/// Later wins over earlier and a higher layer wins over a lower one, because a
/// widget built later is drawn on top of one built earlier. Widgets that notice
/// nothing are skipped: a label does not swallow a click meant for the panel
/// underneath it.
pub fn Rects::at(self : Rects, point : @emath.Vec2) -> WidgetRect? {
  let mut found : WidgetRect? = None
  for item in self.items {
    if !item.enabled || item.sense.is_inert() || !item.rect.contains(point) {
      continue
    }
    match found {
      Some(best) => if item.layer >= best.layer { found = Some(item) }
      None => found = Some(item)
    }
  }
  found
}

///|
/// What happened to a widget this frame.
///
/// This is the whole of a widget's return value. A caller asks it questions —
/// was I clicked, am I being dragged, did my value change — instead of being
/// handed a callback, which is what makes an immediate-mode frame readable from
/// top to bottom.
pub(all) struct Response {
  id : @id.Id
  rect : @emath.Rect
  sense : Sense
  enabled : Bool
  hovered : Bool
  pressed : Bool
  released : Bool
  clicked : Bool
  double_clicked : Bool
  dragged : Bool
  drag_delta : @emath.Vec2
  focused : Bool
  mut changed : Bool
} derive(Eq, Debug)

///|
/// A response to nothing: the widget was not interacted with.
pub fn Response::none(id : @id.Id, rect : @emath.Rect) -> Response {
  {
    id,
    rect,
    sense: inert,
    enabled: true,
    hovered: false,
    pressed: false,
    released: false,
    clicked: false,
    double_clicked: false,
    dragged: false,
    drag_delta: @emath.zero,
    focused: false,
    changed: false,
  }
}

///|
/// Say that the widget's value changed, which the widget itself knows and the
/// interaction cannot.
pub fn Response::mark_changed(self : Response) -> Unit {
  self.changed = true
}

///|
/// The response to either of two widgets, for a widget built out of others.
pub fn Response::union(self : Response, other : Response) -> Response {
  {
    ..self,
    rect: self.rect.union(other.rect),
    hovered: self.hovered || other.hovered,
    pressed: self.pressed || other.pressed,
    released: self.released || other.released,
    clicked: self.clicked || other.clicked,
    double_clicked: self.double_clicked || other.double_clicked,
    dragged: self.dragged || other.dragged,
    focused: self.focused || other.focused,
    changed: self.changed || other.changed,
  }
}

///|
/// Work out what happened to one widget.
///
/// `over` is the widget the pointer is over, which comes from the frame before;
/// `pressed_on` is the widget the button went down on, which is what decides
/// whether a release counts as a click here or somewhere else.
pub fn interact(
  widget : WidgetRect,
  over : @id.Id,
  pressed_on : @id.Id,
  dragged : @id.Id,
  focus : @id.Id,
  state : @input.State,
) -> Response {
  let hovered = widget.enabled && over == widget.id
  let primary = @input.Btn::Primary
  let is_dragged = widget.enabled && widget.sense.drag && dragged == widget.id
  let clicked = widget.enabled &&
    widget.sense.click &&
    hovered &&
    state.clicked(primary) &&
    pressed_on == widget.id
  {
    id: widget.id,
    rect: widget.rect,
    sense: widget.sense,
    enabled: widget.enabled,
    hovered,
    pressed: hovered && state.pressed(primary),
    released: hovered && state.released(primary),
    clicked,
    double_clicked: clicked && state.double_clicked(primary),
    dragged: is_dragged,
    drag_delta: if is_dragged {
      state.pointer_delta()
    } else {
      @emath.zero
    },
    focused: focus == widget.id,
    changed: false,
  }
}
