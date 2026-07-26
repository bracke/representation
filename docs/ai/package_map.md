# Package Map

See `AI.md` for the authoritative package-by-package responsibilities and the
permitted dependency graph. This file is the machine-facing index; keep it in
sync as packages land.

Foundations (Phase 0, implemented):
`Representation`, `.Version`, `.Bounded_Token` (generic), `.Identifiers`,
`.Limits`, `.Errors`, `.Paths`, `.Results`, `.Diagnostics`, `.Inputs`,
`.Outputs`, `.Buffers`.

Later phases (planned, see `docs/PHASE_STATUS.md`):
`.Values`, `.Documents(.*)`, `.Fields`, `.Enums`, `.Objects`, `.Arrays`,
`.Variants`, `.Optionals`, `.Extensions`, `.References`, `.Typed_Codecs`,
`.Schemas(.*)`, `.Versions`, `.Migrations(.*)`, `.Codecs(.Registries)`,
`.JSON`, `.Envelopes`, `.Metadata`, `.Links`, `.Pagination`, `.Testing`.
