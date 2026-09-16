// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What the widgets look like.
///
/// One value rather than a cascade: an immediate-mode frame reads the style
/// every time it draws anything, and a lookup that walks a tree of rules would
/// be the most expensive thing in the frame. Changing an interface's look means
/// handing it a different `Style`.
pub(all) struct Style {
  /// The gap left between widgets.
  spacing : @emath.Vec2
  /// The room inside a button or a field, around its text.
  padding : @emath.Vec2
  /// The smallest a clickable widget is allowed to be, whatever its content —
  /// a checkbox with a one-character label is still a target for a pointer.
  min_height : Double
  font : @paint.FontId
  text : @paint.Color
  weak_text : @paint.Color
  background : @paint.Color
  surface : @paint.Color
  hovered : @paint.Color
  active : @paint.Color
  accent : @paint.Color
  outline : @paint.Stroke
  corner : Double
} derive(Eq, Debug)

///|
/// The look the library comes with: a dark interface, because a canvas with
/// nothing drawn on it is easier to make dark than light.
pub let dark : Style = {
  spacing: { x: 8, y: 6, },
  padding: { x: 8, y: 4, },
  min_height: 24,
  font: { size: 14, family: Sans, },
  text: { r: 222, g: 222, b: 222, a: 255, },
  weak_text: { r: 140, g: 140, b: 140, a: 255, },
  background: { r: 24, g: 24, b: 27, a: 255, },
  surface: { r: 40, g: 40, b: 46, a: 255, },
  hovered: { r: 56, g: 56, b: 64, a: 255, },
  active: { r: 74, g: 74, b: 84, a: 255, },
  accent: { r: 92, g: 140, b: 255, a: 255, },
  outline: { width: 1, color: { r: 70, g: 70, b: 78, a: 255, }, },
  corner: 4,
}

///|
/// The same interface on a light background.
pub let light : Style = {
  ..dark,
  text: { r: 28, g: 28, b: 32, a: 255, },
  weak_text: { r: 110, g: 110, b: 118, a: 255, },
  background: { r: 250, g: 250, b: 252, a: 255, },
  surface: { r: 236, g: 236, b: 240, a: 255, },
  hovered: { r: 224, g: 224, b: 230, a: 255, },
  active: { r: 208, g: 208, b: 216, a: 255, },
  outline: { width: 1, color: { r: 200, g: 200, b: 208, a: 255, }, },
}

///|
/// The background a widget draws with, given what is happening to it. Every
/// widget answers this question, and answering it the same way everywhere is
/// most of what makes an interface look like one interface.
pub fn Style::fill_for(self : Style, response : @hit.Response) -> @paint.Color {
  if !response.enabled {
    self.surface
  } else if response.pressed || response.dragged {
    self.active
  } else if response.hovered {
    self.hovered
  } else {
    self.surface
  }
}

///|
/// The text colour for a widget in that state.
pub fn Style::text_for(self : Style, response : @hit.Response) -> @paint.Color {
  if response.enabled {
    self.text
  } else {
    self.weak_text
  }
}

///|
/// The outline a widget draws, which is the accent colour while it has focus so
/// that keyboard users can see where they are.
pub fn Style::outline_for(
  self : Style,
  response : @hit.Response,
) -> @paint.Stroke {
  if response.focused {
    { width: 1, color: self.accent, }
  } else {
    self.outline
  }
}
