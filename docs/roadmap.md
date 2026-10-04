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
- [x] Create `typescript_local_ai` and `python_local_ai` and link them as
  submodules.
- [x] Fold the planned `next_local_ai` package into the
  `typescript_local_ai/next` subpath.
- [x] Keep each package in its own repository, linked here as a submodule,
  instead of importing history into a monorepo `packages/` tree.

## Phase 3 — Dart architecture

- [ ] Prototype a pure-Dart host for one backend using the most appropriate
  Dart native mechanism.
- [ ] Create the real `dart_local_ai` package manifest and public contracts.
- [ ] Move host-neutral code once, preserving attribution and tests.
- [ ] Make `flutter_local_ai` depend transitively on `dart_local_ai`.
- [ ] Keep compatibility facades for the published Flutter API.
- [ ] Validate a plain `dart create` consumer without Flutter installed.
- [ ] Create the `kekko7072/dart_local_ai` repository and link it here as a
  submodule.

See [Dart migration](dart-migration.md).

## Phase 4 — Other ecosystems

- [ ] Define an idiomatic Rust API after the first backend is selected.
- [x] Scaffold the framework-neutral TypeScript package with a Chrome Prompt
  API adapter.
- [x] Add thin React, Vue, Svelte and Next.js (server) adapters as subpaths
  of the same package.
- [ ] Validate the Prompt API adapter in a real Chrome build.
- [ ] Build and publish `@typescript_local_ai/native` (napi-rs over
  `rust_local_ai`) for the Node backend.
- [ ] Add example apps (Vite + React, Next.js, Nuxt, SvelteKit) and build them
  in CI.
- [x] Build `python_local_ai` as PyO3 bindings over `rust_local_ai`.
- [ ] Validate `python_local_ai` against Apple Foundation Models on a
  configured Mac, then publish wheels to PyPI with explicit authorization.
- [ ] Evaluate Swift, Kotlin, Go, and React Native from concrete user and
  backend requirements.

## CI growth

As package manifests arrive, add affected-package jobs for formatting, linting,
unit tests, native/platform builds, integration tests, package validation,
example builds, and publication dry-runs. Actual publishing remains manual or
requires a separately reviewed authorization and credentials.
