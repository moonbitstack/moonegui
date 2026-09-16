// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
let screen : @emath.Rect = @emath.Rect::of({ x: 0, y: 0, }, { x: 200, y: 100, })

///|
let ink : @paint.Color = @paint.Color::rgb(200, 30, 30)

///|
fn frame(events : Array[@input.Event], time? : Double = 0) -> @input.Raw {
  { screen, events, time, dt: 0.016, focused: true, }
}

///|
fn at(x : Double, y : Double) -> @emath.Vec2 {
  { x, y, }
}

///|
/// A press and a release in the same place, which is a click.
fn tap(x : Double, y : Double) -> Array[@input.Event] {
  [
    PointerMoved(at(x, y)),
    PointerButton(at=at(x, y), btn=Primary, down=true, mods=@input.none),
    PointerButton(at=at(x, y), btn=Primary, down=false, mods=@input.none),
  ]
}

///|
fn tab(shift? : Bool = false) -> Array[@input.Event] {
  [KeyDown(key=Tab, mods={ ctrl: false, alt: false, shift, }, repeat=false)]
}

///|
test "a widget cannot be clicked on the frame it first appears" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let mut clicked = false
  let build = fn(ui : @ctx.Ui) {
    let (_, response) = ui.allocate({ x: 80, y: 20, }, @hit.click, "ok")
    clicked = response.clicked
  }
  ctx.run(frame(tap(10, 10)), build) |> ignore
  assert_false(clicked)
  ctx.run(frame(tap(10, 10), time=1), build) |> ignore
  assert_true(clicked)
}

///|
test "what the pointer is over comes from where things were last frame" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let mut hovered = false
  let mut id = @id.nothing
  let build = fn(ui : @ctx.Ui) {
    let (_, response) = ui.allocate({ x: 80, y: 20, }, @hit.click, "ok")
    hovered = response.hovered
    id = response.id
  }
  ctx.run(frame([PointerMoved(at(10, 10))]), build) |> ignore
  assert_false(hovered)
  assert_true(ctx.hovered().is_nothing())
  ctx.run(frame([]), build) |> ignore
  assert_true(hovered)
  assert_eq(ctx.hovered(), id)
}

///|
test "the pointer somewhere else is over nothing" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let build = fn(ui : @ctx.Ui) {
    ui.allocate({ x: 20, y: 20, }, @hit.click, "ok") |> ignore
  }
  ctx.run(frame([PointerMoved(at(150, 90))]), build) |> ignore
  ctx.run(frame([]), build) |> ignore
  assert_true(ctx.hovered().is_nothing())
}

///|
test "clicking a widget gives it the keyboard" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let mut id = @id.nothing
  let build = fn(ui : @ctx.Ui) {
    let (_, response) = ui.allocate({ x: 80, y: 20, }, @hit.click, "ok")
    id = response.id
  }
  ctx.run(frame([PointerMoved(at(10, 10))]), build) |> ignore
  ctx.run(frame(tap(10, 10), time=1), build) |> ignore
  assert_eq(ctx.focused(), id)
}

///|
test "pressing the background takes the keyboard away again" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let build = fn(ui : @ctx.Ui) {
    ui.allocate({ x: 80, y: 20, }, @hit.click, "ok") |> ignore
  }
  ctx.run(frame([PointerMoved(at(10, 10))]), build) |> ignore
  ctx.run(frame(tap(10, 10), time=1), build) |> ignore
  assert_false(ctx.focused().is_nothing())
  ctx.run(frame(tap(180, 90), time=2), build) |> ignore
  assert_true(ctx.focused().is_nothing())
}

///|
test "tab walks the widgets in the order they were built" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let ids : Array[@id.Id] = []
  let build = fn(ui : @ctx.Ui) {
    ids.clear()
    for name in ["one", "two", "three"] {
      let (_, response) = ui.allocate({ x: 40, y: 20, }, @hit.click, name)
      ids.push(response.id)
    }
  }
  ctx.run(frame([]), build) |> ignore
  assert_true(ctx.focused().is_nothing())
  ctx.run(frame(tab()), build) |> ignore
  assert_eq(ctx.focused(), ids[0])
  ctx.run(frame(tab()), build) |> ignore
  assert_eq(ctx.focused(), ids[1])
  ctx.run(frame(tab()), build) |> ignore
  assert_eq(ctx.focused(), ids[2])
  ctx.run(frame(tab()), build) |> ignore
  assert_eq(ctx.focused(), ids[0])
}

///|
test "shift and tab walks them backwards" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let ids : Array[@id.Id] = []
  let build = fn(ui : @ctx.Ui) {
    ids.clear()
    for name in ["one", "two", "three"] {
      let (_, response) = ui.allocate({ x: 40, y: 20, }, @hit.click, name)
      ids.push(response.id)
    }
  }
  ctx.run(frame([]), build) |> ignore
  ctx.run(frame(tab(shift=true)), build) |> ignore
  assert_eq(ctx.focused(), ids[2])
  ctx.run(frame(tab(shift=true)), build) |> ignore
  assert_eq(ctx.focused(), ids[1])
}

///|
test "a widget that cannot be interacted with is not in the focus ring" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let mut second = @id.nothing
  let build = fn(ui : @ctx.Ui) {
    ui.allocate({ x: 40, y: 20, }, @hit.inert, "label") |> ignore
    let (_, response) = ui.allocate({ x: 40, y: 20, }, @hit.click, "ok")
    second = response.id
  }
  ctx.run(frame([]), build) |> ignore
  ctx.run(frame(tab()), build) |> ignore
  assert_eq(ctx.focused(), second)
}

///|
test "a widget that has gone takes its state and its focus with it" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let full = fn(ui : @ctx.Ui) {
    let (_, response) = ui.allocate({ x: 40, y: 20, }, @hit.click, "ok")
    ui.ctx().memory().set(response.id, Num(5))
  }
  ctx.run(frame([]), full) |> ignore
  ctx.run(frame(tab()), full) |> ignore
  assert_eq(ctx.memory().count(), 1)
  assert_false(ctx.focused().is_nothing())
  ctx.run(frame([]), fn(_ui) {  }) |> ignore
  assert_eq(ctx.memory().count(), 0)
  assert_true(ctx.focused().is_nothing())
}

///|
test "two widgets with the same label are still two widgets" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let ids : Array[@id.Id] = []
  ctx.run(frame([]), fn(ui) {
    for _ in 0..<3 {
      let (_, response) = ui.allocate({ x: 40, y: 20, }, @hit.click, "same")
      ids.push(response.id)
    }
  })
  |> ignore
  assert_not_eq(ids[0], ids[1])
  assert_not_eq(ids[1], ids[2])
}

///|
test "the same widget keeps its id from frame to frame" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let ids : Array[@id.Id] = []
  let build = fn(ui : @ctx.Ui) {
    let (_, response) = ui.allocate({ x: 40, y: 20, }, @hit.click, "ok")
    ids.push(response.id)
  }
  ctx.run(frame([]), build) |> ignore
  ctx.run(frame([]), build) |> ignore
  assert_eq(ids[0], ids[1])
}

///|
test "a frame is counted, and a repaint is asked for only when it is" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let quiet = ctx.run(frame([]), fn(_ui) {  })
  assert_eq(ctx.frame(), 1)
  assert_false(quiet.repaint)
  let busy = ctx.run(frame([]), fn(ui) { ui.ctx().request_repaint() })
  assert_eq(ctx.frame(), 2)
  assert_true(busy.repaint)
  let after = ctx.run(frame([]), fn(_ui) {  })
  assert_false(after.repaint)
}

///|
test "a frame's shapes are the caller's, not the next frame's" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let first = ctx.run(frame([]), fn(ui) {
    ui.painter().rect(@emath.Rect::of(at(0, 0), at(10, 10)), fill=ink)
  })
  assert_eq(first.shapes.length(), 1)
  ctx.run(frame([]), fn(_ui) {  }) |> ignore
  assert_eq(first.shapes.length(), 1)
}

///|
test "a frame plays back as the commands a backend is given" {
  let rec = @back.Rec::new()
  let ctx = @ctx.Ctx::new(rec)
  let out = ctx.run(frame([]), fn(ui) {
    let (rect, _) = ui.allocate({ x: 60, y: 20, }, @hit.click, "ok")
    ui.painter().rect(rect, fill=ink, corner=@paint.Corner::same(4))
    let galley : @paint.Galley = {
      rows: [{ text: "ok", at: @emath.zero, }],
      size: { x: 14, y: 17.5, },
      font: ui.style().font,
    }
    ui.painter().galley(rect.min, galley, ink)
  })
  @back.play(out.shapes, rec)
  inspect(
    rec.text(),
    content=(
      #|fill_rect (0,0)-(60,20) round=4,4,4,4 #c81e1e
      #|text (0,0) sans/14 #c81e1e "ok"
    ),
  )
}

///|
test "a region inside another is clipped to it" {
  let rec = @back.Rec::new()
  let ctx = @ctx.Ctx::new(rec)
  let out = ctx.run(frame([]), fn(ui) {
    ui.child(
      @layout.top_down,
      fn(inside) {
        inside.painter().rect(@emath.Rect::of(at(0, 0), at(500, 20)), fill=ink)
      },
      size=Some({ x: 50, y: 40, }),
    )
    |> ignore
  })
  @back.play(out.shapes, rec)
  inspect(
    rec.text(),
    content=(
      #|clip (0,0)-(50,40)
      #|fill_rect (0,0)-(500,20) #c81e1e
      #|unclip
    ),
  )
}

///|
test "a row lays its widgets out across, a column down" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let places : Array[@emath.Rect] = []
  ctx.run(frame([]), fn(ui) {
    ui.horizontal(fn(row) {
      for name in ["a", "b"] {
        let (rect, _) = row.allocate({ x: 30, y: 20, }, @hit.click, name)
        places.push(rect)
      }
    })
    |> ignore
    let (below, _) = ui.allocate({ x: 30, y: 20, }, @hit.click, "c")
    places.push(below)
  })
  |> ignore
  assert_eq(places[0], @emath.Rect::of(at(0, 0), at(30, 20)))
  assert_eq(places[1], @emath.Rect::of(at(38, 0), at(68, 20)))
  assert_eq(places[2].min.y, 26)
}

///|
test "a gap moves the cursor without taking a widget's place" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let mut rect = @emath.nothing
  ctx.run(frame([]), fn(ui) {
    ui.gap(20)
    let (place, _) = ui.allocate({ x: 30, y: 20, }, @hit.click, "a")
    rect = place
  })
  |> ignore
  assert_eq(rect.min.y, 26)
}

///|
test "a panel draws behind what is built inside it" {
  let rec = @back.Rec::new()
  let ctx = @ctx.Ctx::new(rec)
  let out = ctx.run(frame([]), fn(ui) {
    ui.panel(
      fn(inside) {
        let (rect, _) = inside.allocate({ x: 20, y: 10, }, @hit.click, "a")
        inside.painter().rect(rect, fill=ink)
      },
      size=Some({ x: 60, y: 40, }),
    )
    |> ignore
  })
  @back.play(out.shapes, rec)
  inspect(
    rec.text(),
    content=(
      #|fill_rect (0,0)-(60,40) round=4,4,4,4 #18181b
      #|stroke_rect (0,0)-(60,40) round=4,4,4,4 #46464e w=1
      #|fill_rect (8,8)-(28,18) #c81e1e
    ),
  )
}

///|
test "a region built with interaction off cannot be interacted with" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let mut response = @hit.Response::none(@id.nothing, @emath.nothing)
  let mut enabled = true
  let build = fn(ui : @ctx.Ui) {
    ui.child(@layout.top_down, fn(inside) {
      inside.disable()
      enabled = inside.is_enabled()
      let (_, answer) = inside.allocate({ x: 80, y: 20, }, @hit.click, "ok")
      response = answer
    })
    |> ignore
  }
  ctx.run(frame([PointerMoved(at(10, 10))]), build) |> ignore
  ctx.run(frame(tap(10, 10), time=1), build) |> ignore
  assert_false(enabled)
  assert_false(response.enabled)
  assert_false(response.hovered)
  assert_false(response.clicked)
}

///|
test "how much room is left shrinks as widgets are placed" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  let mut before = @emath.zero
  let mut after = @emath.zero
  let mut used = @emath.nothing
  ctx.run(frame([]), fn(ui) {
    before = ui.available()
    ui.allocate({ x: 30, y: 20, }, @hit.click, "a") |> ignore
    after = ui.available()
    used = ui.used()
  })
  |> ignore
  assert_eq(before, { x: 200, y: 100, })
  assert_eq(after, { x: 200, y: 74, })
  assert_eq(used, @emath.Rect::of(at(0, 0), at(30, 20)))
}

///|
test "the style can be swapped for another" {
  let ctx = @ctx.Ctx::new(@back.Rec::new())
  assert_eq(ctx.style(), @ctx.dark)
  ctx.set_style(@ctx.light)
  assert_eq(ctx.style().background, @ctx.light.background)
  let mut seen = @ctx.dark
  ctx.run(frame([]), fn(ui) { seen = ui.style() }) |> ignore
  assert_eq(seen, @ctx.light)
}

///|
test "a widget's look follows what is happening to it" {
  let style = @ctx.dark
  let plain = @hit.Response::none(@id.nothing, @emath.nothing)
  assert_eq(style.fill_for(plain), style.surface)
  assert_eq(style.fill_for({ ..plain, hovered: true, }), style.hovered)
  assert_eq(style.fill_for({ ..plain, pressed: true, }), style.active)
  assert_eq(
    style.fill_for({ ..plain, enabled: false, hovered: true, }),
    style.surface,
  )
  assert_eq(style.text_for(plain), style.text)
  assert_eq(style.text_for({ ..plain, enabled: false, }), style.weak_text)
  assert_eq(style.outline_for(plain), style.outline)
  assert_eq(style.outline_for({ ..plain, focused: true, }).color, style.accent)
}

///|
test "a measurement is the backend's answer, whatever the backend is" {
  let rec = @back.Rec::new(advance=0.5, height=1.25)
  let ctx = @ctx.Ctx::new(rec)
  let mut body = @emath.zero
  let mut height = 0.0
  let mut small = 0.0
  ctx.run(frame([]), fn(ui) {
    body = ui.measure("abcd")
    height = ui.line_height()
    small = ui.measure("abcd", font=Some({ size: 10, family: Mono, })).x
  })
  |> ignore
  assert_eq(body, { x: 28, y: 17.5, })
  assert_eq(height, 17.5)
  assert_eq(small, 20)
}
