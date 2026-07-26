# Release

The release gate runs entirely through Ada tooling (`project_tools`); there is
no shell/Python/Make workflow logic in this repository (§5).

```sh
cd tools/check_representation && alr build
./bin/check_representation                 # required surface + dependency boundary
./bin/check_representation --release        # + build library, tests, examples
./bin/check_representation --release-strict # + require clean git worktrees
```

A release is accepted only when every configured gate passes (design §42):
build, full AUnit suite, malformed corpus, property/compatibility/migration
tests, canonical golden vectors, fuzz smoke, static-analysis/proof targets,
compiled examples, documentation validation, and the invariant-to-test mapping.
Reproducibility runs under `TZ=UTC LC_ALL=C`.
