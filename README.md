<!-- Copyright 2026 Leo Cheng -->

# moonegui

[![check and test](https://github.com/moonbitstack/moonegui/actions/workflows/ci.yml/badge.svg)](https://github.com/moonbitstack/moonegui/actions/workflows/ci.yml)

An immediate mode graphical interface for MoonBit, after [egui](https://github.com/emilk/egui).

An interface here is a function of your state, called once a frame. There is no
widget tree to keep in step with anything, no callbacks and no subscriptions:
you ask for a button and are told whether it was clicked, on the line below.

```moonbit
if @widget.button(ui, "Press me").clicked {
  clicks = clicks + 1
}
clicks_shown = @widget.slider(ui, clicks_shown, low=0, high=10).0
name = @widget.edit(ui, name, hint="your name").0
```

## What is here

| Package | What it does |
|:--:|:--|
| `emath` | `Vec2`, `Rect`, `Align`, `Margin`, and the interpolation everything else is built from |
| `id` | Ids derived from a parent and a piece of salt, which is what connects a widget to the same widget last frame |
| `input` | The events a host hands over, folded once a frame into the state widgets ask questions of |
| `mem` | What survives a frame: focus, the widget being dragged, and a value per widget, tidied at the end of every frame |
| `paint` | Colours, strokes, fonts, and the five shapes a frame is made of |
| `layout` | Placers: where the next widget goes, in four directions, aligned or stretched across the flow |
| `hit` | What the pointer is over, and the `Response` a widget answers with |
| `text` | Breaking, aligning, eliding, and turning a click into a caret position |
| `ctx` | The frame itself, and `Ui` — the value you spend the frame with |
| `widget` | Label, heading, separator, button, checkbox, radio, slider and text field |
| `back` | The backend contract: three ways to measure, nine to draw, and a recorder that writes them down |
| `back/web` | What both browser backends share: the surface, the text metrics, and the input coming the other way |
| `back/canvas` | A frame painted on a 2D canvas |
| `back/html` | The same frame as elements in the document, for pages that want selectable text and the rest of what H5 already has |

## Design

Three decisions shape everything else.

**The core is synchronous.** `wasm-gc` has no async, and a browser cannot be
blocked, so the frame is a function the host calls — `ctx.run(raw, ui)` — rather
than a loop the library owns.

**A backend measures and draws, nothing more.** Twelve functions, all of which a
plain 2D canvas already has. There is no triangulation, no glyph atlas and no
shader anywhere in the library, and adding a backend is an afternoon — which is
how the same frame reaches both a canvas and the document itself, measured by
one piece of code so that the two lay out identically.

**Hit testing uses the previous frame's rectangles.** This frame's widgets do
not exist yet when the pointer has to be matched to one. That is where immediate
mode's one frame delay comes from, and it is written down in the tests rather
than left to be discovered.

## Use it

```json
{ "deps": { "moonbitstack/moonegui": "0.1.0" } }
```

A frame, in full:

```moonbit
let canvas : @canvas.Canvas = @canvas.Canvas::new()
let context = @ctx.Ctx::new(canvas)
canvas.listen()
// then, once a frame:
let out = context.run(canvas.raw(now, dt), fn(ui) {
  @widget.heading(ui, "moonegui") |> ignore
  if @widget.button(ui, "Press me").clicked {
    clicks = clicks + 1
  }
})
canvas.clear(context.style().background)
@back.play(out.shapes, canvas)
```

`examples/browser` is that program, with every widget in it. To run it:

```bash
moon build --target js
python -m http.server 8741
# then open http://127.0.0.1:8741/examples/browser/index.html
# and the same page as elements: .../index.html?html
```

## Tests

177 tests, run on all four backends. The recording backend turns a frame into a
list of text commands, so a test compares drawing to a string and needs no
screen, no font file and no browser. Its font is deliberately regular — every
character the same width — which is what lets a test work out the expected
numbers by hand.

```bash
moon check --target all --deny-warn
moon test --target all
```

Numbers reaching a snapshot are printed as sixty-fourths, since a floating point
number does not print the same on every backend.

## Not in this version

Meshes and triangulation, glyph rasterisation, images, multiple windows and
viewports, drag and drop, animation, and a colour picker. Text is drawn a row at
a time by the backend; glyph positions are used only for carets and selections.

## License

Apache-2.0.
