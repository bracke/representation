# Integration guidance

`representation` is headless and transport-neutral (§2/§3). It never touches
HTTP, sockets, persistence, or tasks. A *transport adapter* — owned by the
consuming project — bridges the wire to the library. This guide shows the two
directions of that bridge. Runnable versions of every snippet live in
`examples/representation_examples`.

## The boundary

| The adapter owns | The library owns |
|------------------|------------------|
| Reading the request body / headers / URI | Grammar, UTF-8, numbers, limits |
| Selecting the contract version | Structural + schema validation |
| Choosing limits for the caller | Order-independent typed decode |
| Mapping diagnostics to a wire error shape | Deterministic canonical encode |
| Writing the response body | Path-stamped, redaction-safe diagnostics |

The adapter passes bytes in through a `Representation.Inputs.Source` and takes
bytes out through a `Representation.Outputs.Sink`. Both are small interfaces;
`Array_Source` and `Buffers.Buffer_Sink` are the in-memory adapters, and a
streaming adapter is a dozen lines over a socket read/write.

## Decoding a request

1. Wrap the request body in a `Source` (stream it — the whole body need not be
   in memory).
2. Choose limits. For untrusted input use `Representation.Limits.Strict_Limits`;
   they bound depth, members, elements, total values, string bytes, and a
   deterministic work budget **before** any growth (REP-INV-005).
3. Decode against a schema with `Representation.JSON.Typed.Decode`. It parses
   into a caller-owned `Documents.Document` and validates against the schema,
   accumulating **every** problem into a `Diagnostics.Diagnostic_Set`. A syntax
   error is one diagnostic located by byte offset/line/column; each schema
   problem is stamped with its structured path (`$.user.email` — REP-INV-016).
4. If `Ok`, read typed values with `Representation.Values` /
   `Representation.Objects.Lookup` (or a `Typed_Codecs` instance for a whole
   record). Decoding is independent of member order (REP-INV-006); duplicate and
   unknown members are handled per the schema's policy (REP-INV-002/011).

Sensitive fields (declared with a non-`Public` sensitivity class) never have
their value echoed into a diagnostic message (REP-INV-017) — map the
`Diagnostic_Set` straight into your error response without a redaction pass.

## Selecting a version and migrating

The adapter decides the incoming version (from a URI segment, header, or media
type — the core never guesses). Then:

- `Representation.Versions.Resolve` classifies it: `Version_Current`,
  `Version_Migratable`, `Version_Too_New` (refuse — never silently downgrade,
  REP-INV-015), or `Version_Unsupported`.
- For `Version_Migratable`, `Representation.Migrations.Migrate` applies the
  unique, deterministic upgrade chain to the decoded document before typed
  reading (REP-INV-014).

## Encoding a response

1. Build the payload in a `Document` — either a `Typed_Codecs` `Write`, or the
   common models (`Metadata`, `Links`, `Pagination`) plus your data node.
2. Wrap them in a `Representation.Envelopes` object (`data` / `meta` / `links` /
   `page` / `errors`; absent sections are omitted).
3. Serialize with `Representation.JSON.Typed.Encode` (or
   `Representation.JSON.Documents.Encode`) to the response `Sink`:
   - `Compact` for normal responses,
   - `Pretty` for human-facing debug output,
   - `Canonical` when the bytes must be reproducible for signing or caching —
     identical values always produce identical bytes (REP-INV-001) and
     re-encoding is a fixed point (REP-INV-008).

## What not to do

- Do not add a dependency from the core to your web/database/auth stack; the
  release tool's boundary audit fails the build if you do (`docs/ai/prohibited_patterns.md`).
- Do not decode untrusted input with `Default_Limits` when a tighter bound
  applies — pass `Strict_Limits` or a custom `Limits` value.
- Do not treat a `Version_Too_New` as the current version.
