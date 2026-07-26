# V1 Acceptance Report

Status of the `representation` library against its V1 acceptance criteria and
the REP-INV invariant set. Everything below is reproduced by the commands in
"How to verify"; nothing here is asserted on compilation alone.

## Summary

| Dimension | Result |
|-----------|--------|
| Phases 0–12 | complete |
| AUnit suite | **125 / 125** passing, 0 failures, 0 unexpected errors |
| Build (library, tests, examples, tool, fuzz) | success, **zero warnings** (`-gnatwa`-clean, `-gnaty` style-clean) |
| GNATprove (`--level=2`, SPARK units) | **53 checks proved, 0 unproved, 0 justified** |
| Invariants | **20 / 20** covered — 19 proven, 1 audited |
| Dependency boundary | clean (no ecosystem/HTTP/persistence dependency) |
| Repository tooling | Ada-only (no shell/Python/Make logic) |
| Release check | `check_representation` and `--release` pass |

## Invariants (REP-INV-001 .. 020)

| ID | Status | Primary evidence |
|----|--------|------------------|
| 001 | proven | `JSON_Documents_Tests.Test_Canonical_Reproducible` |
| 002 | proven | `Parser_Tests` / `JSON_Documents_Tests` / `Objects_Tests` (duplicate rejection) |
| 003 | proven (SPARK) | `Numbers_Tests` + GNATprove no-overflow on `Numbers` |
| 004 | proven (SPARK) | `Text_Tests` + GNATprove RTE-free `Text`; `Escapes_Tests` |
| 005 | proven | `Lexer_Tests` / `Parser_Tests` limit enforcement |
| 006 | proven | `Objects_Tests` / `Typed_Codecs_Tests` order-independent decode |
| 007 | proven | `Typed_Scalar_Tests.Test_Optionals` (absent ≠ null) |
| 008 | proven | `JSON_Documents_Tests.Test_Canonical_Idempotent` + fuzz |
| 009 | proven | `Objects_Tests.Test_Encode_Canonical_Names` |
| 010 | audited | dependency-boundary scan + no package-level mutable state; `Hardening_Tests.Test_Concurrency` |
| 011 | proven | `Objects_Tests.Test_Validate_Unknown_Policy` |
| 012 | proven | `Variants_Tests.Test_Dispatch_Errors` |
| 013 | proven | `Foundation_Tests.Test_Identifiers` |
| 014 | proven | `Versions_Tests.Test_Migration_Graph` |
| 015 | proven | `Versions_Tests.Test_Resolve` (too-new refused) |
| 016 | proven | `Foundation_Tests` + `Typed_JSON_Tests.Test_Multi_Issue_Paths` |
| 017 | proven | `Typed_JSON_Tests.Test_Redaction` |
| 018 | proven | `Decimals_Tests` / `Documents_Tests.Test_Number_Equality` |
| 019 | proven | `Objects_Tests.Test_Extensions` (core name refused) |
| 020 | proven | `Schemas_Tests` + `Envelopes_Tests.Test_Registry` (immutable after Finalize) |

Full per-invariant evidence: `invariant-registry/mapping.md`.

## Acceptance gates

Enforced by `tools/check_representation` (required surface, dependency boundary,
build/test/examples) and by the test suite.

| Gate | Result | Evidence |
|------|--------|----------|
| Library builds, zero warnings | pass | `alr build` |
| Full AUnit suite passes | pass | `tests/representation_tests` (125/125) |
| Malformed / negative corpus rejected, no crash | pass | `Hardening_Tests.Test_Malformed_Corpus` (~30 cases) |
| Property: canonical idempotence + round-trip | pass | `Hardening_Tests` + `JSON_Documents_Tests` |
| Compatibility / migration determinism | pass | `Schemas_Tests.Test_Compatibility`, `Versions_Tests` |
| Canonical golden vectors | pass | `JSON_Documents_Tests.Test_Canonical_Numbers`; `fixtures/golden` |
| Fuzz smoke (no crash) | pass | `Hardening_Tests.Test_Fuzz_No_Crash` (4000 rounds); `fuzz/representation_fuzz` |
| Source / sink failure injection | pass | `Hardening_Tests.Test_Source_Failure` / `Test_Sink_Failure` |
| Concurrency (no shared state) | pass | `Hardening_Tests.Test_Concurrency` (8 tasks) |
| Static analysis / proof targets | pass | GNATprove `--level=2`: 53/53 proved |
| Values-not-exceptions for routine failure | pass | every decode/validate returns a status; fuzz never raises |
| Bounded / no unbounded growth | pass | fixed-capacity arenas, limits enforced before growth |
| No hidden global mutable state | pass | boundary audit; concurrency test |
| Dependency boundary (no Web/DB/HTTP/…) | pass | `check_representation` boundary scan |
| Ada-only repository tooling | pass | `check_representation` is Ada; no shell/Python/Make logic |
| Examples build and run | pass | `check_representation --release`; 6 example programs |
| Documentation present | pass | ARCHITECTURE, QUICKSTART, INTEGRATION, RELEASE, ADRs, AI map |
| Invariant-to-test mapping | pass | `invariant-registry/mapping.md`; this report |
| Reproducible canonical output | pass | see below |

## Reproducibility

Canonical encoding is reproducible **by construction**: the core reads no clock,
locale, environment, or random source and holds no global mutable state, so
identical typed input plus settings always produce byte-identical output
(REP-INV-001) and re-encoding canonical output is a fixed point (REP-INV-008).
Both are tested directly and exercised over 4000 fuzzed inputs. Release
verification runs under `TZ=UTC LC_ALL=C`; the output does not depend on either.

## Proof gate (GNATprove, SPARK_Mode units)

`Representation.Text` and `Representation.Numbers` are `SPARK_Mode => On`.
`gnatprove -P representation.gpr --level=2` reports:

```
Run-time Checks        25   proved
Assertions              6   proved
Functional Contracts    5   proved
Initialization          7   proved
Termination            10   proved
Total                  53   proved   (0 unproved, 0 justified)
```

This machine-checks that integer parsing never overflows or wraps (REP-INV-003)
and that UTF-8 scalar counting/validation is free of run-time errors
(REP-INV-004). Other units are `SPARK_Mode` absent by design (they use access
types, tasking-free callbacks, or generics outside the SPARK subset) and are
covered by tests.

## How to verify

```sh
# build + tests
alr build
cd tests/representation_tests && alr build && ./bin/tests        # 125/125

# release gate (surface, dependency boundary, build/test/examples)
cd ../../tools/check_representation && alr build && ./bin/check_representation --release

# proofs
cd ../.. && alr exec -- gnatprove -P representation.gpr --level=2

# fuzz smoke
cd fuzz/representation_fuzz && alr build && printf '{"a":[1,2]}' | ./bin/fuzz_json
```
