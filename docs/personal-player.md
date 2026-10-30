# Personal library player

This product includes software developed by Aditya R.
The BSD-4-Clause license and upstream attribution remain in `LICENSE`.

Based on ClassiPod commit `772a6d3` (Flutter 3.47.6). This is a personal
extension, not an official release of ClassiPod, klikWheel or SepiaPod.
The reference apps' code and artwork have not been copied.

## First implementation

- **Music → Folders:** navigate indexed local folders, including subfolders.
  Filenames are shown so a tagged title cannot hide the actual file. Select a
  track to play the current folder's tracks. Hold a folder to play its subtree;
  the play button plays the open subtree. MENU moves to the parent folder.
  The explorer only shows indexed music; choose/change the allowed music root
  through Settings → Library Settings → Re-index as in upstream.
- **Playlist import:** use the document-plus button in Folders for a UTF-8 M3U
  or M3U8 file. Track order and repeated references are preserved. Relative
  paths, file URIs and uniquely matching relocated path suffixes are supported.
  Duplicate filenames are not guessed; the result reports unresolved items.
  Only indexed local songs can be imported. HLS and remote stream URLs are not
  supported. Imports create a saved playlist and do not overwrite another one.
- **Song views:** Compact, List, Artwork and Covers. Cycle the button above
  Music → Songs, or choose Settings → Library & Wheel → Song view. Upstream
  Music → Cover Flow retains both Original and Big album layouts.
- **Wheel:** angular movement, accumulated slow detents, immediate reversal,
  bounded acceleration and no post-release drift. Existing sensitivity controls
  change the angular detent spacing. Library & Wheel offers Smooth/Precise
  response and Soft/Crisp iOS selection feedback. Existing Vibration and Click
  Sound settings still control whether feedback is enabled.
- Scroll bounds use the actual list viewport and row size, so selection stays
  visible across the display modes.

New labels fall back to English until translations are supplied. Display and
wheel settings persist independently of existing preferences.

## Build and install

Use Flutter 3.47.6. From the repository root:

```sh
flutter pub get --suppress-analytics
flutter gen-l10n
flutter analyze --suppress-analytics
flutter test --no-pub --coverage --suppress-analytics
```

The `Personal player checks and iPhone build` GitHub Actions workflow checks
the feature branch without publishing a website or app release. Once the
workflow is on the selected branch, use Run workflow and enable `build_ios`
to build an unsigned IPA on a macOS runner. It uploads a workflow artifact,
not an App Store build. No developer credentials belong in this repository.

For a local iPhone build on a Mac with Xcode:

```sh
bash scripts/package_apple_release.sh ios
```

Sign/install the resulting IPA through a compatible sideloading tool. See
`docs/apple-releases.md` for upstream installation details and account limits.
Linux and Windows cannot locally build the iOS target. A browser preview can
exercise the views with demo music, but cannot validate native folder access,
background playback or iPhone haptics.

## Device acceptance checks

1. Select a music folder on iPhone; confirm nested folders and Unicode filenames.
2. Open several folders with the wheel. MENU must restore the previous folder
   and selection. Hold a folder to check the subtree queue.
3. Import a relative M3U8 playlist. Confirm imported order and missing-file count.
   Repeat with duplicate filenames in different directories and a PC-origin list.
4. Cycle every song view while near the end of a long list. Check selection,
   touch, wheel, artwork fallback and no overflow on the iPhone SE display.
5. Compare slow turns, fast spins, reversal and centre presses with SepiaPod.
   Tune sensitivity/response/feedback; this implementation does not claim an
   exact match to SepiaPod without physical-device comparison.
6. Relaunch, verify preferences, then check airplane mode, screen lock,
   Bluetooth controls and background playback.

Consult `docs/personal-player-validation.md` for checks actually performed.

## Home Screen web version

Open the personal GitHub Pages player in Safari, then use Share → Add to Home
Screen. Launch that icon before importing music: Safari tabs and Home Screen
apps may have separate storage on iOS.

Music → Folders → Import songs from Files copies selected audio into this
site's IndexedDB on the device. Music is never uploaded to the repository.
Imports read embedded title, artist, album and artwork locally when available.
Files without readable tags use their filename as a title; a trailing video ID
is hidden in the displayed title while the stored file identity stays unchanged.
Browser songs without album tags appear as separate Cover Flow cards. Selecting the same filename again replaces
that entry. iPhone's Files picker usually provides individual files, so a folder
hierarchy is not promised there. Supported playback formats depend on Safari;
start with MP3 or M4A.

The player uses imported music when present, otherwise the demo collection.
The existing document button imports M3U/M3U8 references after audio is imported.
Relative playlist references can match unique filename suffixes. Keep originals:
iOS can remove browser storage under storage pressure or after clearing website
data. Refresh/reopen resolves fresh audio URLs for saved playlists.

The Pages workflow caches the app shell and includes the Flutter engine locally.
For offline use, first open the app online and wait for “Offline app ready” in Music → Folders.
Imported audio then plays without downloading it from a server. Remote demo and
Subsonic streams still require a connection. Browser background/lock-screen
playback and iOS haptics remain subject to Safari limitations. Physical iPhone
Home Screen installation and persistence must be tested on the user's device.

Deployment is handled only by `.github/workflows/personal-web.yaml`; Pages must
use the GitHub Actions source. No native signing or Apple account is required.

## Wheel appearance and feedback

Settings → Library & Wheel provides independent wheel color and wheel text/icon
color choices. Device preserves the existing device theme. Click Sound and
Vibrate are controlled by their existing Settings switches. On the web, click
audio is unlocked by a wheel gesture and may depend on the device audio mode.
Native iOS uses platform haptics; Safari does not expose general vibration for
wheel detents. iPhone sound and haptics require physical-device validation.
