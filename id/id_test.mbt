// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
test "the same derivation gives the same id every time" {
  assert_eq(@id.root("moonegui"), @id.root("moonegui"))
  let parent = @id.root("moonegui")
  assert_eq(parent.child("save"), parent.child("save"))
  assert_eq(parent.child("save").index(2), parent.child("save").index(2))
}

///|
test "different salt, different parent and different index all differ" {
  let parent = @id.root("moonegui")
  assert_not_eq(parent.child("save"), parent.child("load"))
  assert_not_eq(parent.child("save"), @id.root("other").child("save"))
  assert_not_eq(parent.child("save").index(1), parent.child("save").index(2))
  assert_not_eq(parent.child("save"), parent.child("save").child("save"))
}

///|
test "nothing is its own id and nothing else is" {
  assert_true(@id.nothing.is_nothing())
  assert_false(@id.root("moonegui").is_nothing())
  assert_false(@id.nothing.child("x").is_nothing())
}

///|
test "an id prints short enough to read in a snapshot" {
  let short = @id.root("moonegui").short()
  assert_eq(short.length(), 8)
  assert_eq(short, @id.root("moonegui").short())
  assert_not_eq(short, @id.root("moonetui").short())
}

///|
test "ids order and hash, which is what a map of them needs" {
  let table : Map[@id.Id, Int] = Map([])
  let a = @id.root("a")
  let b = @id.root("b")
  table[a] = 1
  table[b] = 2
  assert_eq(table.get(a), Some(1))
  assert_eq(table.get(b), Some(2))
  assert_eq(a.compare(a), 0)
  assert_not_eq(a.compare(b), 0)
}
