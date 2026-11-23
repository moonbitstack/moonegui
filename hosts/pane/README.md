<!-- Copyright 2026 Leo Cheng -->

# moonpane

The browser host for [moonegui](https://github.com/moonbitstack/moonegui): a
frame laid out by the library, drawn by a page.

`moonpane` is one implementation of the backend contract — three ways to measure
text and nine to draw — with two ways of drawing it. A frame can go onto a 2D
canvas, or into the document as elements. Both are the same shapes in the same
places, so a program can be moved from one to the other by changing one line,
and a page gets selectable text, zoom and screen readers for nothing.

JavaScript only: both backends call into the browser, and the module declares
that rather than shipping a stub for a target it cannot draw on.

## What is here

| Package | What it does |
|:--:|:--|
| `web` | What both backends share: the surface, its size and pixel ratio, the text metrics, and the input coming the other way |
| `canvas` | A frame painted on a 2D context: rectangles, circles, paths and rows of text |
| `html` | The same frame as elements in the document: a `div` per shape, an `svg` per path, a row of text per row |

## Install

```bash
moon add moonbitstack/moonpane
```

Both backends implement `moonbitstack/moonegui/back`, which comes with the
library the frames are built by.

## Use it

A page has one element for the surface, and the element has an id:

```html
<canvas id="moonegui" tabindex="0"></canvas>
```

`Canvas::new()` takes over the element with that id; pass `id=` for another.
Then a frame is four steps: listen, run, clear, play.

```moonbit
let surface : @canvas.Canvas = @canvas.Canvas::new()
let context = @ctx.Ctx::new(surface)
surface.listen()
let out = context.run(surface.raw(now, dt), fn(ui) {
  @widget.heading(ui, "moonpane") |> ignore
  if @widget.button(ui, "Press me").clicked {
    clicks = clicks + 1
  }
})
surface.clear(context.style().background)
@back.play(out.shapes, surface)
```

The same program as elements differs in three lines: the surface is an `Html`, a
frame is opened with the background colour, and it is closed once the shapes are
in. Elements are reused from the frame before whenever the kind matches, so a
still interface changes nothing in the document.

```moonbit
let surface : @html.Html = @html.Html::new()
let context = @ctx.Ctx::new(surface)
surface.listen()
let out = context.run(surface.raw(now, dt), fn(ui) {
  @widget.heading(ui, "moonpane") |> ignore
})
surface.begin(context.style().background)
@back.play(out.shapes, surface)
surface.end()
```

The imports that go with either:

```moonbit
import {
  "moonbitstack/moonegui/back",
  "moonbitstack/moonegui/ctx",
  "moonbitstack/moonegui/widget",
  "moonbitstack/moonpane/canvas",
}
```

## What each backend answers

| | `canvas` | `html` |
|:--|:--|:--|
| A rectangle | one `fillRect` | one `div` |
| A circle | one arc | one `div` with a round border |
| A path | a few `lineTo` | one `svg` over the page |
| A row of text | `fillText` | one `div` the browser lays out |
| Text selection | no | yes, the document's own |
| Reuse between frames | the canvas is repainted | elements are re-used by kind |
| Cost | one surface | one element per shape |

Both measure through the same code, in a canvas kept aside for the purpose, so a
page laid out for one is laid out for the other.

## Input

The browser's events are flattened into lines of text before they cross into
MoonBit — `m 12 40` for a move, `d 12 40 0 4` for a press with `shift` — because
a line needs no marshalling on either side. `@web.raw(time, dt)` reads the queue
that piled up since the last frame and turns it into the events the library
folds into a frame. The pointer leaving the surface, the surface gaining and
losing the keyboard, and pasted text are events of their own.

## The demo

`src/examples/browser` is every widget on one page, drawn both ways and written
both ways: as calls and as a tree. From the repository root:

```bash
moon build --target js
python -m http.server 8741
# open http://127.0.0.1:8741/hosts/pane/src/examples/browser/index.html
# ?html for elements instead of a canvas, ?view for the tree,
# ?view&html for the tree as elements
```

## License

Apache-2.0.
