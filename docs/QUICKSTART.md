# Quickstart

```sh
alr build
cd tests/representation_tests && alr build && ./bin/tests
cd ../../examples/representation_examples && alr build && ./bin/quickstart
```

The foundation API in words:

- `Representation.Paths` builds an authoritative structured location and renders
  it deterministically (`$.users[3].email`).
- `Representation.Results.Outcome` is the pass/fail verdict of an operation;
  ordinary failure is a value, never an exception.
- `Representation.Diagnostics` accumulates bounded, path-stamped issues.
- `Representation.Limits` supplies the finite bounds every decoder must carry
  (`Default_Limits`, `Strict_Limits`).

## Runnable examples

`examples/representation_examples` (build with `alr build`, run `./bin/<name>`):

- **codec_roundtrip** — parse JSON into the document model, re-emit canonical.
- **typed_record** — bind an Ada record to a JSON contract via `Typed_Codecs`
  (order-independent decode, canonical encode).
- **schema_diagnostics** — validate against a schema, printing every
  path-stamped diagnostic; a `Credential` field's value is redacted.
- **envelope** — assemble a `data`/`meta`/`links`/`page` response envelope.
- **migrate** — resolve an incoming version and migrate a document to current.

## Wiring it into a transport

See `docs/INTEGRATION.md` for how a headless transport adapter (HTTP handler,
message consumer, …) decodes a request body against a schema, redacts sensitive
values from diagnostics, and encodes a response envelope — all over the
`Inputs.Source` / `Outputs.Sink` streaming abstractions.
