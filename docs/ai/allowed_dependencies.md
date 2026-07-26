# Allowed Dependencies

- **Core (`src/`)**: the Ada 2022 standard library only. No third-party or
  ecosystem crates.
- **`tests/representation_tests`**: `representation`, `aunit`, `project_tools`
  (path-pinned).
- **`examples/representation_examples`**: `representation` only.
- **`tools/check_representation`**: `project_tools` only (drives `alr` out of
  process; does not depend on the library it checks).

The dependency-boundary audit fails the build if any core source unit `with`s a
forbidden ecosystem or transport package.
