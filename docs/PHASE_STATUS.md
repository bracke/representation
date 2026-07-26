# Phase Status

Honest, gate-oriented tracking of the V1 build (§41). A phase is **done** only
when its packages build, its tests pass, and its gate criteria are met — never
on compilation alone (§43).

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Repository + foundations (Alire/GPR, root vocabulary, identifiers, paths, errors/results, limits, diagnostics, I/O abstractions, docs, invariant registry, Ada release tool) | **done** |
| 1 | UTF-8 + scalar foundations (UTF-8, escaping, int/uint/decimal parsing, RFC 3339 timestamps; SPARK_Mode proof targets). Scalar->typed codec bindings fold into Phase 5. | **done** |
| 2 | JSON tokenizer (incremental, locations, limits, malformed cases) | pending |
| 3 | JSON parser (arrays/objects/nesting, duplicate detection, event parser, work budget) | pending |
| 4 | Document model (bounded arena, builders/readers, equality, JSON document codec, canonicalization) | pending |
| 5 | Typed contracts/codecs (fields, optional/null/default, arrays, objects, enums, variants, references, extensions) | pending |
| 6 | Schemas (descriptors, builders, finalization, introspection, compatibility) | pending |
| 7 | Versions + migrations (registry, graph validation, typed adapters, document migrations) | pending |
| 8 | Typed JSON (direct decode/encode, compact/pretty/canonical, streaming, diagnostics) | pending |
| 9 | Common models (envelopes, metadata, links, pagination, codec registry) | pending |
| 10 | Examples + integration guidance | pending |
| 11 | Hardening (malformed corpus, properties, fuzzing, failure injection, concurrency, benchmarks) | pending |
| 12 | Release completion (docs, invariant mapping, proof gates, reproducibility, acceptance report) | pending |

## Phase 0 — detail

Done and building green:
- Repo skeleton, `alire.toml`, `representation.gpr`, Alire config generation.
- `Representation` (root strong-scalar vocabulary + raw `Byte`).
- `Representation.Version`, `.Identifiers` (+ generic `.Bounded_Token`),
  `.Limits`, `.Errors` (categories, stable error ids, sensitivity classes),
  `.Paths` (structured path + deterministic render), `.Results` (Outcome),
  `.Diagnostics` (bounded set).
- `docs/ai/invariants.md` (REP-INV-001..020).

Remaining in Phase 0 (next):
- `Representation.Inputs` / `.Outputs` / `.Buffers` (pull source / push sink /
  bounded buffers + adapters).
- `tests/representation_tests` subcrate (AUnit harness) with foundation tests.
- Ada release/check tool (`check_representation`, no shell — §5), required-surface
  + dependency-boundary + build/test gates.
- `docs/` set (ARCHITECTURE, QUICKSTART, RELEASE, package_map, prohibited_patterns,
  allowed_dependencies), `AI.md`, ADR index, `SECURITY.md`, `CONTRIBUTING.md`.
