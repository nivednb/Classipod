# ClassiPod web app guide

This product includes software developed by Aditya R.
The BSD-4-Clause license and upstream attribution remain in `LICENSE`.

Based on ClassiPod commit `772a6d3` (Flutter 3.47.6). This is a personal
extension, not an official release of ClassiPod, klikWheel or SepiaPod.
The reference apps' code and artwork have not been copied.

## Library and controls

- **Music → Folders:** navigate indexed local folders, including subfolders.
  Filenames are shown so a tagged title cannot hide the actual file. Select a
  track to play the current folder's tracks. Hold a folder to play its subtree;
  the play button plays the open subtree. MENU moves to the parent folder.
  The explorer only shows indexed music. On native platforms the music root is
  configured through Settings → Library Settings → Re-index; the web uses files
  explicitly imported into the browser.
- **Playlist import:** choose **Music → Folders → Import playlists**, then
  select UTF-8 M3U/M3U8 files (multiple files on web). Import the audio first.
  The app matches
  local paths, unique relocated filename suffixes, or a unique trailing video ID;
  ambiguous and missing entries are reported. Remote URLs and HLS are not
  imported. New named playlists retain the matched order and repeated entries.
  Re-importing an existing name appends newly matched songs without removing
  existing entries; it does not reorder or remove them to mirror a changed file.
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

For faster later starts, the web app keeps a disposable on-device cache of
readable song tags and small embedded artwork. The first launch after an update
or a new import still reads the audio files; later launches reuse matching cached
metadata. Cached artwork is limited to 12 MiB in total and 256 KiB per cover;
larger or uncached covers are still read from the original audio. A missing,
blocked, or full cache falls back to normal reads. Re-imported files invalidate
their cached metadata. This cache is separate from the music database and is
not a backup of your audio.

The player uses imported music when present, otherwise the demo collection.
The **Import playlists** button imports M3U/M3U8 references after audio is
imported. Unique filename suffixes and stable IDs can match moved or renamed
files. Re-import the same named file after importing new songs; new matches are
appended, and missing entries are counted. It does not automatically monitor
files or sync playlist removals and reorderings. Keep originals:
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

## First-generation screen theme

Settings → Theme cycles through Light, Dark and First generation. The latter
uses a pale LCD palette, pixel-style Latin text (Pixelify Sans, OFL-licensed),
and a recessed screen inspired by the 2001 iPod. Split-screen can be switched
on or off in every theme. Other scripts use platform fallback fonts where
needed. Wheel color and labels remain independently chosen.

## Wheel style

Settings → Library & Wheel → Wheel style switches between the current wheel
and a first-generation-inspired wheel with four outlined outer buttons. Both
styles use the same wheel color and label color, controls, sound and preferences.
The original iPod had a physical wheel; touch behavior is an approximation.


## Share and install

Share <https://nivednb.github.io/Classipod/>. The public site has no shared
account or central music library. Each person's imports, playlists and settings
stay in that device's browser storage; the site itself is shared. People must
supply their own playable audio files and playlist files. Nothing in the link
transfers the owner's songs. The same browser/profile may share site storage
across tabs; separate devices or profiles do not automatically synchronize.

- **iPhone/iPad:** open in Safari, Share → Add to Home Screen, enable Open as
  Web App if offered, then launch the icon. Import songs in that installed app.
  See [Apple's instructions](https://support.apple.com/guide/iphone/iphea86e5236/ios).
- **Android:** open in Chrome and use the browser's Install app/Add to Home
  screen option. Labels vary by browser and version. See
  [Chrome's instructions](https://support.google.com/chrome/answer/9658361).
- **Desktop:** open the link in a supported browser. Browser install controls
  may offer a standalone window.

Open online once, wait for **Offline app ready**, and keep the originals. The
service worker caches the application shell, not network demo or server audio.
Each imported song is a local browser-storage copy. Storage quotas vary; large
imports may fail and the OS/browser may evict data. Clearing site data or
removing a Home Screen app can delete its library. There is no cloud backup,
account system, automatic file sync or guarantee of background playback. Audio
codec support depends on browser/OS; AAC/M4A and MP3 are common choices.

**Language grouping:** embedded musical genre tags and conservative cues in
file names are shown under Genres. Imported playlists named `M.playlist`,
`T.playlist`, `H.playlist`, and `E.playlist` supply Malayalam, Tamil, Hindi,
and English labels for their matched songs. A song with multiple clear
language cues can appear under Language: Mix. Playlist membership and title
clues are not authoritative language detection; incomplete or mislabeled
files can yield incomplete or inaccurate categories. Long mixes remain single
files. Edit a local playlist and re-import it to add new matches.

**Appearance and feedback:** Settings → Theme selects the display. Settings →
Library & Wheel controls wheel color, label color, style, position and optional
3D appearance; Settings → Split Screen Mode works in every theme. Wheel click
sound is subject to browser audio rules and device volume. Safari on iPhone
does not offer the native haptic feedback used by the iOS app.

**Privacy and networking:** imported audio, playlist entries and preferences
are stored in the browser on the device. The site host receives ordinary web
requests for the app; demo tracks/artwork use remote URLs, and an optional
Subsonic connection sends requests to the configured server. Neither a public
repository nor the shared URL is a private cloud vault. Do not commit audio,
playlist files, cookies or credentials to the repository.
