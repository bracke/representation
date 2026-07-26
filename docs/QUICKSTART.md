# Quickstart

```sh
alr build
cd tests/representation_tests && alr build && ./bin/tests
cd ../../examples/representation_examples && alr build && ./bin/quickstart
```

The foundation API in words:

- `Representation.Paths` builds an authoritative structured location and renders
  it deterministically (`$.users[3].email`).
- `Representation.Results.Outcome` is the pass/fail verdict of an operation;
  ordinary failure is a value, never an exception.
- `Representation.Diagnostics` accumulates bounded, path-stamped issues.
- `Representation.Limits` supplies the finite bounds every decoder must carry
  (`Default_Limits`, `Strict_Limits`).

Typed codecs, schemas, and JSON land in later phases; see
`docs/PHASE_STATUS.md`.
