# Dart and Flutter migration

## Target

```text
ONE Dart implementation
        │
        ├── Pure Dart: dart_local_ai
        └── Flutter:   flutter_local_ai → depends on dart_local_ai
```

A user of `flutter_local_ai` receives `dart_local_ai` transitively. A user of
`dart_local_ai` can run a normal Dart CLI without the Flutter SDK.

## Proposed ownership

| Concern | Owner after migration | Reason |
|---|---|---|
| Capabilities, availability values, response values, generation options | `dart_local_ai` | Framework-neutral public concepts |
| Model/session lifecycle and host interface | `dart_local_ai` | Shared behavior and test surface |
| Schema validation and tool declarations/dispatch | `dart_local_ai` | Pure Dart logic |
| Fake host | `dart_local_ai` testing library | Shared consumer and adapter tests |
| Pure-Dart native transport | `dart_local_ai` | Required for CLI/non-Flutter use |
| Pigeon and Flutter channels | `flutter_local_ai` | Flutter runtime transport |
| Native plugin packaging and registration | `flutter_local_ai` | Flutter build system concern |
| Existing `FlutterLocalAi` facade | `flutter_local_ai` | Compatibility and Flutter-facing API |
| genUI/UI integration | `flutter_local_ai` or a later add-on | Framework-specific |

## Questions to prove with prototypes

1. Which Apple and Windows APIs can be reached safely through Dart FFI/native
   assets and build hooks while preserving async streaming and cancellation?
2. Can Android's required runtime be reached in a pure-Dart Android context,
   or should pure Dart initially support a smaller documented platform set?
3. Should browser Prompt API support live in pure Dart web code, and can it do
   so without importing Flutter web registration?
4. How should native assets be packaged independently without duplicating the
   Flutter plugin's native service implementation?

The answers may differ by platform. “One source of truth” can mean one shared
native library consumed by two transports; it does not require one transport
technology everywhere.

## Compatibility hazards

- `PlatformException` is a Flutter type and cannot appear in the pure-Dart
  contract. The Flutter adapter may translate or implement compatibility.
- Conditional exports must never select a file that imports Flutter when a
  pure-Dart consumer resolves the package.
- Web host code needs an import audit for Flutter-only helpers.
- Existing public exports and the `FlutterLocalAi` facade need golden API or
  analyzer fixtures before files move.
- Pigeon generation and native service contracts must stay versioned together
  inside the Flutter package until a shared native binary boundary exists.

## Acceptance checks

- `dart create`, `dart pub add dart_local_ai`, and `dart run` work with no
  Flutter SDK dependency in the resolution graph.
- `flutter pub add flutter_local_ai` is the only install step for Flutter users.
- No Dart implementation file is duplicated between package repositories.
- Shared tests run once in `dart_local_ai`; Flutter retains adapter and
  compatibility tests.
- Existing supported Flutter backends and API behavior do not regress.
