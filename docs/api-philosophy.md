# API philosophy

## Common concepts, native expression

Universal Local AI aligns mental models rather than punctuation. Dart may use
`Future` and `Stream`, Rust may use `Result` and async streams, and TypeScript
may use promises and async iterables. Callers should still recognize the same
lifecycle and capability questions.

## Availability before generation

Native model access depends on the running device. APIs should distinguish:

- whether a backend exists;
- whether it is currently available;
- whether preparation or a model download is possible;
- why it is unavailable when the platform can explain;
- which optional capabilities the active backend supports.

Applications should be able to build fallbacks without parsing error strings.

## Sessions are explicit

A model/provider creates sessions. A session owns conversational context or a
well-documented projection of it. APIs should make concurrency, cancellation,
resource cleanup, and context limits understandable for their language.

## Responses and streams

One-shot generation returns a typed response. Streaming uses the ecosystem's
normal async sequence. A backend that can only return a final chunk must say so
in its capability documentation rather than simulate incremental tokens.

## Optional capabilities

Structured output, images, token counts, model preparation, and tool calling
are capabilities, not universal guarantees. Libraries should:

1. report support at runtime where it can vary;
2. validate inputs before crossing the native boundary;
3. use the backend's real constrained mechanism when claimed;
4. throw a precise unsupported error instead of silently weakening semantics.

## Errors

Errors should be typed around actionable categories such as unavailable,
unsupported, busy, cancelled, invalid input/schema, prompt too long, content
blocked, backend configuration, and generation failure. Preserve native detail
for diagnostics without making native error strings the public contract.

## Platform detection

Platform identity is useful for diagnostics, not a substitute for capability
detection. The same OS can differ by version, hardware, user settings, runtime
installation, browser flags, and application packaging.

## Compatibility

Existing public APIs remain supported through facades or deprecation windows
where practical. New common vocabulary should not trigger gratuitous renames.
An API break requires a migration guide and an independently versioned major
or ecosystem-appropriate breaking release.
