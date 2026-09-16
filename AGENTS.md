<!-- Copyright 2026 Leo Cheng -->

# Working here

Run the gate before every commit and read every result:

```bash
moon clean && moon fmt && moon check --target all --deny-warn && moon build --target all && moon test --target all
```

`moon test` does not deny warnings, so `check` has to be run on its own. The four
backends all have to pass: `wasm`, `wasm-gc`, `js` and `native`.

# Two rules the whole library depends on

1. **The core is synchronous.** `wasm-gc` has no async and a browser cannot be
   blocked, so a frame is a function the host calls, never a loop this library
   owns. Nothing below `back/` may await anything.
2. **Nothing target-dependent may reach a snapshot.** Numbers are printed as
   sixty-fourths, `Map` iteration order is never relied on, and `String`'s `<`
   is not used for ordering: it compares length first.

# Layout

`emath`, `id`, `input`, `mem`, `paint`, `layout`, `hit`, `text`, `ctx` and
`widget` are pure and run everywhere. `back` holds the contract and the
recorder; `back/web`, `back/canvas` and `back/html` are the browser side and are
`js` only. Anything that has to touch a browser goes in those three and nowhere
else.

# Things worth knowing

- Hit testing matches the pointer against the **previous** frame's rectangles.
  A widget is therefore hovered and clicked one frame after it first appears,
  and the tests say so on purpose.
- A widget that keeps no state still has to be kept alive for the frame:
  `Ctx::interact` calls `Memory::keep` for anything that can take focus, or the
  end of the frame takes its focus away again.
- `Rect::union` treats an empty rectangle as absent, so a bounding box is folded
  corner by corner rather than by uniting a rectangle per point.
- The recorder's font is exactly regular — every character the same width — so a
  test can work out the numbers it expects by hand. Keep it that way.
- `moon info --target all` regenerates `pkg.generated.mbti`; CI fails if the
  result differs from what is committed. Packages restricted to one target have
  no `.mbti`, which is expected.
