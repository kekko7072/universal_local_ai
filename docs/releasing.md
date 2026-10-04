# Releasing

Every package is released from **its own repository**, on its own schedule,
by that repository's release workflow. This umbrella repository never
publishes. It pins tested combinations and verifies them in CI.

| Package | Registry | Release workflow | Trigger | Credentials |
|---|---|---|---|---|
| `flutter_local_ai` | pub.dev | `release-on-merge.yml` → `publish.yml` | merge to `main` with a new pubspec version (auto-tags `v<version>`) | pub.dev automated publishing (OIDC); `RELEASE_TOKEN` to push the tag |
| `rust_local_ai` | crates.io | `release.yml` | GitHub release `v<version>` | crates.io trusted publishing (OIDC), `CARGO_REGISTRY_TOKEN` fallback |
| `typescript_local_ai` | npm | `release.yml` | GitHub release `v<version>` | npm Trusted Publishing (OIDC) with provenance; `NPM_TOKEN` only for the first publish |
| `python_local_ai` | PyPI | `release.yml` | GitHub release `v<version>` | PyPI Trusted Publishing (OIDC) |

Each release workflow refuses a tag that does not match the manifest
version, and each one can be run manually as a dry run first.

## Order for a cross-package change

Packages depend on each other through pinned versions or revisions, so
release from the bottom up:

```text
rust_local_ai ──► python_local_ai           (crates.io version in Cargo.toml)
              └─► @typescript_local_ai/native (planned)
typescript_local_ai                          (independent)
flutter_local_ai                             (independent today)
```

1. Merge and release `rust_local_ai` to crates.io.
2. Bump `rust_local_ai` in `python_local_ai/Cargo.toml` (and `Cargo.lock`),
   merge, and release.
3. Release any other package that changed.
4. In this repository, re-pin each submodule to its released `main` commit
   (`git -C <submodule> checkout <sha>`, then commit the pointer) and update
   the status tables in `README.md` and `docs/projects.md`.

## What CI checks here

`.github/workflows/ci.yml` runs on every pull request and on `main`:

- **Submodule pins:** each pin must exist upstream. On pull requests and manual runs, a pin
  that isn't on the submodule's default branch yet is a warning, so a change
  can be reviewed while its upstream pull request is open. On `main` it is an
  error, because a squash merge upstream would leave the pin unreachable.
- **Package checks at the pinned commit**, only for the areas that changed:
  - `rust_local_ai`: `cargo test --all-features` on Linux, macOS and Windows.
  - `python_local_ai`: built against the **`rust_local_ai` submodule**
    through a Cargo `[patch]`, then pytest and stubtest on all three OSes.
    This checks the exact pair pinned here.
  - `typescript_local_ai`: `npm run check` and a pack dry run on Node 20
    and 24.
  - `flutter_local_ai`: `flutter analyze` and `flutter test` on Flutter
    3.44.x.
- **Release status** (on `main` and manual runs): a table comparing each
  pinned manifest version with npm, PyPI, crates.io and pub.dev.
- **CI result:** one aggregate job that fails if any job failed. Make it the
  only required status check in the branch protection for `main`, because
  skipped package jobs count as passing.
