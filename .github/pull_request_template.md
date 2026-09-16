## Changes

## Verification

<!-- The gate, in order. Paste what you actually ran. -->

- [ ] `moon fmt`
- [ ] `moon check --target all --deny-warn`
- [ ] `moon build --target all`
- [ ] `moon test --target all`

**Interface**

<!-- Did `moon info --target all` change any pkg.generated.mbti? If so, say what
     moved: that file is the public interface. -->

**Frames**

<!-- Snapshots of paint commands must read the same on wasm, wasm-gc, js and
     native. If you updated any with `moon test --update`, say why the new
     output is the correct one — and check no floating point number reached it. -->

**Interaction**

<!-- A change to hit testing or focus affects which widget a click lands on.
     Say which interaction cases you added or ran. -->
