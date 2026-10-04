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
Those checks stay in `flutter_local_ai`. The umbrella CI runs `flutter analyze`
and `flutter test` at the pinned commit and never publishes.

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
7. Release both packages from their own repositories and re-pin the
   submodules here.

## `rust_local_ai`

- Repository: `kekko7072/rust_local_ai`, linked as the top-level
  `rust_local_ai/` git submodule and pinned at `main` (`68d9edc`).
- Registry: `rust_local_ai` 0.1.0 is listed on crates.io.
- API: `LocalAiModel`, `LocalAiSession`, backend/session traits,
  capabilities, availability, generation configuration, responses, and typed
  errors. Sessions hold a generation lease that prevents concurrent turns.
- Backends: according to its README, a Swift C-ABI bridge to Apple
  Foundation Models implements availability, sessions, text generation,
  cancellation and token counting (beta, macOS 26.4+ for token counting).
  Windows, Ubuntu and other Linux providers are planned; other platforms
  report `unavailable`. The Apple hardware test is opt-in and has not been
  run as part of this inventory.
- Optional features: `testing` (deterministic `FakeBackend`), `genui`, and
  `a2ui` (generative UI modules and A2UI protocol messages).
- Downstream: `python_local_ai` binds this crate through PyO3, and the planned
  `@typescript_local_ai/native` addon will bind it for Node.
- CI and release: the repository has its own CI and release workflows.

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
- Registry: not yet on PyPI; the repository has a Trusted Publishing release
  workflow (abi3 wheels for Linux, macOS and Windows plus an sdist) waiting
  for the PyPI publisher to be configured.

## Planned repositories

No repository named `dart_local_ai` exists yet. It is planned as its own
repository, to be added here as a submodule once it exists; until then it is
neither a package nor a registry claim.
