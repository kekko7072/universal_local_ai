# Existing project inventory

Inventory date: 4 October 2026. This is a read-only analysis of repositories
owned by `kekko7072`; no existing implementation was modified.

The canonical project domain is [vezz.io](https://vezz.io). GitHub remains the
source repository host and package registries remain the installation source.

## `flutter_local_ai`

- Repository: `kekko7072/flutter_local_ai`; linked into this repository as
  the top-level `flutter_local_ai/` git submodule, pinned at tag `v0.2.1`.
- Registry: published on pub.dev as `flutter_local_ai`; repository manifest
  and registry both show 0.2.1 at inventory time.
- License: MIT.
- Package floor: Dart 3.12 and Flutter 3.44.
- Public surfaces: the compatibility `FlutterLocalAi` facade and the newer
  `LocalAi` / `LocalAiModel` / `LocalAiSession` API.
- Backends: Apple Foundation Models, Android ML Kit GenAI, Windows AI Foundry,
  and Chrome Prompt API.

### Architecture

The package already converged its two public Dart surfaces onto one session
implementation. A `LocalAiHost` contract separates orchestration from native
transport. Native mobile/desktop calls use a Pigeon-generated contract and an
EventChannel; web uses `dart:js_interop` against Chrome's Prompt API. Android,
Swift, and C++ services contain the platform implementations.

### Reusable, Flutter-independent candidates

- availability preparation and polling logic;
- model/session lifecycle and concurrency rules;
- host contract, capability values, host events, and typed errors;
- responses, generation settings, tool declarations and registry;
- schema validation;
- fake host and most host-neutral tests.

These candidates must be moved, not copied. Each file needs an import audit;
the conceptual grouping is not permission to assume it compiles under pure
Dart unchanged.

### Flutter- or platform-specific ownership

- Pigeon and generated Dart/Kotlin/Swift/C++ wire code;
- `flutter/services.dart` EventChannel and PlatformException integration;
- `flutter_web_plugins` registration;
- `FlutterLocalAi` compatibility facade where it uses Flutter APIs;
- genUI integration and Flutter UI types;
- plugin manifests, CocoaPods/SwiftPM, Gradle, CMake, and native services;
- Flutter example application and device builds.

### Dependencies and validation

Runtime package dependencies are Flutter SDK, `plugin_platform_interface`, and
`flutter_web_plugins`; development uses `flutter_test`, `flutter_lints`, and
Pigeon. Native builds add ML Kit GenAI on Android, Foundation Models on Apple,
and Windows App SDK AI projection handling on Windows.

Current CI checks the declared Flutter/Dart floor and pinned current toolchain,
formatting, analysis, VM and Chrome tests, a web example build, configured and
unconfigured Windows builds, generated Pigeon output, and a pub publish dry
run. Separate workflows implement tagged publishing and release automation.
The monorepo must preserve equivalent checks but must not inherit automatic
publishing without explicit authorization.

### Migration path

1. Freeze a compatibility baseline from 0.2.1 tests and public exports.
2. Prototype a pure-Dart native transport before choosing FFI/native assets or
   another mechanism as the package-wide answer.
3. Create `dart_local_ai` with the host-neutral contract and values.
4. Move orchestration and tests to it, replacing Flutter-specific exception
   coupling with a Dart-owned error whose Flutter adapter preserves legacy
   compatibility.
5. Make `flutter_local_ai` depend on and re-export the shared package where
   compatible; retain plugin transport, native code, genUI, and facade.
6. Run old tests plus pure-Dart consumer tests and all native build jobs.
7. Import history into final paths only after this boundary passes.

## `rust_local_ai`

- Repository: `kekko7072/rust_local_ai`; the initially inspected standalone
  checkout contained only a heading README and tags `v0.1.1` and `v0.1.2`.
- Concurrent workspace content: during foundation validation, a top-level
  `rust_local_ai/` Cargo 0.1.0 scaffold appeared. It is preserved as user-owned
  work and analyzed here rather than moved or rewritten.
- API scaffold: `LocalAiModel`, `LocalAiSession`, backend/session traits,
  capabilities, availability, generation configuration, responses, and typed
  errors.
- Backend behavior: detection currently always returns an unsupported adapter;
  Apple, Windows, Ubuntu, and Linux enum variants are design vocabulary, not
  implemented backend claims.
- Registry status: not verified; manifest metadata and historical tags are not
  treated as proof of crates.io publication.

The scaffold has an idiomatic async trait boundary and a session generation
lease that prevents concurrent turns. A deterministic fake and contract tests
cover lifecycle, concurrency, capabilities, configuration, cancellation, and
errors. The inspected suite passes 11 contract tests and one documentation
test with the `testing` feature; a no-default-features library check also
passes. It currently contains no native backend or CI. Consumer examples were
added concurrently but were not part of this foundation's review.

Migration should first establish whether the concurrent scaffold belongs to
the standalone repository's history, then preserve that history while placing
the crate at `packages/rust/rust_local_ai`. Do not copy the scaffold into the
target directory. Select and implement a real backend before claiming platform
support.

## `typescript_local_ai`

- Repository: `kekko7072/typescript_local_ai`, linked as the top-level
  `typescript_local_ai/` git submodule.
- Shape: one ESM npm package with the subpaths `.` (browser / node export
  conditions), `/react`, `/vue`, `/svelte`, `/next` and `/testing`. React,
  Vue, Svelte and Next.js are optional peer dependencies.
- Backends: a Chrome Prompt API adapter, and a Node adapter for the planned
  `@typescript_local_ai/native` napi-rs addon over `rust_local_ai`. The addon
  does not exist yet.
- Validation: typecheck, Vitest unit tests (core, both backends, every
  adapter, SSR rendering for React and Vue), tsup build, publint, and smoke
  imports of every built subpath on Node 20, 22 and 24.
- Registry: not published.
- Replaces the previously planned `next_local_ai` package with the
  `typescript_local_ai/next` subpath.

## `python_local_ai`

- Repository: `kekko7072/python_local_ai`, linked as the top-level
  `python_local_ai/` git submodule.
- Shape: a maturin/PyO3 `abi3` extension (CPython 3.9+) that depends on
  `rust_local_ai` at a pinned git revision. Backend behavior is never
  reimplemented in Python.
- API: `detect()`, `LocalAiModel`, `LocalAiSession` and `ResponseStream`.
  Methods are awaitable, each with a `_sync` twin that releases the GIL.
  Streams work with both `async for` and `for`. Errors form a typed
  hierarchy with stable codes, and the package ships `py.typed` stubs.
  `python_local_ai.testing.FakeBackend` exposes Rust's deterministic fake.
- Backends: whatever the pinned `rust_local_ai` provides. Today that is Apple
  Foundation Models (beta) on macOS and an explicit `unavailable` elsewhere.
- Validation: pytest and doctests against the fake backend, `stubtest`,
  `mypy --strict`, rustfmt and clippy. CI runs on Linux, macOS and Windows
  with Python 3.9 and 3.13 and builds wheel and sdist artifacts.
- Registry: not published.

## Planned repositories

No repository named `dart_local_ai` appeared in the inspected GitHub owner
inventory. Its directory in this foundation is a planning boundary, not a
package and not a registry claim.
