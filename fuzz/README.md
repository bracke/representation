# fuzz/

Ada fuzz harnesses and corpus management (Phase 11): UTF-8 validation,
tokenizer, parser, document builder, typed decoder, migration engine, canonical
encoder, and compatibility checker. Repository orchestration is Ada/
project_tools based; an external engine may feed bytes.

## representation_fuzz

A path-pinned subcrate (`representation` only). `bin/fuzz_json` is a stdin
target for an external engine (AFL++, honggfuzz, or a shell loop): it slurps
bytes from standard input, decodes them against `Strict_Limits`, canonically
re-encodes on success, and prints a one-line verdict:

```
$ printf '{"b":2,"a":[1]}' | ./bin/fuzz_json
accept TRUE
$ printf '{bad'            | ./bin/fuzz_json
reject representation.json.invalid-token
```

The library must never raise on hostile input; if it does, the target prints
`PANIC` and exits non-zero so the fuzzer records a finding. `corpus/` holds seed
inputs. Build with `alr build`.

The in-process, deterministic fuzz loop (4000 rounds, fixed seed, no-crash +
canonical-idempotence property) runs on every build in
`tests/representation_tests` (`hardening_tests`); this harness is for longer
out-of-process campaigns.
