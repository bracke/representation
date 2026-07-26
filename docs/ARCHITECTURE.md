# Architecture

`representation` is layered from a transport-neutral core outward. Each layer
depends only on those below it; nothing depends on an ecosystem project.

```
Envelopes / Links / Pagination / Codec registry        (common models)
        │
Typed JSON  ·  Schemas · Versions · Migrations          (contracts & evolution)
        │
Typed contracts/codecs (fields, enums, objects, arrays, variants, extensions)
        │
Document model (bounded arena, builders, readers, canonicalization)
        │
JSON tokenizer / parser
        │
Scalars (UTF-8, integers, exact decimal, timestamps)
        │
Foundations: vocabulary, identifiers, limits, errors, results, paths,
             diagnostics, inputs, outputs, buffers
```

## Principles

- **Explicit contracts, not reflection.** External names, enum symbols, and
  presence are declared, never derived from Ada component or literal names.
- **Values, not exceptions**, for ordinary failure (Rule 4.6). Contracts and
  assertions guard internal invariants only.
- **Bounded everything** (Rule 4.4): every decode/migration carries explicit
  finite limits and a deterministic work budget; limits are enforced before
  growth.
- **No hidden global state** (REP-INV-010): registries, schemas, versions, and
  contexts are caller-owned immutable values.
- **Deterministic encoding** (REP-INV-001): identical typed input + settings
  produce byte-identical output; canonical output is idempotent.

## Boundaries

The core owns representation validation (presence, bounds, grammar, enum
symbols, discriminator consistency). It does not own domain validation,
persistence, authorization, or transport; those belong to adapters owned by the
consuming project.
