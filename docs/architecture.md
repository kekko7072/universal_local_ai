# Architecture

## Purpose

Universal Local AI is an umbrella for independently publishable libraries. It
is not a model, inference engine, cross-language RPC protocol, or synchronized
release train.

The stable boundary is a set of recognizable concepts:

- model availability and runtime capability detection;
- a model or provider entry point;
- stateful sessions;
- prompts and system instructions;
- text responses and streaming;
- structured output and tools where the backend truly supports them;
- typed errors and platform/backend information;
- explicit resource lifecycles where the language needs them.

Names such as `LocalAiModel`, `LocalAiSession`, `LocalAiCapabilities`, and
`LocalAiResponse` should be recognizable, but spelling, ownership, async
patterns, and error handling remain idiomatic to each ecosystem.

## Ownership rule

> Fix once, test once, benefit every dependent package.

Code belongs in the lowest natural layer that can own it without importing a
higher-level framework. A framework adapter may re-export or wrap the shared
API; it may not keep a second copy.

### Dart and Flutter

```text
Application
    │
    ├── pure Dart ────────> dart_local_ai
    │                            │
    └── Flutter ──────────> flutter_local_ai
                                  │
                                  └── depends on dart_local_ai

dart_local_ai
  ├── public model/session/capability/response contracts
  ├── host-neutral orchestration, schemas, tools, errors, fakes
  └── native host mechanisms usable without Flutter

flutter_local_ai
  ├── Flutter plugin registration and platform channels
  ├── Flutter-only facade or UI integrations
  └── native plugin packaging (Android, Apple, Windows, web registration)
```

The pure-Dart package must resolve in a normal Dart project. It cannot import
`flutter`, `flutter/services.dart`, `flutter_web_plugins`, or Flutter plugin
interfaces. Native Assets, build hooks, `dart:ffi`, and native interop should
be evaluated per backend, but adoption follows a working prototype rather than
an architecture assumption.

The current Flutter implementation already has a useful internal seam:
`LocalAiHost` separates host-neutral Dart behavior from Pigeon, EventChannel,
and browser hosts. Phase 3 turns that seam into package ownership without
copying files. Details are in [Dart migration](dart-migration.md).

### TypeScript and Next.js

Framework-neutral contracts, browser/runtime adapters, validation, and tests
belong in `typescript_local_ai`. `next_local_ai` should add only Next.js-aware
entry points such as runtime selection or framework integration. Server,
browser, and edge runtimes must not be falsely treated as interchangeable.

### Rust

Rust owns its native types, traits, safety model, and platform bindings. It may
inform other packages' concepts, but no cross-language abstraction is required
until multiple implementations demonstrate a concrete need.

## Backend adapters

Each package selects an appropriate backend at runtime or through an explicit
configuration natural to that ecosystem. An adapter must expose availability
and capabilities rather than inferring them only from the OS name.

```text
idiomatic public API
        │
host-neutral orchestration
        │
backend adapter contract
        │
implemented native/on-device API
```

Capabilities can differ across adapters and OS releases. Unsupported features
must be reported or fail explicitly; prompt emulation is not silently
equivalent to native tool calling or schema-constrained output.

## Package and release boundaries

- Each package has its own manifest, changelog, tests, examples, and registry
  release.
- Dependency ranges allow related packages to move independently.
- Coordinated versions are allowed but never structurally required.
- Root CI detects affected families; package workflows own detailed checks.
- No root workflow publishes automatically.

## Migration and history

Each package keeps its own repository, history, tags, and release notes. This
umbrella repository links every package as a top-level git submodule pinned to
a reviewed commit, so no history import or shared tag namespace is needed.
