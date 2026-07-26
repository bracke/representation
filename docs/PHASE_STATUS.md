# Phase Status

Honest, gate-oriented tracking of the V1 build (§41). A phase is **done** only
when its packages build, its tests pass, and its gate criteria are met — never
on compilation alone (§43).

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | Repository + foundations (Alire/GPR, root vocabulary, identifiers, paths, errors/results, limits, diagnostics, I/O abstractions, docs, invariant registry, Ada release tool) | **done** |
| 1 | UTF-8 + scalar foundations (UTF-8, escaping, int/uint/decimal parsing, RFC 3339 timestamps; SPARK_Mode proof targets). Scalar->typed codec bindings fold into Phase 5. | **done** |
| 2 | JSON tokenizer (incremental, locations, limits, malformed cases) | **done** |
| 3 | JSON parser (arrays/objects/nesting, duplicate detection, event parser, work budget) | **done** |
| 4 | Document model (bounded arena, builders/readers, equality, JSON document codec, canonicalization) | **done** |
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

## Phase 2 — detail

Done and building green (49/49 AUnit):
- `Representation.JSON` (Pure codec root) and `Representation.JSON.Lexer`
  — a deterministic, incremental, pull-based JSON tokenizer (§22.1).
- Reads bytes from a `Representation.Inputs.Source` through a fixed
  `Read_Capacity` buffer; the source is bound as a discriminant so a
  stack-allocated source and its lexer can be co-scoped safely.
- Every token carries its start location (byte offset, 1-based line/column);
  UTF-8 continuation bytes do not advance the column.
- String tokens expose raw content (escapes intact, quotes stripped); number
  tokens expose the validated RFC 8259 number text. Values accumulate into a
  bounded `Value_Capacity` scratch.
- Bounded/deterministic: no dynamic allocation, no unbounded lookahead. Limit
  exhaustion (`Max_String_Bytes`, `Max_Input_Bytes`), malformed input, and
  source failure surface as a `Tok_Error` with a stable machine error id;
  end-of-input is `Tok_End_Of_Input`.
- Tests (`lexer_tests`): structural tokens, literals, string/number values with
  raw escapes, location tracking across leading newlines/spaces, streaming
  equivalence across a 1-byte read buffer, malformed cases (leading zero,
  truncated fraction/exponent, unterminated string, bad literal, unescaped
  control, stray byte), and byte-limit enforcement.

## Phase 3 — detail

Done and building green (58/58 AUnit):
- `Representation.JSON.Parser` — a deterministic, pull-based JSON **event**
  reader (§22.2) driving the lexer. It validates the RFC 8259 grammar (a single
  top-level value; objects, arrays, arbitrary nesting) and emits a flat event
  stream: `Start_Object`/`End_Object`, `Start_Array`/`End_Array`, `Key`,
  `String_Value`/`Number_Value`/`Boolean_Value`/`Null_Value`, `End_Of_Input`,
  and `Error`. Each event carries its location and nesting depth.
- Constant-space: only a bounded container stack (`Depth_Capacity`) and an
  optional bounded key store are held; documents parse without materialising.
- Bounded/deterministic, enforced before growth: `Max_Depth`,
  `Max_Object_Members`, `Max_Array_Elements`, `Max_Total_Values`, and a
  per-token `Work_Budget`. Each surfaces as an `Error` event with a stable id.
- Duplicate object keys are rejected within a single object (REP-INV-002) using
  a bounded per-object key store (`Key_Pool_Bytes` × `Key_Slots`); detection is
  per-object (sibling/nested reuse is allowed) and can be disabled for pure
  structural streaming. Store exhaustion fails closed.
- Values-not-exceptions: malformed grammar, premature end, trailing input,
  limit exhaustion, and source failure are `Error` events with stable machine
  ids (`json.invalid-token`, `json.unexpected-end`, `json.trailing-input`,
  `object.duplicate-field`, `limit.*`), never exceptions.
- Tests (`parser_tests`): scalars, empty/populated structures, key/value
  streams, nesting + depth limit, grammar errors (missing comma/colon, empty
  member, bare/trailing comma, non-string key, empty/unterminated document),
  trailing input, member/element/work-budget/total-value limits, duplicate-key
  detection (incl. sibling/nested non-duplicates and detection-off pass-through),
  and streaming equivalence across a 1-byte read buffer.

## Phase 4 — detail

Done and building green (73/73 AUnit):
- `Representation.Documents` — the bounded in-memory JSON value tree. A Document
  owns a fixed arena (flat node table + text pool); nodes reference each other
  by opaque handle (`Node_Ref`), never by pointer. Builders
  (`Add_*`/`Append`/`Insert`) return `No_Node` and latch `Overflowed` on
  exhaustion; readers (`Kind`/`Bool_Value`/`Text`/`Length`/`Element`/`Member`/
  `Find`); structural `Equal` (arrays in order, objects by matching keys
  regardless of member order, numbers by exact decimal value).
- `Representation.JSON.Documents` — the JSON document codec. `Decode` drives the
  event parser to build a Document (escapes decoded to UTF-8; duplicate member
  names rejected via arena lookup; failure returned as a `Decode_Result` with a
  stable id, category, and location). `Encode` streams a Document to a sink in
  three encodings: **Compact** (no whitespace, insertion order, numbers
  verbatim), **Pretty** (indented), and **Canonical** (no whitespace, members
  sorted by key bytes, numbers normalized to their exact canonical spelling).
- Canonical output is deterministic and idempotent (REP-INV-001/008): equal
  values encode byte-identically and re-encoding is a fixed point.
- Tests: `documents_tests` (scalars, arrays, objects, nesting, order-insensitive
  equality, exact number equality, arena overflow) and `json_documents_tests`
  (decode scalars/structure/escapes/errors, compact round-trip, encode styles,
  canonical reproducibility across member order + number spelling, canonical
  idempotence).
