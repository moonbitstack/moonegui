// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// The one event on this line, or a stop: a line the browser meant to send but
/// this side could not read is a bug worth failing on rather than skipping.
fn expect(line : String) -> @input.Event {
  match event_of(line) {
    Some(event) => event
    None => abort("no event from \"" + line + "\"")
  }
}

///|
test "the queue is split into lines, and the blank ones are not events" {
  assert_eq(lines(""), [])
  assert_eq(lines("m 1 2"), ["m 1 2"])
  assert_eq(lines("m 1 2\nd 3 4 0 0"), ["m 1 2", "d 3 4 0 0"])
  assert_eq(lines("m 1 2\n\nd 3 4 0 0\n"), ["m 1 2", "d 3 4 0 0"])
  assert_eq(lines("\n\n"), [])
}

///|
test "a move carries the pointer position, fractions and all" {
  match expect("m 10.5 -3") {
    PointerMoved(at) => {
      assert_eq(at.x, 10.5)
      assert_eq(at.y, -3)
    }
    _ => abort("a move is a move")
  }
}

///|
test "a position no longer has to be a whole number of pixels" {
  match expect("d 0.25 12.75 0 0") {
    PointerButton(at~, ..) => {
      assert_eq(at.x, 0.25)
      assert_eq(at.y, 12.75)
    }
    _ => abort("a press is a press")
  }
}

///|
test "a press and a release say which button and which modifiers" {
  match expect("d 4 5 0 7") {
    PointerButton(btn~, down~, mods~, ..) => {
      assert_eq(btn, Primary)
      assert_eq(down, true)
      assert_eq(mods, { ctrl: true, alt: true, shift: true, })
    }
    _ => abort("a press is a press")
  }
  match expect("u 4 5 1 0") {
    PointerButton(btn~, down~, mods~, ..) => {
      assert_eq(btn, Secondary)
      assert_eq(down, false)
      assert_eq(mods, @input.none)
    }
    _ => abort("a release is a release")
  }
}

///|
test "a button index names a button, and anything past the middle is the middle" {
  assert_eq(button(0), Primary)
  assert_eq(button(1), Secondary)
  assert_eq(button(2), Middle)
  assert_eq(button(9), Middle)
}

///|
test "modifier bits are ctrl, then alt, then shift" {
  assert_eq(mods(0), @input.none)
  assert_eq(mods(1), { ctrl: true, alt: false, shift: false, })
  assert_eq(mods(2), { ctrl: false, alt: true, shift: false, })
  assert_eq(mods(4), { ctrl: false, alt: false, shift: true, })
  assert_eq(mods(5), { ctrl: true, alt: false, shift: true, })
}

///|
test "the pointer leaving the surface is its own event" {
  match expect("g") {
    PointerGone => ()
    _ => abort("a pointer that has gone has gone")
  }
}

///|
test "scrolling carries both axes, negative being up and left" {
  match expect("s -0.5 -120") {
    Scroll(by) => {
      assert_eq(by.x, -0.5)
      assert_eq(by.y, -120)
    }
    _ => abort("a scroll is a scroll")
  }
}

///|
test "every named key is understood" {
  let names : Array[(String, @input.Key)] = [
    ("Enter", @input.Enter),
    ("Tab", @input.Tab),
    ("Backspace", @input.Backspace),
    ("Delete", @input.Delete),
    ("Escape", @input.Escape),
    ("Space", @input.Space),
    ("ArrowLeft", @input.Left),
    ("ArrowRight", @input.Right),
    ("ArrowUp", @input.Up),
    ("ArrowDown", @input.Down),
    ("Home", @input.Home),
    ("End", @input.End),
    ("PageUp", @input.PageUp),
    ("PageDown", @input.PageDown),
  ]
  for entry in names {
    let (name, key) = entry
    assert_eq(key_of(name), Some(key))
  }
}

///|
test "a key this side has no use for is not a key down" {
  assert_eq(key_of("F5"), None)
  assert_eq(key_of("a"), None)
  assert_eq(event_of("k F5 0"), None)
}

///|
test "a key down carries its modifiers and is never a repeat" {
  match expect("k ArrowLeft 4") {
    KeyDown(key~, mods~, repeat~) => {
      assert_eq(key, Left)
      assert_eq(mods, { ctrl: false, alt: false, shift: true, })
      assert_eq(repeat, false)
    }
    _ => abort("a key down is a key down")
  }
}

///|
test "text keeps every space after the first one" {
  match expect("t hello  world ") {
    Text(text) => assert_eq(text, "hello  world ")
    _ => abort("typed text is text")
  }
}

///|
test "typing a space sends the key and the character it produces" {
  match expect("k Space 0") {
    KeyDown(key~, ..) => assert_eq(key, Space)
    _ => abort("a space is a key")
  }
  match expect("t  ") {
    Text(text) => assert_eq(text, " ")
    _ => abort("a space is text")
  }
}

///|
test "an escape brings back the newline and the backslash it hid" {
  match expect("t one\\ntwo") {
    Text(text) => assert_eq(text, "one\ntwo")
    _ => abort("typed text is text")
  }
  match expect("t a\\\\b") {
    Text(text) => assert_eq(text, "a\\b")
    _ => abort("typed text is text")
  }
  assert_eq(unescape("a\\"), "a\\")
}

///|
test "pasting keeps the lines of what was pasted" {
  match expect("v one\\ntwo\\n") {
    Paste(text) => assert_eq(text, "one\ntwo\n")
    _ => abort("a paste is a paste")
  }
}

///|
test "the surface gaining and losing the keyboard is one event either way" {
  match expect("f 1") {
    Focus(yes) => assert_eq(yes, true)
    _ => abort("focus is focus")
  }
  match expect("f 0") {
    Focus(yes) => assert_eq(yes, false)
    _ => abort("focus is focus")
  }
}

///|
test "a line this side does not know is not an event" {
  assert_eq(event_of(""), None)
  assert_eq(event_of("z 1 2"), None)
}

///|
test "a number is read without a library, sign and point included" {
  assert_eq(parse(""), 0)
  assert_eq(parse("12"), 12)
  assert_eq(parse("-12"), -12)
  assert_eq(parse("12.5"), 12.5)
  assert_eq(parse("-0.75"), -0.75)
  assert_eq(parse("0.25"), 0.25)
  assert_eq(parse("007"), 7)
}

///|
test "a line is cut into as many words as asked for and no more" {
  assert_eq(words("t a b c", 2), ["t", "a", "b c"])
  assert_eq(words("d 1 2 0 0", 5), ["d", "1", "2", "0", "0"])
  assert_eq(words("", 3), [])
  assert_eq(rest("t "), "")
  assert_eq(rest("t"), "")
}
