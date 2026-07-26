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
| REP-INV-005 | `Lexer_Tests.Test_Limits` (Max_String_Bytes enforced before capture; bounded Value scratch; Max_Input_Bytes); `Parser_Tests.Test_Limits` (depth/members/elements/total-values/work-budget) | proven (tokenizer + parser limits) |
| REP-INV-002 | `Parser_Tests.Test_Duplicate_Keys`; `JSON_Documents_Tests.Test_Decode_Errors` (duplicate member rejected on decode) | proven (collision case) |
| REP-INV-001 | `JSON_Documents_Tests.Test_Canonical_Reproducible` (equal values, differing member order + number spelling → byte-identical canonical output) | proven (JSON canonical) |
| REP-INV-008 | `JSON_Documents_Tests.Test_Canonical_Idempotent` (canonical(canonical(x)) = canonical(x)) | proven |
| REP-INV-018 (doc) | `Documents_Tests.Test_Number_Equality` (1 = 1.0 = 10e-1 by exact value); canonical number normalization | proven |
| REP-INV-006 | `Objects_Tests.Test_Lookup_Order_Independent`; `Typed_Codecs_Tests.Test_Decode_Order_Independent` | proven |
| REP-INV-007 | `Typed_Scalar_Tests.Test_Optionals` (absent /= null; distinct fallbacks) | proven |
| REP-INV-009 | `Objects_Tests.Test_Encode_Canonical_Names` (alias never emitted; canonical only) | proven |
| REP-INV-011 | `Objects_Tests.Test_Validate_Unknown_Policy` (Reject/Ignore/Preserve) | proven |
| REP-INV-012 | `Variants_Tests.Test_Dispatch_Errors` (undeclared discriminator -> Variant_Unknown) | proven |
| REP-INV-019 | `Objects_Tests.Test_Extensions` (core field name refused as extension) | proven |
| REP-INV-020 | `Schemas_Tests.Test_Immutable_After_Finalize` (Add_Field refused post-Finalize; count unchanged) | proven (schemas) |
| Compatibility | `Schemas_Tests.Test_Compatibility` (missing-required / type-mismatch / unknown-rejected vs ignore) | proven (Compatibility_Failure semantics) |
| REP-INV-014 | `Versions_Tests.Test_Migration_Graph` (unique source per version; forward-only; deterministic plan) | proven |
| REP-INV-015 | `Versions_Tests.Test_Resolve` (too-new refused, never downgraded; unregistered unsupported) | proven |
| REP-INV-016 (decode) | `Typed_JSON_Tests.Test_Multi_Issue_Paths` (each schema issue stamped with its `$.field` path) | proven |
| REP-INV-017 | `Typed_JSON_Tests.Test_Redaction` (public value shown; credential/secret → `<redacted>`) | proven |

Remaining REP-INV entries are `planned`; each gains a row here when its owning
package and test land (see `docs/PHASE_STATUS.md`).
