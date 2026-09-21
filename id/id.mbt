// Copyright 2026 Leo Cheng
// SPDX-License-Identifier: Apache-2.0

///|
/// What connects a widget to the same widget in the frame before.
///
/// An id is derived from its parent and a piece of salt — usually the widget's
/// label, or its index in a list. Two widgets in the same place with the same
/// salt are the same widget as far as anything that remembers is concerned,
/// which is exactly the property an immediate-mode interface needs.
pub(all) struct Id(UInt64) derive(Eq, Hash, Compare, Debug)

///|
/// The id nothing has.
pub let nothing : Id = Id(0)

///|
/// The root of an id tree.
pub fn root(name : String) -> Id {
  Id(mix(0xcbf2_9ce4_8422_2325UL, name))
}

///|
/// A child of this id.
pub fn Id::child(self : Id, salt : String) -> Id {
  let Id(seed) = self
  Id(mix(seed * 1099511628211UL + 0x9E37_79B9_7F4A_7C15UL, salt))
}

///|
/// A child of this id identified by a number, which is what a list of widgets
/// built in a loop needs.
pub fn Id::index(self : Id, at : Int) -> Id {
  self.child(at.to_string())
}

///|
/// True when this is the id nothing has.
pub fn Id::is_nothing(self : Id) -> Bool {
  self == nothing
}

///|
/// The id as a number, for a backend that has to name it.
pub fn Id::value(self : Id) -> UInt64 {
  let Id(value) = self
  value
}

///|
/// A short, stable, printable form. Ids appear in snapshots, and sixty-four bits
/// of decimal make them unreadable; eight hexadecimal digits do not.
pub fn Id::short(self : Id) -> String {
  let Id(value) = self
  let digits = "0123456789abcdef"
  let out = StringBuilder()
  let mut at = 28
  while at >= 0 {
    let nibble = ((value >> at) & 0xFUL).to_int()
    out.write_string(digits[nibble:nibble + 1].to_owned())
    at = at - 4
  }
  out.to_string()
}

///|
/// The FNV-1a hash, which is short, has no state to carry around, and gives the
/// same answer on every backend — the last of which matters, because an id can
/// end up in a snapshot.
fn mix(seed : UInt64, text : String) -> UInt64 {
  let mut hash = seed
  for i in 0..<text.length() {
    hash = (hash ^ text[i].to_uint64()) * 1099511628211UL
  }
  hash
}

///|
pub extend Id with Debug::{to_repr}

///|
pub extend Id with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Id with Eq::{not_equal, equal}

///|
pub extend Id with Hash::{hash, hash_combine}
