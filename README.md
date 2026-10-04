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

     Dart      Flutter      Rust      Python
       │          │          │          │
       └─────┬────┘          └────┬─────┘
             │                    │
             │   TypeScript (React · Vue · Svelte · Next.js)
             │                    │
             └─────────┬──────────┘
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
| Python | [`python_local_ai`](https://github.com/kekko7072/python_local_ai) | PyPI | PyO3 bindings over `rust_local_ai` (async and sync API, typed); not published |
| TypeScript | [`typescript_local_ai`](https://github.com/kekko7072/typescript_local_ai) | npm | Scaffold: core plus `/react`, `/vue`, `/svelte` and `/next` subpaths; not published |

`typescript_local_ai` is one npm package with an entry point per framework:
plain TypeScript, React (including Next.js client components), Vue, Svelte,
and `typescript_local_ai/next` for Next.js server route handlers. The
frameworks are optional peer dependencies, so each app pulls in only its own.
The separate `next_local_ai` package is no longer planned; the `/next` subpath
replaces it.

The Flutter package currently implements Apple Foundation Models, Android ML
Kit GenAI, Windows AI Foundry, and Chrome's Prompt API with different verified
capabilities on each platform. `typescript_local_ai` has a unit-tested Chrome
Prompt API adapter, and a Node adapter that waits for the unpublished native
addon. See [platforms](docs/platforms.md) for the careful support matrix.

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
dart_local_ai             rust_local_ai ──────────────┐
      ↑                         ↑                     │ napi-rs (Node)
flutter_local_ai          python_local_ai (PyO3)      ↓
                                              typescript_local_ai
                                               ├── /react
                                               ├── /vue
                                               ├── /svelte
                                               └── /next
```

Pure Dart concepts and host-neutral behavior belong in `dart_local_ai`.
`flutter_local_ai` will depend on it transitively and retain only Flutter
integration and plugin packaging. In TypeScript, one framework-neutral core
owns the behavior; the React, Vue, Svelte and Next.js subpaths are thin
adapters over it inside the same package. Rust stays idiomatic Rust and is the
native core for the Python bindings and the Node backend.

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
flutter_local_ai/      kekko7072/flutter_local_ai, pinned at v0.2.1
rust_local_ai/         kekko7072/rust_local_ai, pinned at main
typescript_local_ai/   kekko7072/typescript_local_ai, pinned at the scaffold
python_local_ai/       kekko7072/python_local_ai, pinned at the bindings
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
