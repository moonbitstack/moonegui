// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Everything the interface remembers between frames.
///
/// The state is the caller's, not the library's: a widget takes the old value
/// and gives back the new one, and this is where the new one is kept.
priv struct Demo {
  mut ticked : Bool
  mut wrapped : Bool
  mut size : Double
  mut name : String
  mut clicks : Int
  mut theme : Bool
}

///|
let demo : Demo = {
  ticked: true,
  wrapped: false,
  size: 0.35,
  name: "",
  clicks: 0,
  theme: true,
}

///|
/// Draw one frame of the demonstration.
fn ui(root : @ctx.Ui) -> Unit {
  root.panel(fn(page) {
    @widget.heading(page, "moonegui") |> ignore
    @widget.weak(
      page, "An immediate mode interface, on a canvas or as elements.",
    )
    |> ignore
    @widget.separator(page) |> ignore
    page.horizontal(fn(row) {
      if @widget.button(row, "Press me").clicked {
        demo.clicks = demo.clicks + 1
      }
      if @widget.accent_button(row, "Reset").clicked {
        demo.clicks = 0
      }
      @widget.label(row, "clicked " + demo.clicks.to_string() + " times")
      |> ignore
    })
    |> ignore
    page.gap(4)
    page.horizontal(fn(row) {
      demo.ticked = @widget.checkbox(row, "Ticked", demo.ticked).0
      demo.wrapped = @widget.checkbox(row, "Wrap the paragraph", demo.wrapped).0
    })
    |> ignore
    page.horizontal(fn(row) {
      let (dark, _) = @widget.radio(row, "Dark", demo.theme)
      let (light, _) = @widget.radio(row, "Light", !demo.theme)
      if dark && !demo.theme {
        demo.theme = true
      }
      if light && demo.theme {
        demo.theme = false
      }
    })
    |> ignore
    page.gap(4)
    demo.size = @widget.slider_with_label(page, "Text size", demo.size).0
    page.gap(4)
    @widget.label(page, "Your name") |> ignore
    demo.name = @widget.edit(page, demo.name, hint="type here", width=260).0
    page.gap(4)
    let greeting = if demo.name == "" {
      "Nobody has been greeted yet."
    } else {
      "Hello, " + demo.name + "."
    }
    @widget.label(page, greeting) |> ignore
    if demo.ticked {
      @widget.label(
        page,
        "This paragraph is here to show how a long piece of text is broken into rows when it is wider than the region it is drawn in, and left on one row when it is not.",
        wrap=demo.wrapped,
      )
      |> ignore
    }
  })
  |> ignore
}

///|
/// Hand the host a frame at a time, drawing on a canvas.
///
/// The loop belongs to the browser: `requestAnimationFrame` calls in, the
/// library builds the interface and gives back a list of shapes, and this plays
/// them onto the canvas. Nothing in the library is asynchronous.
pub fn start() -> Unit {
  let canvas : @canvas.Canvas = @canvas.Canvas::new()
  let context = @ctx.Ctx::new(canvas)
  canvas.listen()
  let mut last = @web.now()
  frames(fn() {
    let now = @web.now()
    let dt = now - last
    last = now
    dress(context)
    let out = context.run(canvas.raw(now, dt), ui)
    canvas.clear(context.style().background)
    @back.play(out.shapes, canvas)
  })
}

///|
/// The same interface, drawn as elements in the document instead.
///
/// Only the backend changes: the frame, the widgets and the state are the same
/// code, which is the point of keeping a frame a list of shapes.
pub fn start_html() -> Unit {
  let page : @html.Html = @html.Html::new()
  let context = @ctx.Ctx::new(page)
  page.listen()
  let mut last = @web.now()
  frames(fn() {
    let now = @web.now()
    let dt = now - last
    last = now
    dress(context)
    let out = context.run(page.raw(now, dt), ui)
    page.begin(context.style().background)
    @back.play(out.shapes, page)
    page.end()
  })
}

///|
/// The style this frame is drawn with, which the demonstration itself chooses.
fn dress(context : @ctx.Ctx) -> Unit {
  context.set_style(if demo.theme { @ctx.dark } else { @ctx.light })
  let style = context.style()
  let font : @paint.FontId = {
    ..style.font,
    size: @emath.lerp(11, 22, demo.size),
  }
  context.set_style({ ..style, font, })
}

///|
extern "js" fn frames(body : () -> Unit) -> Unit =
  #| (body) => {
  #|   const tick = () => { body(); requestAnimationFrame(tick); };
  #|   requestAnimationFrame(tick);
  #| }
