# AI.md — building on and within `representation`

Deterministic guidance for machine-assisted work on this repository. Keep it
accurate against the delivered public APIs; update it in the same change that
alters a contract.

## What this library is (and is not)

`representation` defines **stable external representation contracts** and their
codecs (JSON in V1). It is headless and transport-neutral. It must never gain a
dependency on Webframework, Templates, Database, Tables, Forms, Validation,
Identity, Authorization, Jobs, Notifications, Audit, Files, or i18n, and must
never touch HTTP, sockets, files, tasks, or persistence (§2, §3, §43).

## Permitted dependency graph

- The core (`src/`) depends only on the Ada runtime. No third-party or
  ecosystem crates.
- `tests/representation_tests` depends on `representation`, `aunit`, and
  `project_tools` (path-pinned).
- The Ada release tool depends on `project_tools` only (not on the library it
  checks; it drives `alr` out of process).
- Repository tooling is **Ada** (§5): no shell/Python/Make workflow logic.

## Package map (foundations, Phase 0)

| Package | Responsibility | Ownership notes |
|---------|----------------|-----------------|
| `Representation` | Root strong-scalar vocabulary (Byte/Element/Field/Depth counts, offsets, versions' base, line/column) + raw `Byte`/`Byte_Array`. Pure; no logic. | value types only |
| `Representation.Version` | The contract/schema version number and active-range test. | value type |
| `Representation.Bounded_Token` (generic) | Private fixed-capacity validated token; instantiated per id kind. | caller-owned values |
| `Representation.Identifiers` | Stable, locale-neutral identifiers; distinct Schema/Field/Codec/Error id types. | REP-INV-013 |
| `Representation.Limits` | Explicit finite decode/migration limits + work budget; `Default_Limits`, `Strict_Limits`. | REP-INV-005 (enforcement lands with decoders) |
| `Representation.Errors` | Failure categories, stable machine error ids, sensitivity classes. | REP-INV-017 |
| `Representation.Paths` | Bounded structured location path + deterministic `Render`. | REP-INV-016; caller-owned mutable stack |
| `Representation.Results` | `Outcome`: the single pass/fail verdict of an operation. | REP-INV (no-exception) 4.6 |
| `Representation.Diagnostics` | Bounded, truncation-reporting collection of individual issues. | REP-INV-016/017 |

Packages for later phases (documents, typed codecs, schemas, versions/
migrations, JSON, envelopes/links/pagination, registry, testing support) are
listed in `docs/PHASE_STATUS.md` and the design; they do not exist yet and must
not be referenced until built.

## Ownership and lifetime rules

- All contexts, registries, buffers, documents, paths, and diagnostic sets are
  **caller-owned values**. There is no package-global mutable state
  (REP-INV-010).
- Finalized registries/schemas (later phases) are immutable and safe for
  concurrent reading; parser/encoder/document/workspace instances are not shared
  across tasks unless the caller protects them (§33).

## Core rules to preserve in every change

- Ordinary malformed input, capacity exhaustion, unsupported versions, and I/O
  errors are **values** (`Results.Outcome` / diagnostics), never exceptions
  (Rule 4.6). Reserve exceptions/contracts for internal invariants.
- Distinct quantities get distinct types (Rule 4.7); never `Natural`
  indiscriminately.
- Enforce a limit **before** the growth it bounds (REP-INV-005).
- Diagnostics carry the structured path and a stable error id, and never embed
  sensitive values by default (REP-INV-016/017).

## Build / test / check commands

```sh
alr build                                             # library
cd tests/representation_tests && alr build && ./bin/tests   # (from Phase 0 completion)
```

The release gate runs through the Ada `check_representation` tool (added in
Phase 0 completion): required-surface + dependency-boundary audit by default;
`--release` adds build + tests + examples; `--release-strict` adds a clean-git
requirement.
