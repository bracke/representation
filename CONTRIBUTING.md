# Contributing

- Ada 2022, built with `alr build` against the pinned `gnat_native=15.2.1`.
- Every change keeps the tree building and the AUnit suite green; new behaviour
  ships with tests. Do not claim completion on compilation alone (§43).
- Repository tooling is Ada only (no shell/Python/Make workflow logic).
- Preserve the invariants in `docs/ai/invariants.md`; a change that touches an
  invariant updates its entry and its test in the same commit.
- Run the release gate before proposing a release:
  `cd tools/check_representation && alr build && ./bin/check_representation --release`.
