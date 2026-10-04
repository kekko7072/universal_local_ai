# typescript_local_ai

Final monorepo path for the `typescript_local_ai` npm package. Until its
history is imported, the source lives in
[`kekko7072/typescript_local_ai`](https://github.com/kekko7072/typescript_local_ai),
linked here as the top-level `typescript_local_ai/` submodule.

One package with a subpath for each framework:

```ts
import { LocalAi } from 'typescript_local_ai';                   // plain TS
import { useLocalAi } from 'typescript_local_ai/react';          // React / Next.js client
import { useLocalAi } from 'typescript_local_ai/vue';            // Vue / Nuxt
import { localAi } from 'typescript_local_ai/svelte';            // Svelte / SvelteKit
import { createLocalAiRoute } from 'typescript_local_ai/next';   // Next.js server
```

This replaces the previously planned `next_local_ai` package. Not yet
published to npm.
