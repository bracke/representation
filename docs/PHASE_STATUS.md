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
| 5 | Typed contracts/codecs (fields, optional/null/default, arrays, objects, enums, variants, references, extensions) | **done** |
| 6 | Schemas (descriptors, builders, finalization, introspection, compatibility) | **done** |
| 7 | Versions + migrations (registry, graph validation, typed adapters, document migrations) | **done** |
| 8 | Typed JSON (direct decode/encode, compact/pretty/canonical, streaming, diagnostics) | **done** |
| 9 | Common models (envelopes, metadata, links, pagination, codec registry) | **done** |
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
  idempotence, and plain canonical number spelling).

## Phase 5 — detail

Done and building green (96/96 AUnit):
- `Representation.Values` — typed scalar get/put between Document nodes and Ada
  scalars via the exact Numbers/Decimals paths (overflow/malformed reported,
  never wrapped — REP-INV-003/018).
- `Representation.Optionals` — generic Absent / Null_Present / Value_Present
  tri-state (REP-INV-007).
- `Representation.Enums` — generic enum codec driven by a caller-supplied Symbol
  function; unknown symbols rejected; never Enumeration'Image.
- `Representation.Fields` — immutable field descriptor (canonical name,
  decode-only aliases, presence policy, sensitivity) + `Field_Set` contract.
- `Representation.Objects` — order-independent name-matched lookup (REP-INV-006);
  Validate enforces required fields, rejects a field supplied under more than one
  name (REP-INV-002), applies an explicit unknown-member policy Reject/Ignore/
  Preserve (REP-INV-011); Put_Field emits canonical names only (REP-INV-009).
- `Representation.Extensions` — bounded unknown-member capture; a core field's
  name can never become an extension (REP-INV-019).
- `Representation.Arrays` — ordered accessors + a generic typed-vector Reader.
- `Representation.Variants` — discriminator-bound dispatch; an unrecognised
  discriminator is never mapped to a default (REP-INV-012).
- `Representation.References` — bounded, non-empty typed reference value.
- `Representation.Typed_Codecs` — the end-to-end generic codec: JSON source →
  document → contract validation → caller Read; caller Write → document →
  Compact/Pretty/Canonical JSON sink.
- Phase 4 canonical number spelling refined to plain decimal (never scientific),
  so decoded integers survive a canonical round-trip while staying idempotent.
- Tests: `typed_scalar_tests`, `objects_tests`, `variants_tests`,
  `typed_codecs_tests` (full order-independent decode / missing-field / syntax /
  encode / canonical round-trip).

## Phase 6 — detail

Done and building green (102/102 AUnit):
- `Representation.Schemas` — a declarative object schema: an id, an ordered set
  of fields (each a Fields descriptor + a declared `Type_Kind`), and an
  unknown-member policy. Built incrementally, then `Finalize`d; once final the
  builder is refused and only read-only introspection remains (REP-INV-020).
  `Validate` checks a Document object against the schema — presence, duplicate,
  and unknown-member rules (via `Objects`) plus each present field's declared
  type — reporting the first violation with a category and stable id
  (`object.*` or the new `field.type-mismatch`).
- `Representation.Schemas.Compatibility` — a directional, fail-closed read
  compatibility check between two schemas: it flags a required field the writer
  does not guarantee (`Missing_Required`), an incompatibly retyped shared field
  (`Type_Mismatch`), and — when the reader rejects unknowns — a field the writer
  emits that the reader does not declare (`Unknown_Rejected`). `Kind_Any`,
  number⊇integer, and string⊇enum/reference widen acceptance.
- Tests (`schemas_tests`): build/introspect, immutability after finalize,
  validate ok / type-mismatch / non-object root / missing / unknown, and the
  four compatibility outcomes (identical, missing-required, type-mismatch,
  unknown-rejected vs ignore-tolerated).

## Phase 7 — detail

Done and building green (107/107 AUnit):
- `Representation.Versions` — a bounded, caller-owned registry naming the Current
  version and the older versions accepted via migration. `Resolve` never silently
  downgrades: a newer version is `Version_Too_New` (refused, not treated as
  Current) and an unregistered older version is `Version_Unsupported`
  (REP-INV-015). Immutable after `Finalize`.
- `Representation.Migrations` — a caller-owned set of forward-only upgrade steps,
  each carrying a `Transform` that rewrites the document value. At most one step
  may leave a version, so the path between two versions is unique and migration
  is deterministic (REP-INV-014); forward-only steps guarantee termination.
  `Plan` reports path existence/absence without touching a document; `Migrate`
  applies the chain in order and reports `No_Path` / `Failed` / `Cycle`.
- Tests (`versions_tests`): resolve (current/migratable/too-new/unsupported),
  version-set immutability, migration graph (unique-source determinism,
  forward-only, plan ok/no-path), chain application over a Document, and
  migrate errors (no-path, failing transform).

## Phase 8 — detail

Done and building green (113/113 AUnit):
- `Representation.Schemas.Diagnostics` — schema validation that reports every
  issue (wrong root, missing required, field type mismatch, unknown member) as a
  path-stamped diagnostic in a bounded `Diagnostic_Set`, rather than stopping at
  the first (REP-INV-016). `Redacted_Value` renders a node's value for a message
  but returns `<redacted>` for any redacted sensitivity class, so a sensitive
  field's value never appears in diagnostics (REP-INV-017).
- `Representation.JSON.Typed` — the schema-typed JSON convenience: `Decode`
  parses a streaming source into a caller-owned Document and validates it against
  a schema, accumulating parse and schema issues into one `Diagnostic_Set` (a
  syntax failure is a single diagnostic located by offset/line/column); `Encode`
  serializes a subtree in Compact/Pretty/Canonical.
- Tests (`typed_json_tests`): redaction (public shown vs credential/secret
  redacted), multi-issue collection with `$.id` / `$.name` path stamps, decode
  valid / syntax / schema-invalid, and canonical typed encode.

## Phase 9 — detail

Done and building green (119/119 AUnit):
- `Representation.Metadata` — a bounded key -> value-node map (unique keys, owned
  key pool); `To_Object` / `From_Object`.
- `Representation.Links` — a bounded set of rel -> href links (unique relations,
  shared byte pool); renders to/from a `{ rel : href }` object.
- `Representation.Pagination` — a pagination descriptor (limit / offset / total /
  has_more + optional cursor) with type-checked `To_Object` / `From_Object`.
- `Representation.Envelopes` — the standard response envelope assembling the
  canonical sections `data` / `meta` / `links` / `page` / `errors` (omitting any
  absent section) and reading them back; `Has_Errors`. Depends only on the
  document model.
- `Representation.Codecs` (namespace) and `Representation.Codecs.Registries` — a
  bounded, caller-owned codec registry (id -> media type), immutable after
  `Finalize` (REP-INV-020, registries half), with no global registry
  (REP-INV-010).
- Tests (`models_tests`, `envelopes_tests`): metadata/links/pagination
  round-trips and rejections; envelope assembly + section accessors + errors;
  registry register/duplicate/lookup and post-finalize immutability.
