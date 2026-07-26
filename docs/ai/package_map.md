# Package Map

See `AI.md` for the authoritative package-by-package responsibilities and the
permitted dependency graph. This file is the machine-facing index; keep it in
sync as packages land.

Foundations (Phase 0, implemented):
`Representation`, `.Version`, `.Bounded_Token` (generic), `.Identifiers`,
`.Limits`, `.Errors`, `.Paths`, `.Results`, `.Diagnostics`, `.Inputs`,
`.Outputs`, `.Buffers`.

Scalars + JSON codec (Phases 1-4, implemented):
`.Text`, `.Numbers`, `.Decimals`, `.Timestamps`, `.Json_Escapes`,
`.JSON`, `.JSON.Lexer`, `.JSON.Parser`, `.Documents`, `.JSON.Documents`.

Typed contracts/codecs (Phase 5, implemented):
`.Values`, `.Optionals`, `.Enums`, `.Fields`, `.Objects`, `.Arrays`,
`.Extensions`, `.Variants`, `.References`, `.Typed_Codecs`.

Schemas (Phase 6, implemented):
`.Schemas`, `.Schemas.Compatibility`.

Versions + migrations (Phase 7, implemented):
`.Versions`, `.Migrations`.

Typed JSON (Phase 8, implemented):
`.Schemas.Diagnostics`, `.JSON.Typed`.

Later phases (planned, see `docs/PHASE_STATUS.md`):
`.Codecs(.Registries)`, `.Envelopes`, `.Metadata`, `.Links`, `.Pagination`,
`.Testing`.
