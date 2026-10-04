# Roadmap

The roadmap is evidence-driven. Phases describe ordering, not synchronized
package releases.

## Phase 1 — Foundation

- [x] Establish the umbrella repository and governance files.
- [x] Define architecture and API philosophy.
- [x] Inventory known repositories without moving their source.
- [x] Record only verified platform and publication claims.
- [x] Add change-aware, non-publishing CI foundations.

## Phase 2 — Repository analysis

- [x] Analyze `flutter_local_ai` architecture, backends, dependencies, tests,
  CI, reusable code, and platform-specific code.
- [x] Analyze the standalone `rust_local_ai` repository and the concurrent
  workspace API scaffold; record that no native backend is implemented.
- [x] Confirm that Dart, TypeScript, and Next.js repositories do not yet exist
  in the current owner inventory.
- [x] Link existing package repositories as top-level git submodules instead
  of importing their history.
- [ ] Reconcile the top-level Rust scaffold with standalone repository history.

## Phase 3 — Dart architecture

- [ ] Prototype a pure-Dart host for one backend using the most appropriate
  Dart native mechanism.
- [ ] Create the real `dart_local_ai` package manifest and public contracts.
- [ ] Move host-neutral code once, preserving attribution and tests.
- [ ] Make `flutter_local_ai` depend transitively on `dart_local_ai`.
- [ ] Keep compatibility facades for the published Flutter API.
- [ ] Validate a plain `dart create` consumer without Flutter installed.

See [Dart migration](dart-migration.md).

## Phase 4 — Other ecosystems

- [ ] Define an idiomatic Rust API after the first backend is selected.
- [ ] Build the framework-neutral TypeScript package around an implemented
  runtime.
- [ ] Add a thin Next.js integration only for framework-specific concerns.
- [ ] Evaluate Swift, Kotlin, Python, Go, and React Native from concrete user
  and backend requirements.

## CI growth

As package manifests arrive, add affected-package jobs for formatting, linting,
unit tests, native/platform builds, integration tests, package validation,
example builds, and publication dry-runs. Actual publishing remains manual or
requires a separately reviewed authorization and credentials.
