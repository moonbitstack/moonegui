// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// The same demonstration, written as a tree instead of as a sequence of calls.
///
/// The state is still the caller's: the tree says what the interface looks like
/// for a given state, the interpreter says what the user did to it, and `apply`
/// is the only place the state changes.
priv struct Board {
  mut tab : Int32
  mut name : String
  mut ticked : Bool
  mut size : Double
  mut chosen : Int32
  mut line : Int32
  mut open : Bool
  mut menu : Int32
  mut unfolded : Bool
  mut work : Double
}

///|
let board : Board = {
  tab: 0,
  name: "",
  ticked: true,
  size: 0.35,
  chosen: 0,
  line: 0,
  open: true,
  menu: 1,
  unfolded: false,
  work: 0.4,
}

///|
let tab_tag : @view.Tag = @view.Tag::new(1)

///|
let name_tag : @view.Tag = @view.Tag::new(2)

///|
let tick_tag : @view.Tag = @view.Tag::new(3)

///|
let size_tag : @view.Tag = @view.Tag::new(4)

///|
let list_tag : @view.Tag = @view.Tag::new(5)

///|
let table_tag : @view.Tag = @view.Tag::new(6)

///|
let group_tag : @view.Tag = @view.Tag::new(7)

///|
let menu_tag : @view.Tag = @view.Tag::new(8)

///|
let less : @view.Tag = @view.Tag::new(9)

///|
let more : @view.Tag = @view.Tag::new(10)

///|
/// What the page looks like for this state.
fn pages(state : Board) -> Array[@view.View] {
  [
    @view.heading("moonegui"),
    @view.weak_text("One tree, drawn on a canvas or as elements."),
    @view.separator(),
    @view.tabs(["Form", "List", "About"], tab_tag, state.tab),
    @view.space(4),
    match state.tab {
      0 => form(state)
      1 => listing(state)
      _ => about()
    },
  ]
}

///|
fn form(state : Board) -> @view.View {
  @view.column([
    @view.edit(state.name, name_tag, hint="type here", width=260),
    @view.checkbox("Ticked", tick_tag, state.ticked),
    @view.row([
      @view.text("Text size"),
      @view.slider(size_tag, state.size, low=0.0, high=1.0, width=160),
    ]),
    @view.row([@view.button("Less", less), @view.button("More", more)]),
    @view.progress(state.work, width=260, label="progress"),
  ])
}

///|
fn listing(state : Board) -> @view.View {
  @view.column([
    @view.list(["alpha", "beta", "gamma", "delta"], list_tag, state.chosen),
    @view.space(4),
    @view.table(
      ["name", "size"],
      [["alpha", "12"], ["beta", "48"], ["gamma", "7"]],
      table_tag,
      state.line,
      width=260,
    ),
    @view.space(4),
    @view.group(
      "More",
      state.open,
      group_tag,
      @view.column([
        @view.text("A section that folds away."),
        @view.hyperlink("a link", @view.Tag::new(11)),
      ]),
    ),
  ])
}

///|
fn about() -> @view.View {
  @view.column([
    @view.combo(
      ["one", "two", "three"],
      menu_tag,
      board.menu,
      open=board.unfolded,
      width=200,
    ),
    @view.space(4),
    @view.row([
      @view.badge("stable"),
      @view.spinner(0.25),
      @view.weak_text("something is happening"),
    ]),
    @view.space(4),
    @view.scroll(
      @view.Tag::new(12),
      60,
      @view.column([
        @view.text("A line in a scrolling region."),
        @view.text("Another line."),
        @view.text("And a third one, below the window."),
      ]),
    ),
  ])
}

///|
/// The only place the state changes.
fn apply(event : @view.Event) -> Unit {
  match event {
    Chosen(tag~, at~) =>
      if tag == tab_tag {
        board.tab = at
      } else if tag == list_tag {
        board.chosen = at
      } else if tag == table_tag {
        board.line = at
      } else if tag == menu_tag {
        board.menu = at
        board.unfolded = false
      }
    Edited(tag~, text~) => if tag == name_tag { board.name = text }
    Toggled(tag~, value~) => if tag == tick_tag { board.ticked = value }
    Moved(tag~, value~) => if tag == size_tag { board.size = value }
    Opened(tag~, open~) =>
      if tag == group_tag {
        board.open = open
      } else if tag == menu_tag {
        board.unfolded = open
      }
    Clicked(tag) =>
      if tag == less {
        board.work = @emath.clamp(board.work - 0.1, 0, 1)
      } else if tag == more {
        board.work = @emath.clamp(board.work + 0.1, 0, 1)
      }
  }
}

///|
/// Draw one frame of the tree into a surface.
fn draw(
  context : @ctx.Ctx,
  interp : @view.Interp,
  raw : @input.Raw,
) -> @ctx.Output {
  let out = context.run(raw, fn(ui) { interp.show(ui, pages(board)) })
  for event in interp.events() {
    apply(event)
  }
  out
}

///|
/// The tree, drawn on a canvas.
pub fn start_view() -> Unit {
  let canvas : @canvas.Canvas = @canvas.Canvas::new()
  let context = @ctx.Ctx::new(canvas)
  let interp = @view.Interp::new()
  canvas.listen()
  let mut last = @web.now()
  frames(fn() {
    let now = @web.now()
    let dt = now - last
    last = now
    let out = draw(context, interp, canvas.raw(now, dt))
    canvas.clear(context.style().background)
    @back.play(out.shapes, canvas)
  })
}

///|
/// The same tree, drawn as elements in the document.
pub fn start_view_html() -> Unit {
  let page : @html.Html = @html.Html::new()
  let context = @ctx.Ctx::new(page)
  let interp = @view.Interp::new()
  page.listen()
  let mut last = @web.now()
  frames(fn() {
    let now = @web.now()
    let dt = now - last
    last = now
    let out = draw(context, interp, page.raw(now, dt))
    page.begin(context.style().background)
    @back.play(out.shapes, page)
    page.end()
  })
}
