# Agent instructions — representation

Typed transport-independent external representation contracts.

This crate pins its GNAT toolchain via Alire (`gnat_native = "=15.2.1"`). Build and test with `alr`, not
system GNAT / GPRBuild / GNATprove / GNATdoc tools on `PATH` — `alr exec -- gnatls --version` must report the pinned GNAT.

```sh
alr build
cd tools/check_representation && alr build && ./bin/check_representation --release   # release gate
```
