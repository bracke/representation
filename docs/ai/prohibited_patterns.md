# Prohibited Patterns

Enforced by review and by the dependency-boundary audit in
`tools/check_representation` (§43):

- No dependency on Webframework, Templates, Database, Tables, Forms,
  Validation, Identity, Authorization, Jobs, Notifications, Audit, Files, or
  i18n; no HTTP, sockets, or persistence.
- No package-global mutable registries, schemas, versions, caches, or config
  (REP-INV-010). No hidden background tasks.
- No exceptions for routine malformed input (Rule 4.6).
- No deriving external names from Ada component names, or enum symbols from
  `Enumeration'Image`.
- No representing all JSON numbers as `Long_Float`; no silent rounding of exact
  numerics; no silent integer wraparound.
- No silent duplicate-key acceptance; no conflation of null and absent.
- No unchecked conversion for wire decoding; no raw Ada record transmission.
- No shell/Python/Make repository tooling.
- No `Not_Implemented`, TODO placeholders, or completion claims based on
  compilation alone.
