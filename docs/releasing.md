# Releasing

Every package is released from **its own repository**, on its own schedule,
by that repository's release workflow. This umbrella repository never
publishes. It pins tested combinations and verifies them in CI.

Every package releases the same way: **bump the version and add a
`## <version>` entry to `CHANGELOG.md`, then merge to `main`.** Its release
workflow tests the package, publishes it to the registry and creates the
GitHub release `v<version>`, using that changelog entry as the notes and
attaching the built artifacts. A merge whose version is already published, or
already tagged, releases nothing.

| Package | Registry | Release workflow | GitHub release assets | Credentials |
|---|---|---|---|---|
| `flutter_local_ai` | pub.dev | `release-on-merge.yml` tags `v<version>` → `publish.yml` | notes only (pub.dev hosts the package) | pub.dev automated publishing (OIDC); `RELEASE_TOKEN` to push the tag |
| `rust_local_ai` | crates.io | `release.yml` | the packaged `.crate` | crates.io trusted publishing (OIDC), `CARGO_REGISTRY_TOKEN` fallback |
| `typescript_local_ai` | npm | `release.yml` | the `npm pack` tarball | npm Trusted Publishing (OIDC) with provenance; `NPM_TOKEN` only for the first publish |
| `python_local_ai` | PyPI | `release.yml` | every wheel and the sdist | PyPI Trusted Publishing (OIDC) |

Publishing a GitHub release by hand still works for Rust, Python and
TypeScript: the package is published and the artifacts are attached to that
release. Each workflow refuses a tag that does not match the manifest
version, and a manual run (Actions → Release → Run workflow) is a dry run.
Adding required reviewers to each publishing environment (`crates-io`,
`pypi`, `npm`) makes every release wait for your approval.

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
