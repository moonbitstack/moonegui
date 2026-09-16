// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
let screen : @emath.Rect = @emath.Rect::of({ x: 0, y: 0, }, { x: 100, y: 100, })

///|
let one : @id.Id = @id.root("one")

///|
let two : @id.Id = @id.root("two")

///|
fn box(x : Double, y : Double) -> @emath.Rect {
  @emath.Rect::of({ x, y, }, { x: x + 20, y: y + 20, })
}

///|
fn widget(
  id : @id.Id,
  rect : @emath.Rect,
  sense? : @hit.Sense = @hit.click,
  enabled? : Bool = true,
  layer? : Int = 0,
) -> @hit.WidgetRect {
  { id, rect, sense, enabled, layer, }
}

///|
fn state(events : Array[@input.Event]) -> @input.State {
  let out = @input.State::new()
  out.begin({ screen, events, time: 0, dt: 0.016, focused: true, })
  out
}

///|
test "a point in no widget is over nothing" {
  let rects = @hit.Rects::new()
  rects.add(widget(one, box(0, 0)))
  assert_eq(rects.at({ x: 50, y: 50, }), None)
  assert_eq(rects.count(), 1)
}

///|
test "of two widgets in the same place, the later one is on top" {
  let rects = @hit.Rects::new()
  rects.add(widget(one, box(0, 0)))
  rects.add(widget(two, box(0, 0)))
  let found = rects.at({ x: 5, y: 5, })
  assert_eq(found.unwrap().id, two)
}

///|
test "a higher layer wins however early it was built" {
  let rects = @hit.Rects::new()
  rects.add(widget(one, box(0, 0), layer=1))
  rects.add(widget(two, box(0, 0)))
  assert_eq(rects.at({ x: 5, y: 5, }).unwrap().id, one)
}

///|
test "a label does not swallow the click meant for what is under it" {
  let rects = @hit.Rects::new()
  rects.add(widget(one, box(0, 0)))
  rects.add(widget(two, box(0, 0), sense=@hit.inert))
  assert_eq(rects.at({ x: 5, y: 5, }).unwrap().id, one)
}

///|
test "a disabled widget is not under the pointer" {
  let rects = @hit.Rects::new()
  rects.add(widget(one, box(0, 0), enabled=false))
  assert_eq(rects.at({ x: 5, y: 5, }), None)
}

///|
test "a widget can be found again by its id, until the frame is forgotten" {
  let rects = @hit.Rects::new()
  rects.add(widget(one, box(10, 10)))
  assert_eq(rects.find(one).unwrap().rect, box(10, 10))
  assert_eq(rects.find(two), None)
  assert_eq(rects.items().length(), 1)
  rects.clear()
  assert_eq(rects.count(), 0)
  assert_eq(rects.find(one), None)
}

///|
test "a widget only wanting to be hovered is still under the pointer" {
  let rects = @hit.Rects::new()
  rects.add(widget(one, box(0, 0), sense=@hit.hover))
  assert_eq(rects.at({ x: 5, y: 5, }).unwrap().id, one)
  assert_false(@hit.hover.is_inert())
  assert_true(@hit.inert.is_inert())
}

///|
test "the widget the pointer is over is the hovered one" {
  let input = state([])
  let answer = @hit.interact(
    widget(one, box(0, 0)),
    one,
    @id.nothing,
    @id.nothing,
    @id.nothing,
    input,
  )
  assert_true(answer.hovered)
  let other = @hit.interact(
    widget(two, box(0, 0)),
    one,
    @id.nothing,
    @id.nothing,
    @id.nothing,
    input,
  )
  assert_false(other.hovered)
}

///|
test "a release over a widget the press did not start on is not a click" {
  let input = state([
    PointerButton(at={ x: 5, y: 5, }, btn=Primary, down=true, mods=@input.none),
    PointerButton(at={ x: 5, y: 5, }, btn=Primary, down=false, mods=@input.none),
  ])
  let pressed_here = @hit.interact(
    widget(one, box(0, 0)),
    one,
    one,
    @id.nothing,
    @id.nothing,
    input,
  )
  assert_true(pressed_here.clicked)
  let pressed_elsewhere = @hit.interact(
    widget(one, box(0, 0)),
    one,
    two,
    @id.nothing,
    @id.nothing,
    input,
  )
  assert_false(pressed_elsewhere.clicked)
}

///|
test "a widget that does not take clicks never reports one" {
  let input = state([
    PointerButton(at={ x: 5, y: 5, }, btn=Primary, down=true, mods=@input.none),
    PointerButton(at={ x: 5, y: 5, }, btn=Primary, down=false, mods=@input.none),
  ])
  let answer = @hit.interact(
    widget(one, box(0, 0), sense=@hit.drag),
    one,
    one,
    @id.nothing,
    @id.nothing,
    input,
  )
  assert_false(answer.clicked)
  assert_true(answer.released)
}

///|
test "a drag belongs to the widget the press started on" {
  let input = state([
    PointerMoved({ x: 5, y: 5, }),
    PointerButton(at={ x: 5, y: 5, }, btn=Primary, down=true, mods=@input.none),
  ])
  input.begin({
    screen,
    events: [PointerMoved({ x: 30, y: 5, })],
    time: 0.1,
    dt: 0.016,
    focused: true,
  })
  let answer = @hit.interact(
    widget(one, box(0, 0), sense=@hit.click_and_drag),
    two,
    one,
    one,
    @id.nothing,
    input,
  )
  assert_true(answer.dragged)
  assert_eq(answer.drag_delta, { x: 25, y: 0, })
  assert_false(answer.hovered)
}

///|
test "a widget that is not being dragged reports no movement" {
  let input = state([PointerMoved({ x: 30, y: 5, })])
  let answer = @hit.interact(
    widget(one, box(0, 0), sense=@hit.click_and_drag),
    one,
    @id.nothing,
    @id.nothing,
    @id.nothing,
    input,
  )
  assert_false(answer.dragged)
  assert_eq(answer.drag_delta, @emath.zero)
}

///|
test "a disabled widget notices nothing at all" {
  let input = state([
    PointerButton(at={ x: 5, y: 5, }, btn=Primary, down=true, mods=@input.none),
    PointerButton(at={ x: 5, y: 5, }, btn=Primary, down=false, mods=@input.none),
  ])
  let answer = @hit.interact(
    widget(one, box(0, 0), enabled=false),
    one,
    one,
    one,
    @id.nothing,
    input,
  )
  assert_false(answer.hovered)
  assert_false(answer.clicked)
  assert_false(answer.dragged)
}

///|
test "focus is reported to the widget that has it" {
  let input = state([])
  let answer = @hit.interact(
    widget(one, box(0, 0)),
    @id.nothing,
    @id.nothing,
    @id.nothing,
    one,
    input,
  )
  assert_true(answer.focused)
}

///|
test "a widget built from others answers for all of them" {
  let left = @hit.Response::none(one, box(0, 0))
  let right : @hit.Response = {
    ..@hit.Response::none(two, box(40, 0)),
    hovered: true,
    clicked: true,
  }
  let both = left.union(right)
  assert_true(both.hovered)
  assert_true(both.clicked)
  assert_eq(both.id, one)
  assert_eq(both.rect, @emath.Rect::of({ x: 0, y: 0, }, { x: 60, y: 20, }))
}

///|
test "a widget says for itself that its value changed" {
  let answer = @hit.Response::none(one, box(0, 0))
  assert_false(answer.changed)
  answer.mark_changed()
  assert_true(answer.changed)
  assert_true(answer.sense.is_inert())
}
