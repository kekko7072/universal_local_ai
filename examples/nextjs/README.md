# Next.js examples

Next.js uses two entry points of `typescript_local_ai`, not a separate
package:

- `typescript_local_ai/react` for client components, using the browser Prompt API;
- `typescript_local_ai/next` for route handlers, using the Node backend.

A runnable App Router example will be added and built in CI to catch
`"use client"`, `server-only` and hydration regressions.
