# fixtures/

Checked-in golden fixtures and the malformed-input corpus (Phases 4 and 11):
byte-for-byte compact/pretty/canonical JSON, timestamps, decimals, and a
substantial negative corpus (truncation, invalid escapes, lone surrogates,
invalid UTF-8, duplicate names, excessive nesting, numeric overflow, trailing
garbage, capacity failures).

Contents:

- `golden/simple.input.json` + `golden/simple.canonical.json` — an illustrative
  compact→canonical pair (member sort + `1.0`→`1`).
- `malformed/*.json` — representative negative samples.

These files are illustrative references (and seeds for external tooling). The
**authoritative** golden and negative corpus is embedded and executed in
`tests/representation_tests` (`json_documents_tests`, `hardening_tests`), so it
runs on every build without file-path assumptions.
