# Invariant Registry (REP-INV-*)

Normative invariants for the `representation` library. Each is machine-checked
by tests and/or contracts once its owning package exists; the release gate
fails if a `release-gate` invariant is not covered.

Status legend:
- **proven** — implemented and covered by a passing test and/or contract.
- **audited** — structurally guaranteed and confirmed by review / boundary
  audit (e.g. absence of a construct).
- **planned** — not yet implemented; the owner column names the intended home.

| ID | Invariant | Owner | Status | Consequence if violated |
|----|-----------|-------|--------|--------------------------|
| REP-INV-001 | Identical typed input, version, schema, codec, options and extension set encode to byte-identical output | Representation.Typed_Codecs, .JSON | planned | non-reproducible bytes; broken signing/caching |
| REP-INV-002 | Duplicate logical fields (canonical, alias, or collision) are never accepted | Representation.Objects | planned | ambiguous decode; smuggled overrides |
| REP-INV-003 | Numeric overflow is never accepted or silently wrapped | Representation.Values, .JSON | planned | corrupted values |
| REP-INV-004 | Invalid UTF-8 is rejected | Representation.Text (Phase 1) | planned | mojibake; injection |
| REP-INV-005 | Limits are enforced before any prohibited growth | Representation.Limits | planned | memory/CPU denial of service |
| REP-INV-006 | Typed object decoding is field-order independent | Representation.Objects | planned | order-dependent bugs |
| REP-INV-007 | Absent and null remain distinct | Representation.Optionals | planned | lost patch/merge semantics |
| REP-INV-008 | Canonical encoding is idempotent | Representation.Documents.Canonicalization | planned | signing instability |
| REP-INV-009 | Encoding emits canonical field names only (aliases are decode-only) | Representation.Fields | planned | contract drift |
| REP-INV-010 | No hidden mutable global registry, schema, version, or cache exists | (whole core) | audited | non-determinism; hidden coupling |
| REP-INV-011 | Unknown-field behaviour is explicit (Reject/Ignore/Preserve) | Representation.Extensions | planned | silent data loss or injection |
| REP-INV-012 | Variant dispatch is bound to declared discriminators only | Representation.Variants | planned | type confusion |
| REP-INV-013 | Schema and field identifiers are stable and locale-neutral | Representation.Identifiers | proven | contract breakage on rename |
| REP-INV-014 | Migration paths are deterministic | Representation.Migrations | planned | divergent upgrades |
| REP-INV-015 | Unsupported versions never silently downgrade | Representation.Versions | planned | data corruption |
| REP-INV-016 | Diagnostics identify the failing structured path | Representation.Diagnostics, .Paths | proven | unusable errors |
| REP-INV-017 | Sensitive values are omitted from diagnostics by default | Representation.Diagnostics, .Errors | planned | credential/PII leakage |
| REP-INV-018 | Exact numerics are never silently rounded | Representation.Values (decimal) | planned | financial corruption |
| REP-INV-019 | Extensions cannot override core fields | Representation.Extensions | planned | contract subversion |
| REP-INV-020 | Finalized registries and schemas are immutable | Representation.Codecs.Registries, .Schemas | planned | data races; drift |

## Phase 0 evidence (implemented so far)

- **REP-INV-013** — `Representation.Identifiers.Valid_Identifier` enforces the
  stable-identifier lexical rule; the schema/field/codec/error id kinds are
  distinct instantiations of `Representation.Bounded_Token`.
- **REP-INV-016** — `Representation.Paths` builds an authoritative structured
  path with deterministic `Render` (`$.users[3].email`), and
  `Representation.Diagnostics.Make` stamps every diagnostic with it.
- **REP-INV-010** — the core has no package-level mutable state; all future
  registries/contexts are caller-owned values (audited; enforced by the
  dependency-boundary check in the release tool once built).

Test-to-invariant mapping is emitted by the release tooling (Phase 12); until
then, the `Owner` column is the source of truth for where each invariant lands.
