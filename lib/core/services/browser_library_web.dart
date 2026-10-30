import 'dart:convert';
import 'dart:js_interop';

import 'package:classipod/core/models/music_metadata.dart';

@JS('classipodLibrary.list')
external JSPromise<JSString> _listSongs();

@JS('classipodLibrary.offlineReady')
external JSPromise<JSBoolean> _offlineReady();

Future<bool> browserOfflineReady() async =>
    (await _offlineReady().toDart).toDart;

@JS('classipodLibrary.importSongs')
external JSPromise<JSNumber> _importSongs();

Future<List<MusicMetadata>> readBrowserSongs() async {
  final rows = jsonDecode((await _listSongs().toDart).toDart) as List;
  return [
    for (final row in rows)
      MusicMetadata(
        songId: row['id'] as String,
        filePath: row['path'] as String,
        contentUri: row['url'] as String,
        trackName: row['title'] as String,
        trackArtistNames: row['artist'] == null
            ? null
            : [row['artist'] as String],
        albumName: row['album'] as String?,
        thumbnailPath: row['artwork'] as String?,
        mimeType: row['mime'] as String?,
      ),
  ];
}

Future<int> importBrowserSongs() async =>
    (await _importSongs().toDart).toDartInt;

// Saved playlists contain an old page's blob URLs. Resolve by stable identity
// against this page's object URLs before handing a song to the audio player.
Future<MusicMetadata> resolveBrowserSong(MusicMetadata song) async {
  if (!(song.songId?.startsWith('browser:') ?? false)) return song;
  final songs = await readBrowserSongs();
  final current = songs.where((s) => s.identity == song.identity).firstOrNull;
  if (current == null) {
    throw StateError(
      'This song is no longer in browser storage. Import it again.',
    );
  }
  return song.copyWith(contentUri: current.contentUri);
}
