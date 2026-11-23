<p align="center">
  <svg width="120" height="120" viewBox="0 0 120 120" role="img" aria-label="moonegui">
    <rect x="8" y="14" width="104" height="92" rx="10" fill="#18181b" stroke="#3a3a44" stroke-width="2"/>
    <rect x="20" y="26" width="46" height="10" rx="3" fill="#5c8cff"/>
    <rect x="20" y="46" width="80" height="8" rx="4" fill="#28282e" stroke="#46464e" stroke-width="1.5"/>
    <rect x="20" y="46" width="44" height="8" rx="4" fill="#5c8cff"/>
    <circle cx="64" cy="50" r="7" fill="#dedede"/>
    <rect x="20" y="64" width="34" height="18" rx="4" fill="#28282e" stroke="#46464e" stroke-width="1.5"/>
    <rect x="60" y="64" width="20" height="18" rx="9" fill="#5c8cff"/>
    <circle cx="71" cy="73" r="5" fill="#18181b"/>
    <rect x="20" y="90" width="60" height="6" rx="3" fill="#28282e"/>
    <rect x="20" y="90" width="22" height="6" rx="3" fill="#5c8cff"/>
  </svg>
</p>

<h1 align="center">moonegui</h1>

<p align="center">Immediate-mode interfaces for MoonBit: a frame is a function of your state, and what it produces is a list of shapes any backend can draw.</p>

<p align="center">
  <a href="#two-ways-to-write-one-interface">Two ways</a> ·
  <a href="#what-is-here">Packages</a> ·
  <a href="#design">Design</a> ·
  <a href="#use-it">Use it</a> ·
  <a href="#widgets">Widgets</a> ·
  <a href="https://mooncakes.io/docs/moonbitstack/moonegui">mooncakes.io</a>
</p>

---

## Two ways to write one interface

Write the frame as calls, one line per control, and read what happened to it on
the line below:

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

Or describe the interface as data — a tree of nodes, with a tag on every control
— and let the interpreter hand back what the user did:

```moonbit
let name_tag : @view.Tag = @view.Tag::new(1)

let remember_tag : @view.Tag = @view.Tag::new(2)

let save_tag : @view.Tag = @view.Tag::new(3)

fn account_tree(name : String, remember : Bool) -> Array[@view.View] {
  [
    @view.heading("Account"),
    @view.edit(name, name_tag, hint="your name"),
    @view.checkbox("Remember me", remember_tag, remember),
    @view.button("Save", save_tag),
  ]
}

fn account_step(
  ui : @ctx.Ui,
  interp : @view.Interp,
  name : String,
  remember : Bool,
) -> (String, Bool) {
  interp.show(ui, account_tree(name, remember))
  let mut name = name
  let mut remember = remember
  for event in interp.events() {
    match event {
      Edited(tag~, text~) => if tag == name_tag { name = text }
      Toggled(tag~, value~) => if tag == remember_tag { remember = value }
      Clicked(tag) => if tag == save_tag { println("saved " + name) }
      _ => ()
    }
  }
  (name, remember)
}
```

Both produce the same shapes for the same interface, down to the byte. The tree
is not a second renderer: it is a way of saying what a frame says, which is what
lets one interface be drawn on a canvas, as elements in a document, or into a
frame buffer without being written three times.

## What is here

This module is the core: the maths, the layout, the controls, the tree, and the
contract a backend answers to. There is no foreign function anywhere in it, so
it compiles and runs on `wasm`, `wasm-gc`, `js` and `native` with nothing under
it — a frame can be drawn, recorded, and read back as text without a screen.

| Package | What it does |
|:--|:--|
| `emath` | `Vec2`, `Rect`, `Align`, `Margin`, and the interpolation everything else is built from |
| `id` | Ids derived from a parent and a piece of salt, which is what connects a widget to the same widget last frame |
| `input` | The events a host hands over, folded once a frame into the state widgets ask questions of |
| `mem` | What survives a frame: focus, the widget being dragged, and a value per widget, tidied at the end of every frame |
| `paint` | Colours, strokes, fonts, and the five shapes a frame is made of |
| `layout` | Where things go: placer cursors in four directions, and the flows and bounds a tree is measured against |
| `hit` | What the pointer is over, and the `Response` a widget answers with |
| `text` | Breaking, aligning, eliding, and turning a click into a caret position |
| `ctx` | The frame itself, `Ui` — the value you spend the frame with — and the style everything is drawn in |
| `widget` | The controls, from a label to a table |
| `view` | The tree: what a node is, how big it is, and the interpreter that draws a tree and remembers what it produced |
| `back` | The backend contract: three ways to measure, nine to draw, and a recorder that writes them down |

The browser is a module of its own, [moonpane](hosts/pane/README.md), because the
two backends that draw into a page are the only part of the library that cannot
run anywhere else. It answers the same twelve functions and publishes under its
own name, with its own release tag.

| Package | What it does |
|:--|:--|
| `web` | What both browser backends share: the surface, the text metrics, and the input coming the other way |
| `canvas` | A frame painted on a 2D canvas |
| `html` | The same frame as elements in the document, for pages that want selectable text and the rest of what H5 already has |

## Design

Four decisions shape everything else.

**The core is synchronous.** `wasm-gc` has no async, and a browser cannot be
blocked, so the frame is a function the host calls — `ctx.run(raw, ui)` — rather
than a loop the library owns. Time, input and repainting are the host's.

**A backend measures and draws, nothing more.** Twelve functions, all of which a
plain 2D canvas already has. There is no triangulation, no glyph atlas and no
shader in the library, which is why the same frame reaches a canvas, the
document, and anything else willing to implement twelve functions.

**Hit testing uses the previous frame's rectangles.** This frame's widgets do not
exist yet when the pointer has to be matched to one. That is where immediate
mode's one frame delay comes from, and it is written down in the tests rather
than left to be discovered.

**A tree is data, and only what changed is built again.** Every node is a value,
so this frame's tree can be compared with the last one's. A subtree whose data is
unchanged, in the same rectangle, with nothing incoming able to touch it, is not
built again: what it drew is put back where it was. Nothing is stored in the tree
— no closures, no widget objects, no subscriptions — which is what makes the
comparison possible at all.

Layout is measured before it is drawn, because a row has to know how wide its
children are before it can say where the second one starts: rows, columns,
equal-column grids, alignment across and along the flow, gaps, padding, and
minimum and maximum sizes. The placer is still there for code that would rather
work it out as it goes.

## Use it

```bash
moon add moonbitstack/moonegui
moon add moonbitstack/moonpane   # only for a program that draws into a page
```

A frame, in full. The canvas backend is JavaScript only and lives in the host
module, so this block does not compile inside this one.

```moonbit nocheck
let canvas : @canvas.Canvas = @canvas.Canvas::new()
let context : @ctx.Ctx = @ctx.Ctx::new(canvas)
canvas.listen()
// then, once a frame:
let out = context.run(canvas.raw(now, dt), fn(ui) {
  @widget.heading(ui, "moonegui") |> ignore
  if @widget.button(ui, "Press me").clicked {
    clicks = clicks + 1
  }
  @widget.label(ui, "clicked " + clicks.to_string() + " times") |> ignore
})
canvas.clear(context.style().background)
@back.play(out.shapes, canvas)
```

`hosts/pane/src/examples/browser` is that program with every widget in it,
written both ways. To run it from the repository root:

```bash
moon build --target js
python -m http.server 8741
# http://127.0.0.1:8741/hosts/pane/src/examples/browser/index.html
# ?html for elements instead of a canvas, ?view for the tree, ?view&html for both
```

## Widgets

| Group | Functions |
|:--|:--|
| Text | `label`, `weak`, `heading`, `caption`, `hyperlink`, `badge` |
| Buttons | `button`, `accent_button`, `quiet_button` |
| Choices | `checkbox`, `radio`, `switch`, `slider`, `drag_value`, `combo`, `tabs` |
| Fields | `edit`, `text_area` |
| Containers | `panel`, `group`, `scroll_area`, `list`, `table`, `separator` |
| Motion | `progress`, `spinner` |

Every one of them is a function that takes the value it shows and returns the
value the user made of it, next to the `Response` that says what happened. A
widget holds no state of its own: a caret position, a scroll offset or a folded
section belong to the caller or to the frame's memory, never to the widget.

## Not in this version

Meshes and triangulation, glyph rasterisation, images, multiple windows and
viewports, drag and drop, animation, overlays that float above their neighbours,
and a colour picker. Text is drawn a row at a time by the backend; glyph
positions are used only for carets and selections.

## License

Apache-2.0.
