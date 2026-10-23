import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/features/music/folders/models/folder_index.dart';

class LocalPlaylistImport {
  final List<MusicMetadata> songs;
  final List<String> unresolved;
  const LocalPlaylistImport(this.songs, this.unresolved);
}

/// Imports local M3U/M3U8 references, including relocated Windows libraries.
/// It only resolves to indexed songs, never opens a file or fetches a URL.
LocalPlaylistImport parseLocalPlaylist(
  String text,
  FolderIndex index, {
  String? playlistDirectory,
}) {
  final songs = <MusicMetadata>[];
  final unresolved = <String>[];
  for (final line in text.replaceFirst('\uFEFF', '').split(RegExp(r'\r?\n'))) {
    final reference = line.trim();
    if (reference.isEmpty || reference.startsWith('#')) continue;
    if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(reference) &&
        !reference.startsWith('file:')) {
      unresolved.add(reference);
      continue;
    }
    String path;
    try {
      path = normalizeLibraryPath(reference);
    } on FormatException {
      unresolved.add(reference);
      continue;
    }
    final absolute =
        path.startsWith('/') || RegExp(r'^[A-Za-z]:/').hasMatch(path);
    MusicMetadata? song = index.songsByPath[path];
    if (song == null && !absolute && playlistDirectory != null) {
      song = index
          .songsByPath[normalizeLibraryPath('$playlistDirectory/$reference')];
    }
    // Longest unique suffix permits moving a music tree from PC to iPhone.
    // An ambiguous filename is never guessed.
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (song == null) {
      for (var start = 0; start < segments.length; start++) {
        final suffix = segments.skip(start).join('/');
        final candidates = index.songsByPath.entries
            .where(
              (entry) => entry.key == suffix || entry.key.endsWith('/$suffix'),
            )
            .toList();
        if (candidates.length > 1) break;
        if (candidates.length == 1) {
          song = candidates.single.value;
          break;
        }
      }
    }
    if (song == null) {
      unresolved.add(reference);
    } else {
      songs.add(song);
    }
  }
  return LocalPlaylistImport(songs, unresolved);
}
