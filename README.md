# representation

Strongly typed, transport-independent framework for defining, validating,
versioning, encoding, and decoding stable external application representations
in Ada 2022.

It is the boundary between internal/domain models → explicit typed
representation models → codec-neutral contracts → concrete encoded bytes.
Its primary responsibility is **stable external representation contracts**;
serialization (JSON in V1) is a subordinate capability.

The core is headless and reusable: it depends on no ecosystem project and knows
nothing about HTTP, routing, templates, forms, databases, auth, scheduling, or
persistence. Integration happens through explicit adapters owned by consumers.

## Status

V1 is under construction, phase by phase (`docs/PHASE_STATUS.md`). Nothing is
declared complete on compilation alone; each phase is gated on building,
passing tests, and its acceptance criteria (§42 of the design).

**Phase 0 (foundations)** — in progress: repository, root strong-scalar
vocabulary, identifiers, paths, errors/results/diagnostics, limits.

## Build

```sh
alr build
cd tests/representation_tests && alr build && ./bin/tests   # (once the suite lands)
```

## Documentation

- `docs/PHASE_STATUS.md` — what is built and what is pending.
- `docs/ai/invariants.md` — the normative invariant registry (REP-INV-*).
- `AI.md` — deterministic package-by-package guidance for building on the library.

## License

MIT OR Apache-2.0 WITH LLVM-exception.
