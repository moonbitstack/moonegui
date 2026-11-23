// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What a control is called in the program that owns it.
///
/// A tree carries tags rather than functions so that it stays data: two frames
/// can be compared, an unchanged subtree can be skipped, and a tree can be
/// written down and read back. What a tag means is the program's business.
#derive(Eq, Debug)
pub(all) struct Tag(Int32)

///|
/// A tag with this number.
pub fn Tag::new(value : Int32) -> Tag {
  Tag(value)
}

///|
/// The number inside.
pub fn Tag::value(self : Tag) -> Int32 {
  let Tag(value) = self
  value
}

///|
/// Something the user did to the tree.
///
/// An event carries the new value, not just the fact that something happened:
/// a program that gets `Toggled(tag, true)` does not have to remember what the
/// tick box said before, and a program that is handed the old value back has to
/// keep two copies of its own state in step.
#derive(Eq, Debug)
pub(all) enum Event {
  Clicked(Tag)
  Toggled(tag~ : Tag, value~ : Bool)
  Edited(tag~ : Tag, text~ : String)
  Moved(tag~ : Tag, value~ : Double)
  Chosen(tag~ : Tag, at~ : Int32)
  Opened(tag~ : Tag, open~ : Bool)
}

///|
/// How a button is drawn.
#derive(Eq, Debug)
pub(all) enum ButtonKind {
  Normal
  /// The one action the screen is about.
  Accent
  /// No ground until the pointer is on it.
  Quiet
}

///|
/// A node of an interface.
///
/// Every field is a value, so the whole tree can be compared with the tree of
/// the frame before; that comparison is what lets an unchanged subtree be drawn
/// from what it produced last time instead of being built again.
#derive(Eq, Debug)
pub(all) enum View {
  Empty
  Text(text~ : String, role~ : @ctx.TextRole, wrap~ : Bool)
  Button(text~ : String, tag~ : Tag, kind~ : ButtonKind, enabled~ : Bool)
  Checkbox(text~ : String, tag~ : Tag, value~ : Bool, enabled~ : Bool)
  Radio(text~ : String, tag~ : Tag, value~ : Bool, enabled~ : Bool)
  Switch(tag~ : Tag, value~ : Bool, enabled~ : Bool)
  Slider(
    tag~ : Tag,
    value~ : Double,
    low~ : Double,
    high~ : Double,
    width~ : Double,
    enabled~ : Bool,
  )
  DragValue(
    tag~ : Tag,
    value~ : Double,
    low~ : Double,
    high~ : Double,
    speed~ : Double,
    width~ : Double,
    enabled~ : Bool,
  )
  Edit(
    text~ : String,
    tag~ : Tag,
    hint~ : String,
    width~ : Double,
    enabled~ : Bool,
  )
  TextArea(
    text~ : String,
    tag~ : Tag,
    rows~ : Int32,
    width~ : Double,
    enabled~ : Bool,
  )
  Combo(
    items~ : Array[String],
    tag~ : Tag,
    chosen~ : Int32,
    open~ : Bool,
    width~ : Double,
  )
  Tabs(labels~ : Array[String], tag~ : Tag, chosen~ : Int32)
  Progress(fraction~ : Double, width~ : Double, label~ : String)
  Spinner(phase~ : Double)
  Hyperlink(text~ : String, tag~ : Tag)
  Badge(text~ : String, tone~ : @ctx.Tone)
  Separator
  Space(width~ : Double, height~ : Double)
  Row(flow~ : Flow, children~ : Array[View])
  Column(flow~ : Flow, children~ : Array[View])
  Grid(columns~ : Int32, flow~ : Flow, children~ : Array[View])
  Panel(title~ : String, tone~ : @ctx.Tone, padding~ : Double, child~ : View)
  Group(title~ : String, open~ : Bool, tag~ : Tag, child~ : View)
  Scroll(tag~ : Tag, height~ : Double, child~ : View)
  List(items~ : Array[String], tag~ : Tag, chosen~ : Int32, height~ : Double)
  Table(
    columns~ : Array[String],
    rows~ : Array[Array[String]],
    tag~ : Tag,
    chosen~ : Int32,
    width~ : Double,
  )
  Sized(bounds~ : Bounds, child~ : View)
}

///|
/// Nothing at all, for a branch of a tree that has nothing to show.
pub fn empty() -> View {
  Empty
}

///|
/// A line of body text.
pub fn text(string : String) -> View {
  Text(text=string, role=Body, wrap=false)
}

///|
/// A line of text a reader may skip.
pub fn weak_text(string : String) -> View {
  Text(text=string, role=Weak, wrap=false)
}

///|
/// A line larger than the body text.
pub fn heading(string : String) -> View {
  Text(text=string, role=Heading, wrap=false)
}

///|
/// A line smaller than the body text.
pub fn caption(string : String) -> View {
  Text(text=string, role=Caption, wrap=false)
}

///|
/// Text that breaks to fit the room it is given.
pub fn paragraph(string : String) -> View {
  Text(text=string, role=Body, wrap=true)
}

///|
/// A button.
pub fn button(string : String, tag : Tag) -> View {
  Button(text=string, tag~, kind=Normal, enabled=true)
}

///|
/// The button a screen is about.
pub fn accent_button(string : String, tag : Tag) -> View {
  Button(text=string, tag~, kind=Accent, enabled=true)
}

///|
/// A button with no ground until the pointer is on it.
pub fn quiet_button(string : String, tag : Tag) -> View {
  Button(text=string, tag~, kind=Quiet, enabled=true)
}

///|
/// A tick box.
pub fn checkbox(string : String, tag : Tag, value : Bool) -> View {
  Checkbox(text=string, tag~, value~, enabled=true)
}

///|
/// One of a set of choices.
pub fn radio(string : String, tag : Tag, value : Bool) -> View {
  Radio(text=string, tag~, value~, enabled=true)
}

///|
/// A switch.
pub fn switch(tag : Tag, value : Bool) -> View {
  Switch(tag~, value~, enabled=true)
}

///|
/// A handle on a range.
pub fn slider(
  tag : Tag,
  value : Double,
  low~ : Double = 0,
  high~ : Double = 1,
  width~ : Double = 160,
) -> View {
  Slider(tag~, value~, low~, high~, width~, enabled=true)
}

///|
/// A number in a box that is dragged to change it.
pub fn drag_value(
  tag : Tag,
  value : Double,
  low~ : Double = -1.0e9,
  high~ : Double = 1.0e9,
  speed~ : Double = 1,
  width~ : Double = 64,
) -> View {
  DragValue(tag~, value~, low~, high~, speed~, width~, enabled=true)
}

///|
/// A single line of editable text.
pub fn edit(
  string : String,
  tag : Tag,
  hint~ : String = "",
  width~ : Double = 200,
) -> View {
  Edit(text=string, tag~, hint~, width~, enabled=true)
}

///|
/// Several lines of editable text.
pub fn text_area(
  string : String,
  tag : Tag,
  rows~ : Int32 = 4,
  width~ : Double = 240,
) -> View {
  TextArea(text=string, tag~, rows~, width~, enabled=true)
}

///|
/// A field that shows the chosen item and, when open, the rest of the list.
pub fn combo(
  items : Array[String],
  tag : Tag,
  chosen : Int32,
  open~ : Bool = false,
  width~ : Double = 160,
) -> View {
  Combo(items~, tag~, chosen~, open~, width~)
}

///|
/// A row of words, one of which is chosen.
pub fn tabs(labels : Array[String], tag : Tag, chosen : Int32) -> View {
  Tabs(labels~, tag~, chosen~)
}

///|
/// How far along something is.
pub fn progress(
  fraction : Double,
  width~ : Double = 160,
  label~ : String = "",
) -> View {
  Progress(fraction~, width~, label~)
}

///|
/// Something is happening and there is no fraction to report.
pub fn spinner(phase : Double) -> View {
  Spinner(phase~)
}

///|
/// A word that leads somewhere.
pub fn hyperlink(string : String, tag : Tag) -> View {
  Hyperlink(text=string, tag~)
}

///|
/// A short word in a pill.
pub fn badge(string : String, tone~ : @ctx.Tone = Accent) -> View {
  Badge(text=string, tone~)
}

///|
/// A rule across the region.
pub fn separator() -> View {
  Separator
}

///|
/// A gap.
pub fn space(height : Double, width~ : Double = 0) -> View {
  Space(width~, height~)
}

///|
/// Children side by side.
pub fn row(children : Array[View]) -> View {
  Row(flow=row_flow, children~)
}

///|
/// Children side by side, placed by this flow.
pub fn row_with(flow : Flow, children : Array[View]) -> View {
  Row(flow~, children~)
}

///|
/// Children stacked downwards.
pub fn column(children : Array[View]) -> View {
  Column(flow=column_flow, children~)
}

///|
/// Children stacked downwards, placed by this flow.
pub fn column_with(flow : Flow, children : Array[View]) -> View {
  Column(flow~, children~)
}

///|
/// Children in equal columns across the region.
pub fn grid(columns : Int32, children : Array[View]) -> View {
  Grid(columns~, flow=row_flow, children~)
}

///|
/// Children in equal columns, placed by this flow.
pub fn grid_with(columns : Int32, flow : Flow, children : Array[View]) -> View {
  Grid(columns~, flow~, children~)
}

///|
/// A box around something.
pub fn panel(
  child : View,
  title~ : String = "",
  tone~ : @ctx.Tone = Surface,
  padding~ : Double = 8,
) -> View {
  Panel(title~, tone~, padding~, child~)
}

///|
/// A section that folds away.
pub fn group(title : String, open : Bool, tag : Tag, child : View) -> View {
  Group(title~, open~, tag~, child~)
}

///|
/// A window onto something taller.
pub fn scroll(tag : Tag, height : Double, child : View) -> View {
  Scroll(tag~, height~, child~)
}

///|
/// A column of words, one of which is chosen.
pub fn list(
  items : Array[String],
  tag : Tag,
  chosen : Int32,
  height~ : Double = 160,
) -> View {
  List(items~, tag~, chosen~, height~)
}

///|
/// Rows of cells under a header.
pub fn table(
  columns : Array[String],
  rows : Array[Array[String]],
  tag : Tag,
  chosen : Int32,
  width~ : Double = 320,
) -> View {
  Table(columns~, rows~, tag~, chosen~, width~)
}

///|
/// Something held to a size.
pub fn sized(bounds : Bounds, child : View) -> View {
  Sized(bounds~, child~)
}

///|
/// The tag this node answers with, if it has one.
pub fn View::tag(self : View) -> Tag? {
  match self {
    Button(tag~, ..) => Some(tag)
    Checkbox(tag~, ..) => Some(tag)
    Radio(tag~, ..) => Some(tag)
    Switch(tag~, ..) => Some(tag)
    Slider(tag~, ..) => Some(tag)
    DragValue(tag~, ..) => Some(tag)
    Edit(tag~, ..) => Some(tag)
    TextArea(tag~, ..) => Some(tag)
    Combo(tag~, ..) => Some(tag)
    Tabs(tag~, ..) => Some(tag)
    Hyperlink(tag~, ..) => Some(tag)
    Group(tag~, ..) => Some(tag)
    Scroll(tag~, ..) => Some(tag)
    List(tag~, ..) => Some(tag)
    Table(tag~, ..) => Some(tag)
    _ => None
  }
}

///|
/// What a node is called among its siblings: its tag when it has one, and the
/// place it was put in when it has not.
///
/// A tag is the better name because a tag survives the list around it being
/// edited; a plain text node has nothing but its place to be known by.
pub fn View::name(self : View, index : Int32) -> String {
  match self.tag() {
    Some(tag) => "t" + tag.value().to_string()
    None => "#" + index.to_string()
  }
}
