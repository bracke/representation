# Invariant → Evidence Mapping

| Invariant | Evidence (test / contract) | Status |
|-----------|----------------------------|--------|
| REP-INV-013 | `Foundation_Tests.Test_Identifiers` | proven |
| REP-INV-016 | `Foundation_Tests.Test_Path_Render`, `Test_Diagnostics` | proven |
| REP-INV-004 | `Text_Tests` (overlong, surrogate, out-of-range, malformed, incremental) | proven |
| REP-INV-004 (JSON) | `Escapes_Tests` (surrogate pairs, lone/malformed surrogate + invalid-escape rejection) | proven |
| REP-INV-003 | `Numbers_Tests` (signed/unsigned boundaries + overflow) | proven (integer path) |
| REP-INV-018 | `Decimals_Tests` (normalization, canonical equality, limits) | proven |
| REP-INV-010 | dependency-boundary audit in `check_representation`; no package-level mutable state (audited) | audited |

Remaining REP-INV entries are `planned`; each gains a row here when its owning
package and test land (see `docs/PHASE_STATUS.md`).
