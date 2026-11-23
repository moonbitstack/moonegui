---
name: moonegui
description: "Build graphical interfaces in MoonBit the immediate-mode way: a frame is a function of your state that draws controls and returns what the user did to them, either as calls (label, button, checkbox, slider, text field, table, scroll area) or as a tree of views the interpreter lays out, drawn through any backend that can measure text and draw five shapes — a canvas, HTML elements, a frame buffer."
---

# moonegui

Two ways to write one interface: calls, or a tree. Both produce the same shapes.
The library never owns a window, a loop, or the clock — a host hands over what
happened and takes back a list of shapes.

```bash
moon add moonbitstack/moonegui
moon add moonbitstack/moonpane   # the backends that draw into a page
```

The core has no foreign function in it and runs on all four targets. Drawing
into a browser — a canvas or the document's own elements — is the
`moonbitstack/moonpane` module: `@canvas.Canvas` and `@html.Html` both answer
`@back.Backend`, so a frame written either way goes to either one.

## A frame as calls

Every control takes the value it shows and gives back the value the user made of
it, next to a `Response` that says what happened.

```moonbit
fn account(ui : @ctx.Ui, name : String, remember : Bool) -> (String, Bool) {
  @widget.heading(ui, "Account") |> ignore
  let name = @widget.edit(ui, name, hint="your name").0
  let remember = @widget.checkbox(ui, "Remember me", remember).0
  if @widget.button(ui, "Save").clicked {
    println("saved " + name)
  }
  (name, remember)
}
```

Draw it inside a frame the host drives:

```moonbit
fn frame(ctx : @ctx.Ctx, raw : @input.Raw, name : String) -> String {
  let out = ctx.run(raw, fn(ui) { @widget.label(ui, name) |> ignore })
  out.shapes.length() |> ignore
  name
}
```

## The same frame as a tree

A tree is data: nodes with a `Tag` on every control. The interpreter draws it and
hands back what the user did, so nothing in the tree holds a closure or a widget
object and an unchanged subtree is not built again.

```moonbit
let name_tag : @view.Tag = @view.Tag::new(1)

fn account_tree(name : String, remember : Bool) -> Array[@view.View] {
  [
    @view.heading("Account"),
    @view.edit(name, name_tag, hint="your name"),
    @view.checkbox("Remember me", @view.Tag::new(2), remember),
    @view.button("Save", @view.Tag::new(3)),
  ]
}

fn account_step(ui : @ctx.Ui, interp : @view.Interp, name : String) -> String {
  interp.show(ui, account_tree(name, false))
  let mut name = name
  for event in interp.events() {
    match event {
      Edited(tag~, text~) => if tag == name_tag { name = text }
      _ => ()
    }
  }
  name
}
```

## Rows, columns, grids

Layout is measured before it is drawn, because a row has to know how wide its
children are. A flow carries the gap, the padding, where children sit across it
and along it; bounds hold a node between a least and a most.

```moonbit
fn toolbar() -> @view.View {
  @view.column_with(@layout.column_flow.with_stretch(true), [
    @view.row([
      @view.button("Save", @view.Tag::new(1)),
      @view.button("Cancel", @view.Tag::new(2)),
    ]),
    @view.grid(3, [
      @view.text("one"),
      @view.text("two"),
      @view.text("three"),
    ]),
    @view.sized(@layout.Bounds::at_least({ x: 240, y: 0 }), @view.text("wide")),
  ])
}
```

## Rules that decide whether it looks right

- A click is matched against the rectangles of the **previous** frame. Feed one
  frame with no events after building a new interface, or the first click lands
  nowhere.
- Identity comes from place and tag: two siblings with the same tag are the same
  widget as far as focus, carets and scroll offsets are concerned. Give the
  controls in a list a tag each.
- A widget holds no state. A caret, a scroll offset and a folded section belong
  to the caller (a tree node's props) or to the frame's memory.
- A control draws whatever `style` the context carries; change the look by
  handing the context a different `@ctx.Style`, not by passing colours around.
- `Ui::disable` turns interaction off for everything built after it — the
  controls still draw, in their disabled colours.
- A tree's cells do not clip. A region built with `Ui::child` or `Ui::region`
  does, so an outline sitting exactly on its edge loses half a pixel; give it a
  padding of one point if that matters.
