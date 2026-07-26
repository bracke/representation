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
