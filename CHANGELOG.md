# Changelog

All notable changes to `representation` are documented here. The format follows
Keep a Changelog; the project is pre-1.0 and the wire/contract surface is not
yet stable.

## [Unreleased]

### Added
- Phase 0 foundations: repository skeleton, Alire/GPR setup, and the core
  vocabulary packages — `Representation` (strong scalar types + raw bytes),
  `Representation.Version`, `.Identifiers` (+ generic `.Bounded_Token`),
  `.Limits`, `.Errors`, `.Paths`, `.Results`, `.Diagnostics`.
- Invariant registry (`docs/ai/invariants.md`, REP-INV-001..020) and phase
  tracker (`docs/PHASE_STATUS.md`).
- Phase 1 scalar foundations: `Representation.Text` (incremental UTF-8
  validation, SPARK_Mode), `.Numbers` (overflow-safe signed/unsigned parsing),
  `.Decimals` (exact normalized decimals), `.Timestamps` (RFC 3339 → UTC), and
  `.JSON_Escapes` (JSON string decode/encode with surrogate-pair handling).
- Phase 2 JSON tokenizer: `Representation.JSON` codec root and
  `Representation.JSON.Lexer` — a deterministic, incremental, pull-based
  tokenizer with per-token locations, raw string/number values, bounded scratch,
  byte-limit enforcement, and stable machine error ids for malformed input.
- Phase 3 JSON parser: `Representation.JSON.Parser` — a deterministic,
  constant-space, pull-based event reader validating the RFC 8259 grammar. It
  enforces depth, member, element, total-value, and work-budget limits before
  growth, rejects duplicate object keys within an object (bounded, per-object,
  optional), and reports malformed grammar / trailing input / limit exhaustion
  as `Error` events with stable machine ids (REP-INV-002, REP-INV-005 evidence).
- Phase 4 document model: `Representation.Documents` — a bounded in-memory JSON
  value tree over a fixed arena (handle-based nodes, soft overflow, structural
  equality with exact-value number comparison) — and `Representation.JSON.Documents`,
  the JSON document codec that decodes into a Document and encodes it Compact,
  Pretty, or Canonical. Canonical output sorts object members by key and
  normalizes numbers to plain decimal, and is deterministic and idempotent
  (REP-INV-001/008).
- Phase 5 typed contracts/codecs: `Representation.Values` (scalar bridge),
  `.Optionals` (absent/null/present — REP-INV-007), `.Enums` (explicit symbols),
  `.Fields` (descriptor + contract), `.Objects` (order-independent lookup,
  required/duplicate/unknown-member handling, canonical-name encode —
  REP-INV-006/009/011), `.Extensions` (bounded unknown-member capture that
  cannot override core fields — REP-INV-019), `.Arrays` (typed reader),
  `.Variants` (discriminator-bound dispatch — REP-INV-012), `.References`
  (bounded typed reference), and the `.Typed_Codecs` generic end-to-end codec.
- Phase 6 schemas: `Representation.Schemas` — declarative object schemas
  (fields + declared type kinds + unknown policy), immutable after `Finalize`
  (REP-INV-020), with schema-driven `Validate` (adds `field.type-mismatch`) —
  and `Representation.Schemas.Compatibility`, a directional read-compatibility
  check (missing-required / type-mismatch / unknown-rejected).
- Phase 7 versions + migrations: `Representation.Versions` — a bounded supported-
  version registry whose `Resolve` never silently downgrades (REP-INV-015) — and
  `Representation.Migrations`, a forward-only migration-step set with unique
  source per version (deterministic paths — REP-INV-014), `Plan`, and a `Migrate`
  that applies the chain over a Document.
- Phase 8 typed JSON: `Representation.Schemas.Diagnostics` — schema validation
  that collects every issue as a path-stamped diagnostic (REP-INV-016) with
  sensitivity redaction (REP-INV-017) — and `Representation.JSON.Typed`, the
  convenience decode (source → document → schema diagnostics) and encode
  (Compact/Pretty/Canonical). Adds a public `Schemas.Accepts`/`Kind_Name`.
- Phase 9 common models: `Representation.Metadata`, `.Links`, `.Pagination`
  (bounded models with document round-trip), `Representation.Envelopes` (standard
  data/meta/links/page/errors response envelope), and `Representation.Codecs`
  + `.Codecs.Registries` (immutable codec registry — REP-INV-020 registries).
- Phase 10 examples + integration guidance: five runnable examples
  (codec_roundtrip, typed_record, schema_diagnostics, envelope, migrate) over the
  public API, and `docs/INTEGRATION.md` describing how a transport adapter wires
  the library in over the Source/Sink abstractions.
- Phase 11 hardening: `hardening_tests` (malformed corpus, deterministic fuzz
  with canonical-idempotence property, source/sink failure injection, 8-task
  concurrency), a `fuzz/representation_fuzz` stdin harness for external engines
  with a seed corpus, a `bench` throughput example, and reference fixtures.
