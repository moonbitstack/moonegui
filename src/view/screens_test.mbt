// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// The room a screen is laid out in.
let window : @emath.Vec2 = { x: 800, y: 600, }

///|
/// One of the ten interfaces a layout has to be able to express, with the room
/// it is expected to need.
struct Screen {
  name : String
  views : Array[@view.View]
  height : Double
}

///|
fn screens() -> Array[Screen] {
  [
    {
      name: "login",
      height: 210,
      views: [
        @view.heading("Sign in"),
        @view.edit("", @view.Tag::new(1), hint="your name", width=280),
        @view.edit("", @view.Tag::new(2), hint="your password", width=280),
        @view.checkbox("Remember me", @view.Tag::new(3), true),
        @view.row([
          @view.accent_button("Sign in", @view.Tag::new(4)),
          @view.quiet_button("Cancel", @view.Tag::new(5)),
        ]),
      ],
    },
    {
      name: "settings",
      height: 300,
      views: [
        @view.heading("Settings"),
        @view.separator(),
        @view.group(
          "Appearance",
          true,
          @view.Tag::new(6),
          @view.column([
            @view.row([
              @view.text("Text size"),
              @view.slider(@view.Tag::new(7), 0.4, width=200),
            ]),
            @view.row([
              @view.text("Dark"),
              @view.switch(@view.Tag::new(8), true),
            ]),
          ]),
        ),
        @view.group("Network", false, @view.Tag::new(9), @view.text("hidden")),
      ],
    },
    {
      name: "player",
      height: 260,
      views: [
        @view.row([@view.heading("Now playing"), @view.badge("live")]),
        @view.progress(0.35, width=420, label="two minutes in"),
        @view.row([
          @view.quiet_button("previous", @view.Tag::new(10)),
          @view.button("play", @view.Tag::new(11)),
          @view.quiet_button("next", @view.Tag::new(12)),
        ]),
        @view.list(
          ["first", "second", "third"],
          @view.Tag::new(13),
          0,
          height=80,
        ),
      ],
    },
    {
      name: "dashboard",
      height: 260,
      views: [
        @view.heading("Today"),
        @view.grid(3, [
          @view.panel(
            @view.column([@view.caption("visits"), @view.heading("1 204")]),
          ),
          @view.panel(
            @view.column([@view.caption("signups"), @view.heading("38")]),
          ),
          @view.panel(
            @view.column([@view.caption("errors"), @view.heading("2")]),
          ),
        ]),
        @view.space(6),
        @view.table(
          ["page", "visits"],
          [["/", "900"], ["/docs", "300"]],
          @view.Tag::new(14),
          0,
          width=420,
        ),
      ],
    },
    {
      name: "files",
      height: 240,
      views: [
        @view.row([
          @view.button("open", @view.Tag::new(15)),
          @view.button("copy", @view.Tag::new(16)),
          @view.quiet_button("delete", @view.Tag::new(17)),
        ]),
        @view.row([
          @view.list(
            ["notes", "src", "build"],
            @view.Tag::new(18),
            0,
            height=120,
          ),
          @view.table(
            ["name", "size"],
            [["a.mbt", "1k"], ["b.mbt", "2k"]],
            @view.Tag::new(19),
            0,
            width=300,
          ),
        ]),
      ],
    },
    {
      name: "chat",
      height: 240,
      views: [
        @view.scroll(
          @view.Tag::new(20),
          160,
          @view.column([
            @view.row([@view.weak_text("ada"), @view.text("are you there?")]),
            @view.row([@view.weak_text("leo"), @view.text("I am.")]),
            @view.row([@view.weak_text("ada"), @view.text("good.")]),
          ]),
        ),
        @view.row([
          @view.edit("", @view.Tag::new(21), hint="say something", width=400),
          @view.accent_button("send", @view.Tag::new(22)),
        ]),
      ],
    },
    {
      name: "inspector",
      height: 240,
      views: [
        @view.row([
          @view.column([
            @view.caption("outline"),
            @view.list(
              ["window", "button", "label"],
              @view.Tag::new(23),
              1,
              height=100,
            ),
          ]),
          @view.column([
            @view.caption("properties"),
            @view.grid_with(2, @view.row_flow.with_gap(6), [
              @view.text("x"),
              @view.drag_value(@view.Tag::new(24), 12),
              @view.text("y"),
              @view.drag_value(@view.Tag::new(25), 40),
            ]),
          ]),
        ]),
      ],
    },
    {
      name: "wizard",
      height: 230,
      views: [
        @view.tabs(["name", "address", "confirm"], @view.Tag::new(26), 1),
        @view.space(6),
        @view.column([
          @view.text("Where should it be sent?"),
          @view.text_area("", @view.Tag::new(27), rows=3, width=360),
        ]),
        @view.space(6),
        @view.row_with(@view.row_flow.with_justify(SpaceBetween), [
          @view.quiet_button("back", @view.Tag::new(28)),
          @view.accent_button("next", @view.Tag::new(29)),
        ]),
      ],
    },
    {
      name: "keypad",
      height: 320,
      views: [
        @view.row([@view.heading("0"), @view.spinner(0.5)]),
        @view.grid(4, [
          @view.button("7", @view.Tag::new(30)),
          @view.button("8", @view.Tag::new(31)),
          @view.button("9", @view.Tag::new(32)),
          @view.button("/", @view.Tag::new(33)),
          @view.button("4", @view.Tag::new(34)),
          @view.button("5", @view.Tag::new(35)),
          @view.button("6", @view.Tag::new(36)),
          @view.button("*", @view.Tag::new(37)),
          @view.button("1", @view.Tag::new(38)),
          @view.button("2", @view.Tag::new(39)),
          @view.button("3", @view.Tag::new(40)),
          @view.button("-", @view.Tag::new(41)),
          @view.button("0", @view.Tag::new(42)),
          @view.button(".", @view.Tag::new(43)),
          @view.button("=", @view.Tag::new(44)),
          @view.button("+", @view.Tag::new(45)),
        ]),
      ],
    },
    {
      name: "board",
      height: 260,
      views: [
        @view.row([
          @view.panel(
            @view.column([
              @view.caption("to do"),
              @view.text("write the parser"),
              @view.text("draw the icon"),
            ]),
            title="2",
          ),
          @view.panel(
            @view.column([@view.caption("doing"), @view.text("the layout")]),
            title="1",
          ),
          @view.panel(
            @view.column([
              @view.caption("done"),
              @view.text("the frame"),
              @view.text("the recorder"),
              @view.text("the canvas"),
            ]),
            title="3",
          ),
        ]),
      ],
    },
  ]
}

///|
/// Ten real interfaces, laid out and drawn: what a layout has to be able to say
/// is decided by whether these can be written at all.
test "ten interfaces fit the window and draw the same twice" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let all = screens()
  assert_eq(all.length(), 10)
  for screen in all {
    // Each screen is named once, so a failure says which one.
    let mut same = 0
    for other in all {
      if other.name == screen.name {
        same = same + 1
      }
    }
    assert_eq(same, 1)
    let root = screen.views
    let mut size = @emath.zero
    ctx.run(@input.Raw::new(@emath.Rect::at(@emath.zero, window)), fn(ui) {
      let mut tall = 0.0
      let mut wide = 0.0
      for view in root {
        let each = view.size(ui, room=window)
        tall = tall + each.y
        if each.x > wide {
          wide = each.x
        }
      }
      size = { x: wide, y: tall, }
    })
    |> ignore
    assert_true(size.x <= window.x)
    // A screen may be taller than the window — a form scrolls — but not by
    // more than the height it was written to need.
    assert_true(size.y <= screen.height + 60)
    let first = stage()
    let drawn = first.draw([], root)
    let second = first.draw([], root)
    assert_eq(second, drawn)
    assert_true(drawn.contains("\""))
  }
}

///|
test "a row of buttons puts them where a frame would, clips aside" {
  let rec = @back.Rec::new()
  let ctx = @ctx.Ctx::new(rec)
  let out = ctx.run(@input.Raw::new(screen), fn(ui) {
    ui.horizontal(fn(row) {
      @widget.button(row, "Save") |> ignore
      @widget.button(row, "Cancel") |> ignore
    })
    |> ignore
  })
  rec.clear()
  @back.play(out.shapes, rec)
  let by_hand = without_clips(rec.lines())
  let s = stage()
  let by_tree = s.lines([], [
    @view.row([
      @view.button("Save", @view.Tag::new(1)),
      @view.button("Cancel", @view.Tag::new(2)),
    ]),
  ])
  assert_eq(by_tree, by_hand)
}

///|
/// The commands of a frame without the clip a region carries.
///
/// A region in a frame clips what is put in it, and a tree's cells do not: the
/// tree knows each rectangle before it draws, so there is nothing to clip to.
/// The outlines themselves land in the same places, which is what this compares.
fn without_clips(lines : Array[String]) -> Array[String] {
  let out : Array[String] = []
  for line in lines {
    if line.has_prefix("clip ") || line == "unclip" {
      continue
    }
    out.push(line)
  }
  out
}
