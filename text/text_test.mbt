// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// Five pixels a character, twelve and a half a line.
let font : @paint.FontId = { size: 10, family: Mono, }

///|
let rec : @back.Rec = @back.Rec::new()

///|
fn rows_of(galley : @paint.Galley) -> Array[String] {
  let out : Array[String] = []
  for row in galley.rows {
    out.push(row.text)
  }
  out
}

///|
test "a short string is one row, as wide as it measures" {
  let galley = @text.layout(rec, "hello", font)
  assert_eq(rows_of(galley), ["hello"])
  assert_eq(galley.size, { x: 25, y: 12.5, })
  assert_eq(galley.rows[0].at, @emath.zero)
  assert_eq(galley.font, font)
}

///|
test "a newline starts a row, one line height further down" {
  let galley = @text.layout(rec, "ab\ncdef\ng", font)
  assert_eq(rows_of(galley), ["ab", "cdef", "g"])
  assert_eq(galley.rows[1].at, { x: 0, y: 12.5, })
  assert_eq(galley.rows[2].at, { x: 0, y: 25, })
  assert_eq(galley.size, { x: 20, y: 37.5, })
}

///|
test "a carriage return before a newline is part of the break" {
  assert_eq(rows_of(@text.layout(rec, "ab\r\ncd", font)), ["ab", "cd"])
}

///|
test "an empty string is one empty row, not no rows at all" {
  let galley = @text.layout(rec, "", font)
  assert_eq(rows_of(galley), [""])
  assert_eq(galley.size, { x: 0, y: 12.5, })
}

///|
test "a trailing newline leaves an empty row behind it" {
  assert_eq(rows_of(@text.layout(rec, "ab\n", font)), ["ab", ""])
}

///|
test "a line too wide to fit breaks at the last space that does" {
  let galley = @text.layout(rec, "hello world", font, wrap=30)
  assert_eq(rows_of(galley), ["hello", "world"])
  assert_eq(galley.size, { x: 25, y: 25, })
}

///|
test "the space a row was broken at is not drawn at the end of it" {
  let galley = @text.layout(rec, "ab      cd", font, wrap=30)
  assert_eq(rows_of(galley), ["ab", "cd"])
}

///|
test "a word with no space in it is cut rather than left to overflow" {
  assert_eq(rows_of(@text.layout(rec, "abcdefghij", font, wrap=25)), [
    "abcde", "fghij",
  ])
}

///|
test "a word longer than the whole line still makes progress" {
  let galley = @text.layout(rec, "aaaaaaa b", font, wrap=12)
  assert_eq(rows_of(galley), ["aa", "aa", "aa", "a", "b"])
}

///|
test "a line narrower than one character breaks one character at a time" {
  assert_eq(rows_of(@text.layout(rec, "abc", font, wrap=1)), ["a", "b", "c"])
}

///|
test "breaking happens inside each line the text already had" {
  assert_eq(rows_of(@text.layout(rec, "one two\nthree", font, wrap=25)), [
    "one", "two", "three",
  ])
}

///|
test "centred rows are placed against the widest one" {
  let galley = @text.layout(rec, "abcd\nz", font, align=Center)
  assert_eq(galley.size.x, 20)
  assert_eq(galley.rows[0].at.x, 0)
  assert_eq(galley.rows[1].at.x, 7.5)
}

///|
test "a row laid out on its own is one row however long it is" {
  let galley = @text.line(rec, "one two three", font)
  assert_eq(galley.rows.length(), 1)
  assert_eq(galley.size, { x: 65, y: 12.5, })
}

///|
test "text that fits is not shortened" {
  assert_eq(@text.elide(rec, "abcd", font, 100), "abcd")
}

///|
test "text that does not fit is cut and marked" {
  assert_eq(@text.elide(rec, "abcdefghij", font, 30), "abcde…")
  assert_eq(@text.elide(rec, "abcdefghij", font, 30, tail="..."), "abc...")
}

///|
test "text with no room for anything is left as the mark alone" {
  assert_eq(@text.elide(rec, "abcdefghij", font, 4), "…")
}

///|
test "a click lands on the nearer side of the character it is over" {
  assert_eq(@text.index_at(rec, "abcd", font, 0), 0)
  assert_eq(@text.index_at(rec, "abcd", font, 2), 0)
  assert_eq(@text.index_at(rec, "abcd", font, 3), 1)
  assert_eq(@text.index_at(rec, "abcd", font, 12), 2)
  assert_eq(@text.index_at(rec, "abcd", font, 13), 3)
}

///|
test "a click outside the text lands at one end or the other" {
  assert_eq(@text.index_at(rec, "abcd", font, -50), 0)
  assert_eq(@text.index_at(rec, "abcd", font, 500), 4)
  assert_eq(@text.index_at(rec, "", font, 5), 0)
}

///|
test "a caret's distance along the text is the width of what is before it" {
  assert_eq(@text.x_at(rec, "abcd", font, 0), 0)
  assert_eq(@text.x_at(rec, "abcd", font, 2), 10)
  assert_eq(@text.x_at(rec, "abcd", font, 4), 20)
  assert_eq(@text.x_at(rec, "abcd", font, 40), 20)
  assert_eq(@text.x_at(rec, "abcd", font, -1), 0)
}

///|
test "moving over a character made of two code units moves over both" {
  let text = "a\u{1F600}b"
  assert_eq(text.length(), 4)
  assert_eq(@text.next_index(text, 0), 1)
  assert_eq(@text.next_index(text, 1), 3)
  assert_eq(@text.next_index(text, 3), 4)
  assert_eq(@text.next_index(text, 4), 4)
  assert_eq(@text.prev_index(text, 4), 3)
  assert_eq(@text.prev_index(text, 3), 1)
  assert_eq(@text.prev_index(text, 1), 0)
  assert_eq(@text.prev_index(text, 0), 0)
}

///|
test "a click never puts the caret inside a surrogate pair" {
  let text = "a\u{1F600}b"
  assert_eq(@text.index_at(rec, text, font, 7), 1)
  assert_eq(@text.index_at(rec, text, font, 9), 3)
}

///|
test "inserting and removing leave the rest of the string alone" {
  assert_eq(@text.insert("ac", 1, "b"), "abc")
  assert_eq(@text.insert("ab", 0, "z"), "zab")
  assert_eq(@text.insert("ab", 2, "z"), "abz")
  assert_eq(@text.insert("ab", 90, "z"), "abz")
  assert_eq(@text.remove("abcd", 1, 3), "ad")
  assert_eq(@text.remove("abcd", 0, 4), "")
  assert_eq(@text.remove("abcd", 2, 2), "abcd")
}

///|
test "removing works whichever way round the two indices are" {
  assert_eq(@text.remove("abcd", 3, 1), "ad")
  assert_eq(@text.remove("abcd", -5, 2), "cd")
  assert_eq(@text.remove("abcd", 2, 90), "ab")
}
