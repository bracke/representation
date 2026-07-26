# Architecture Decision Records

| ADR | Title | Status |
|-----|-------|--------|
| 001 | Stable contracts over reflection (explicit names, ids, enum symbols) | accepted (structural) |
| 002 | Structured results and bounded diagnostics rather than exceptions | accepted (structural) |
| 003 | Caller-owned values; no hidden mutable global state | accepted (structural) |
| 004 | Exact numerics (integers + exact decimal), never float-for-everything | accepted (structural) |
| 005 | JSON as the only V1 wire codec behind a codec-neutral abstraction | accepted (structural) |
| 006 | Ada-only repository tooling (no shell/Python/Make) | accepted (structural) |

Structural ADRs are decided inline in `docs/ARCHITECTURE.md`; dedicated files
are added when a decision needs its own rationale and alternatives record.
