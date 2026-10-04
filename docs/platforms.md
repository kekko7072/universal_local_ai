# Platforms and backends

This page distinguishes implemented support from direction. A vendor API's
existence does not mean Universal Local AI supports it.

## Implemented today

Only `flutter_local_ai` currently has an implementation. Its repository and
published package report these adapters:

| Platform | Implemented backend | Important qualification |
|---|---|---|
| iOS / macOS | Apple Foundation Models | Runtime requires eligible hardware, OS 26+, enabled Apple Intelligence, and ready assets; individual capabilities vary |
| Android | Google ML Kit GenAI Prompt API / Gemini Nano | Runtime support depends on compatible devices and AICore; not every optional feature is bridged |
| Windows | Windows AI Foundry | Compiles in CI; qualifying-device inference remains documented as unverified and requires OS, hardware, runtime, identity, and packaging configuration |
| Web | Chrome Prompt API / Gemini Nano | Requires a compatible Chromium browser and API availability; capabilities differ from native hosts |

The detailed, version-specific matrix remains in the existing
`flutter_local_ai` repository until migration. Consumers must query
`LocalAi.capabilities()` and availability at runtime.

## TypeScript

| Runtime | Adapter in `typescript_local_ai` | Qualification |
|---|---|---|
| Browser | Chrome Prompt API (`LanguageModel`) | Unit-tested against a simulated `LanguageModel`; not yet validated in a real Chrome build. Streaming and model download are bridged. Structured output and image input are not exposed, and the adapter reports them as unsupported. |
| Node.js | `@typescript_local_ai/native` (napi-rs over `rust_local_ai`) | The adapter and its contract exist, but the addon is not built or published, so Node reports `unavailable`. |
| Edge runtimes | none | Reports `unavailable`. |

React, Vue, Svelte and Next.js are supported as framework integrations
(entry points of the same package), not as separate backends.

## Python

`python_local_ai` binds `rust_local_ai` and adds no backend of its own. Its
support is exactly the pinned Rust revision's: the Apple Foundation Models
adapter (beta, macOS 26+) and an explicit `unavailable` on other platforms.
It has only been tested against the fake backend; the Apple path has not been
exercised from Python on hardware yet.

## Not yet implemented in this monorepo

`dart_local_ai` does not yet claim a backend here. Apple,
Windows, Android, Linux, and browser integrations for those packages are
roadmap candidates, not support promises.

## Criteria for adding a backend

A backend becomes supported only when it has:

- a real adapter in the relevant package;
- availability and capability detection;
- unit tests plus appropriate native/build validation;
- an example or reproducible integration path;
- documented OS, hardware, SDK, packaging, and runtime constraints;
- clear notes for features that are missing or unverified on hardware.
