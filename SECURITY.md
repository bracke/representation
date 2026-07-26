# Security

`representation` decodes untrusted external input, so defensive decoding is a
first-class concern. See design §34 for the full threat model. In brief, every
decode carries explicit finite limits and a deterministic work budget, and the
following are always rejected or bounded: deep nesting, oversized arrays/
objects/strings, invalid UTF-8, escape expansion, numeric/exponent overflow,
duplicate keys, alias collisions, unknown discriminators, malicious extensions,
and version downgrade.

Security-sensitive contracts can require: reject unknown fields, reject unknown
enum values, disable extensions, strict versions, tight bounds, and redacted
diagnostics. Sensitive field values are omitted from diagnostics by default
(REP-INV-017). The project makes no constant-time claims and does not perform
cryptography.

To report a vulnerability, contact the maintainer at bent@bracke.dk.
