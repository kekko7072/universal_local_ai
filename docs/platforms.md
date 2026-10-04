# Platforms and backends

This page distinguishes implemented support from direction. A vendor API's
existence does not mean Universal Local AI supports it.

## Implemented today

`flutter_local_ai` has the broadest implementation. Its repository and
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

## Rust

`rust_local_ai` 0.2.0 reports these adapters:

| Platform | Backend | Qualification |
|---|---|---|
| macOS | Apple Foundation Models | Beta; macOS 26+ with Apple Intelligence; token counting on 26.4+ |
| Windows | Phi Silica (Windows App SDK) | Beta; Copilot+ PC or supported GPU, Windows 11 25H2+, and an app with package identity declaring `systemAIModels` |
| Linux | Ubuntu inference snaps | Uses an installed snap such as `qwen3`; streaming supported |
| Any | Local OpenAI-compatible server | `openai_compatible()` for llama.cpp, Ollama, LM Studio or Foundry Local; `http://` on this machine only |

"Beta" means built and type-checked in CI but not yet run against a real
model. See that repository's support matrix for details.

## TypeScript

| Runtime | Adapter in `typescript_local_ai` | Qualification |
|---|---|---|
| Browser | Chrome Prompt API (`LanguageModel`) | Unit-tested against a simulated `LanguageModel`; not yet validated in a real Chrome build. Streaming and model download are bridged. Structured output and image input are not exposed, and the adapter reports them as unsupported. |
| Node.js | `@typescript_local_ai/native` (napi-rs over `rust_local_ai`) | The adapter and its contract exist, but the addon is not built or published, so Node reports `unavailable`. |
| Edge runtimes | none | Reports `unavailable`. |

React, Vue, Svelte and Next.js are supported as framework integrations
(entry points of the same package), not as separate backends.

## Python

`python_local_ai` binds `rust_local_ai` and adds no backend of its own, so its
support is exactly the Rust table above. CI tests it against the fake backend
and, end to end, against the OpenAI-compatible backend with a local test
server. The Apple, Windows and inference-snap paths haven't yet been run from
Python on real hardware. A plain `python.exe` has no package identity, so on
Windows Phi Silica reports `provider_not_installed`.

## Not yet implemented

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
