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

The unsigned iOS build subsequently passed on the GitHub macOS runner:
https://github.com/nivednb/Classipod/actions/runs/39920296286

Not performed: physical iPhone folder permission and playlist picker checks,
haptic comparison with SepiaPod, background playback acceptance, signing or
sideloading. No personal music library was available on this host.

## Home Screen web extension — 2026-10-23

- Flutter analysis: no issues; final local pass 34.8 s.
- Full Flutter regression suite: all 201 tests passed (42 s after native setup),
  before the final browser-only duration/cache refinements.
- Browser-library/service-worker tests in Node: 5 passed, including persistence
  across page contexts, Unicode filenames, replacement URLs, cancellation,
  storage failure and offline navigation fallback.
- PWA build/manifest checks in Python: 3 passed; icon filenames match disk case.

Physical Safari installation, storage retention under iOS pressure and locked
screen playback still require checks on the user's iPhone.

Final deployment: https://nivednb.github.io/Classipod/

The final GitHub Pages workflow passed analysis, JavaScript/Python checks and
release compilation. Live Chromium checks confirmed:

- Generated WAV import and persistence after closing/reopening the app.
- M3U8 import preserving two repeated entries, with zero unresolved references.
- Playback from the saved playlist after reopening, advancing to entry 2 of 2,
  with the correct three-second duration.
- “Offline app ready” and successful HTTP responses for all 48 cached resources.
- Content-versioned JavaScript entrypoints loaded after a deployment update.

This verifies cache readiness and the offline fallback test, not a physical
Safari airplane-mode or lock-screen test. No personal audio was uploaded.


## Shared web app and recent updates — 2026-10-31

- Public Pages URL responds without authentication and provides a standalone
  web manifest and a versioned service worker.
- Browser preview verified first-generation split-screen on/off, local audio
  import, M3U8 import and re-import adding a newly matched song without creating
  another playlist. Language grouping reflected the imported named playlist.
- The first-generation pixel theme was visually inspected in a browser; GitHub
  Pages release checks, including theme, playlist and language tests, passed.
- The owner reported that playlist import works on their iPhone. This is not a
  test of a second person's device, iOS storage eviction, every audio codec,
  offline playback in airplane mode, or all browser versions.
