// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// A region of the interface being built.
///
/// This is the value a caller spends the frame with: it hands out space, says
/// what happened in that space, and draws into it. A nested region is another
/// `Ui` sharing the same context, which is how a row inside a column costs
/// nothing but a placer.
pub struct Ui {
  ctx : Ctx
  id : @id.Id
  placer : @layout.Placer
  clip : @emath.Rect
  mut enabled : Bool
  mut counter : Int
}

///|
/// The root region, filling the screen.
pub fn Ui::root(ctx : Ctx, screen : @emath.Rect) -> Ui {
  {
    ctx,
    id: @id.root("moonegui"),
    placer: @layout.Placer::new(
      screen,
      layout=@layout.top_down,
      spacing=ctx.style.spacing,
    ),
    // The root does not clip: a surface is bounded by being a surface, and
    // clipping to it would make every widget whose outline sits on the edge
    // carry a clip that changes nothing.
    clip: @paint.unclipped,
    enabled: true,
    counter: 0,
  }
}

///|
/// The context this region belongs to.
pub fn Ui::ctx(self : Ui) -> Ctx {
  self.ctx
}

///|
/// The style in force.
pub fn Ui::style(self : Ui) -> Style {
  self.ctx.style
}

///|
/// This region's id, which the ids of its widgets are derived from.
pub fn Ui::id(self : Ui) -> @id.Id {
  self.id
}

///|
/// How much room is left.
pub fn Ui::available(self : Ui) -> @emath.Vec2 {
  self.placer.available()
}

///|
/// Everything this region has placed so far.
pub fn Ui::used(self : Ui) -> @emath.Rect {
  self.placer.used()
}

///|
/// Whether widgets in this region can be interacted with.
pub fn Ui::is_enabled(self : Ui) -> Bool {
  self.enabled
}

///|
/// Turn interaction off for everything built from here on: the widgets still
/// draw, in their disabled colours, which is what a form with a precondition
/// needs.
pub fn Ui::disable(self : Ui) -> Unit {
  self.enabled = false
}

///|
/// A painter clipped to this region.
pub fn Ui::painter(self : Ui) -> @paint.Painter {
  self.ctx.painter.sub(self.clip)
}

///|
/// Measure a string in a font.
pub fn Ui::measure(
  self : Ui,
  text : String,
  font? : @paint.FontId,
) -> @emath.Vec2 {
  self.ctx.back.measure(text, self.font_of(font))
}

///|
/// The height of one line of text.
pub fn Ui::line_height(self : Ui, font? : @paint.FontId) -> Double {
  self.ctx.back.line_height(self.font_of(font))
}

///|
fn Ui::font_of(self : Ui, font : @paint.FontId?) -> @paint.FontId {
  match font {
    Some(value) => value
    None => self.ctx.style.font
  }
}

///|
/// An id for the next widget in this region.
///
/// The salt is usually the widget's label, which keeps the id stable while the
/// interface is edited. Widgets built in a loop with the same label would
/// collide, so the region also counts: the id is position and label together.
pub fn Ui::next_id(self : Ui, salt : String) -> @id.Id {
  self.counter = self.counter + 1
  self.id.child(salt).index(self.counter)
}

///|
/// Take space for a widget and find out what happened there.
pub fn Ui::allocate(
  self : Ui,
  want : @emath.Vec2,
  sense : @hit.Sense,
  salt : String,
) -> (@emath.Rect, @hit.Response) {
  let id = self.next_id(salt)
  let rect = self.placer.allocate(want)
  let response = self.ctx.interact(id, rect, sense, enabled=self.enabled)
  (rect, response)
}

///|
/// Take space without claiming any interaction, for something purely drawn.
pub fn Ui::allocate_space(self : Ui, want : @emath.Vec2) -> @emath.Rect {
  self.placer.allocate(want)
}

///|
/// Leave a gap.
pub fn Ui::gap(self : Ui, size : Double) -> Unit {
  let want : @emath.Vec2 = if self.placer.layout().dir.is_horizontal() {
    { x: size, y: 0, }
  } else {
    { x: 0, y: size, }
  }
  self.placer.allocate(want) |> ignore
}

///|
/// Build a nested region and give back the space it used.
pub fn Ui::child(
  self : Ui,
  layout : @layout.Layout,
  body : (Ui) -> Unit,
  size? : @emath.Vec2,
  salt? : String = "child",
) -> @emath.Rect {
  let used = self.nested(self.placer.child(layout, size?), salt, body)
  // The parent only learns how much room the child took once the child is
  // finished, which is why the parent's cursor moves here rather than when the
  // child was created.
  self.placer.advance(used)
  used
}

///|
/// Build a nested region filling exactly this rectangle.
///
/// Where `child` asks the layout where a region goes, this puts it where the
/// caller says and leaves the parent's cursor where it was: whoever worked out
/// the rectangle is also the one who knows what should follow it.
pub fn Ui::region(
  self : Ui,
  layout : @layout.Layout,
  rect : @emath.Rect,
  body : (Ui) -> Unit,
  salt? : String = "region",
) -> @emath.Rect {
  self.nested(
    @layout.Placer::new(rect, layout~, spacing=self.placer.spacing()),
    salt,
    body,
  )
}

///|
fn Ui::nested(
  self : Ui,
  placer : @layout.Placer,
  salt : String,
  body : (Ui) -> Unit,
) -> @emath.Rect {
  let child = {
    ctx: self.ctx,
    id: self.next_id(salt),
    placer,
    clip: self.clip.intersect(placer.max()),
    enabled: self.enabled,
    counter: 0,
  }
  body(child)
  child.placer.used()
}

///|
/// Build a row.
pub fn Ui::horizontal(self : Ui, body : (Ui) -> Unit) -> @emath.Rect {
  self.child(@layout.left_to_right, body, salt="row")
}

///|
/// Build a column.
pub fn Ui::vertical(self : Ui, body : (Ui) -> Unit) -> @emath.Rect {
  self.child(@layout.top_down, body, salt="column")
}

///|
/// Draw a panel behind a nested region: the background is painted first, then
/// the region is built on top of it.
pub fn Ui::panel(
  self : Ui,
  body : (Ui) -> Unit,
  margin? : Double = 8,
  size? : @emath.Vec2,
) -> @emath.Rect {
  let style = self.ctx.style
  let outer = match size {
    Some(value) => @emath.Rect::at(self.placer.cursor(), value)
    None => @emath.Rect::at(self.placer.cursor(), self.available())
  }
  self
  .painter()
  .rect(
    outer,
    fill=style.background,
    stroke=style.outline,
    corner=@paint.Corner::same(style.corner),
  )
  self.region(@layout.top_down, outer.shrink(margin), body, salt="panel")
  |> ignore
  self.placer.advance(outer)
  outer
}
