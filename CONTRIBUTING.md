# Contributing to Universal Local AI

Thank you for helping make native, local AI accessible from more ecosystems.

## Before opening a change

1. Check the roadmap and existing issues.
2. Keep changes scoped to one package family when possible.
3. Discuss public API breaks and new backend abstractions before implementing
   them.
4. Never claim support from SDK availability alone. Include implementation,
   runtime capability detection, tests, and documentation.

## Design rules

- Put reusable, Flutter-independent Dart code in `dart_local_ai`; Flutter code
  depends on it, never the reverse.
- Put reusable, framework-independent TypeScript code in the
  `typescript_local_ai` core. The React, Vue, Svelte and Next.js subpaths stay
  thin adapters over it and never keep a second copy of behavior.
- Prefer each language's conventions over mechanically identical APIs.
- Add abstractions in response to demonstrated implementations, not imagined
  future needs.
- Do not duplicate an implementation across related packages.
- Preserve package compatibility unless a breaking change is deliberate,
  documented, and released accordingly.

## Development workflow

Each package owns its toolchain, tests, examples, and release metadata. Run the
checks documented by the package you change. Root CI selects affected package
families and will grow package-specific jobs as implementations arrive.

Documentation-only changes should keep factual statuses and platform claims
traceable to an implementation, test, registry, or upstream project.

## Commits and pull requests

- Explain the user-visible outcome and why the chosen ownership boundary is
  correct.
- Add or update tests for behavior changes.
- Update platform and capability documentation when a backend changes.
- Include migration notes for public API changes.
- Do not include generated build output or credentials.

Publishing is a separate, explicitly authorized operation that runs in each
package's own repository; see [docs/releasing.md](docs/releasing.md). Merging a pull
request in this umbrella repository must not publish a package.
