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

## Not yet implemented in this monorepo

`dart_local_ai`, `rust_local_ai`, `typescript_local_ai`, and `next_local_ai` do
not yet claim a backend here. Apple, Windows, Android, Linux, and browser
integrations for those packages are roadmap candidates, not support promises.

## Criteria for adding a backend

A backend becomes supported only when it has:

- a real adapter in the relevant package;
- availability and capability detection;
- unit tests plus appropriate native/build validation;
- an example or reproducible integration path;
- documented OS, hardware, SDK, packaging, and runtime constraints;
- clear notes for features that are missing or unverified on hardware.
