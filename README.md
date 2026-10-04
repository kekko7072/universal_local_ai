# Universal Local AI

**Native AI, any language.**

[vezz.io](https://vezz.io) is the home of Universal Local AI.

Universal Local AI is an open-source ecosystem that makes local and
operating-system-native AI accessible from the languages and frameworks
developers already use.

Instead of learning a different native AI API for every platform, use an
idiomatic library for your ecosystem.

> **Write for your language. Run AI locally.**

```text
                 Universal Local AI

     Dart       Flutter       Rust
       │           │            │
       └──────┬────┴─────┬──────┘
              │          │
          TypeScript   Next.js
              │          │
              └────┬─────┘
                   │
              Local AI Layer
                   │
       ┌───────────┼───────────┐
       │           │           │
     Apple      Windows      Other
  Foundation    Local AI     Native
    Models                    AI
```

## Projects

Every package remains independently versioned and publishable. Statuses below
describe verified repository and registry state as of 4 October 2026; they do
not promise backend support that has not been implemented and tested.

| Ecosystem | Package | Registry | Status |
|---|---|---|---|
| Dart | `dart_local_ai` | pub.dev | Planned |
| Flutter | [`flutter_local_ai`](https://vezz.io) | [pub.dev](https://pub.dev/packages/flutter_local_ai) | Published; migration analysis complete |
| Rust | [`rust_local_ai`](https://vezz.io) | crates.io | API scaffold; no native backend or verified publication |
| TypeScript | `typescript_local_ai` | npm | Planned |
| Next.js | `next_local_ai` | npm | Planned |

The Flutter package currently implements Apple Foundation Models, Android ML
Kit GenAI, Windows AI Foundry, and Chrome's Prompt API with different verified
capabilities on each platform. See [platforms](docs/platforms.md) for the
careful support matrix. No backend is attributed to the other packages yet.

## One ecosystem, four principles

### Universal

One ecosystem spans multiple languages and frameworks. It shares vocabulary,
design lessons, and conformance expectations without forcing every language
into the same syntax.

### Local

Inference stays on the user's device whenever the selected platform backend
supports it. Availability is a runtime fact: hardware, OS version, user
settings, model readiness, and application configuration can all affect it.

### Native

Libraries prefer operating-system-native and on-device AI capabilities so
application developers do not have to manage model files when the platform
already provides a suitable model. A package must report what the running
backend can actually do.

### Open

Universal Local AI is developed in the open. Implementations and integrations
can evolve and release independently, with their own idiomatic APIs.

## Architecture

Share code only where it is genuinely natural:

```text
dart_local_ai                  typescript_local_ai
      ↑                                ↑
flutter_local_ai                    next_local_ai
```

Pure Dart concepts and host-neutral behavior belong in `dart_local_ai`.
`flutter_local_ai` will depend on it transitively and retain only Flutter
integration and plugin packaging. The TypeScript/Next.js relationship follows
the same rule where runtime boundaries allow it. Rust stays idiomatic Rust.

The migration is incremental. Existing repositories, public APIs, histories,
tests, examples, release metadata, licenses, and CI behavior are preserved
until a reviewed import plan says otherwise. See the full
[architecture](docs/architecture.md), [API philosophy](docs/api-philosophy.md),
[project inventory](docs/projects.md), and [roadmap](docs/roadmap.md).

## Repository layout

```text
packages/       Independently publishable libraries, grouped by ecosystem
examples/       Consumer examples, separate from package implementation
docs/           Architecture, support facts, and migration decisions
.github/        Change-aware validation; publishing is intentionally absent
```

Most package directories are foundations only during Phase 1. The standalone
repositories are linked as git submodules at the top level so their history
stays intact until migration:

```text
flutter_local_ai/   kekko7072/flutter_local_ai, pinned at v0.2.1
rust_local_ai/      kekko7072/rust_local_ai API scaffold
```

Clone with `git clone --recurse-submodules`, or run
`git submodule update --init` in an existing checkout. No existing
implementation has been copied or rewritten as part of this foundation.

## Contributing

Start with [CONTRIBUTING.md](CONTRIBUTING.md). New backends need an implemented
adapter, runtime capability reporting, tests, and precise documentation before
they are listed as supported.

## License

This umbrella repository is available under the [MIT License](LICENSE).
Imported projects retain their applicable license and attribution.

Universal Local AI is a [vezz.io](https://vezz.io) open-source project.
