# Personal player validation

Validated on Linux on 2026-10-23 with Flutter 3.47.6 / Dart 3.13.5.
Base: `772a6d3533677bfa78f9251a40df8fa8ca3e6180`.

- `flutter gen-l10n`: passed.
- `flutter analyze --suppress-analytics`: no issues (25.1 s).
- `flutter test --no-pub --coverage --suppress-analytics`: 201 tests passed.
- `flutter build web --release --no-pub`: passed (80.5 s).
- `git diff --check`: passed.

The tests cover angular wheel steps, reversal, seam crossing, release/reset,
acceleration bounds, real touch gestures and existing player interactions;
folder hierarchy, Unicode/Windows paths, M3U8 order and repeats, relocated
paths and ambiguous filenames; persisted display settings and all four song
layouts at 240 logical pixels. Existing native metadata-reader tests also
passed for the supplied MP3, M4A, FLAC, OGG, Opus and WAV fixtures.

The JavaScript web build succeeds. Upstream universal_html dependencies produce
Wasm compatibility warnings during the optional dry run; no Wasm build is
claimed.

Not performed: macOS/Xcode compilation, physical iPhone folder permission and
playlist picker checks, haptic comparison with SepiaPod, background playback
acceptance, signing or sideloading. No personal music library was available on
this host. The macOS GitHub Actions build workflow is included but was not run.
