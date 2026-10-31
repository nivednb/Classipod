import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/features/music/folders/models/folder_index.dart';
import 'package:classipod/features/music/folders/models/local_playlist_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MusicMetadata song(String path) => MusicMetadata(
    filePath: path,
    songId: path,
    trackName: path.split('/').last,
  );
  final tracks = [
    song('/music/Malayalam/മലരേ.m4a'),
    song('/music/Tamil/Same.mp3'),
    song('/music/Hindi/Same.mp3'),
  ];

  test('folders precede songs and remote sources are excluded', () {
    final index = FolderIndex([
      ...tracks,
      song('/music/Root.m4a'),
      MusicMetadata(filePath: 'https://example.com/a.mp3', isOnDevice: false),
      MusicMetadata(
        filePath: '/secret/stream.mp3',
        serverId: 's',
        remoteSongId: 'r',
      ),
    ]);
    expect(index.root, '/music');
    expect(index.children(index.root).map((e) => e.name), [
      'Hindi',
      'Malayalam',
      'Tamil',
      'Root.m4a',
    ]);
    expect(
      index.songsIn('/music/Tamil').single.filePath,
      '/music/Tamil/Same.mp3',
    );
  });
  test('normalizes Windows folders without merging adjacent names', () {
    final index = FolderIndex([
      song(r'C:\Music\A\one.mp3'),
      song(r'C:\Music\AB\two.mp3'),
    ]);
    expect(index.root, 'C:/Music');
    expect(index.songsIn('C:/Music/A').length, 1);
    expect(index.children('C:/Music').length, 2);
  });
  test('imports UTF-8, BOM, relative and relocated Windows paths in order', () {
    final result = parseLocalPlaylist(
      '\uFEFF#EXTM3U\n#EXTINF:200,Title\nMalayalam/മലരേ.m4a\r\n'
      'C:\\Old\\Tamil\\Same.mp3\nMalayalam/മലരേ.m4a\n',
      FolderIndex(tracks),
      playlistDirectory: '/music',
    );
    expect(result.songs.map((s) => s.filePath), [
      tracks[0].filePath,
      tracks[1].filePath,
      tracks[0].filePath,
    ]);
    expect(result.unresolved, isEmpty);
  });
  test('reports ambiguity, missing files and stream URLs without guessing', () {
    final result = parseLocalPlaylist(
      'Same.mp3\nMissing.mp3\nhttps://example.com/Same.mp3',
      FolderIndex(tracks),
    );
    expect(result.songs, isEmpty);
    expect(result.unresolved.length, 3);
  });
  test('file URI resolves only into the indexed library', () {
    final result = parseLocalPlaylist(
      'file:///music/Tamil/Same.mp3',
      FolderIndex(tracks),
    );
    expect(result.songs.single.identity, tracks[1].identity);
  });
  test('matches renamed files by unique stable video ID', () {
    final index = FolderIndex([
      song('/Browser Music/New title [abcdefghijk].m4a'),
    ]);
    final result = parseLocalPlaylist('Old title [abcdefghijk].m4a', index);
    expect(
      result.songs.single.filePath,
      '/Browser Music/New title [abcdefghijk].m4a',
    );
    expect(result.unresolved, isEmpty);
  });
  test('never guesses when a video ID matches multiple files', () {
    final index = FolderIndex([
      song('/One/a [abcdefghijk].m4a'),
      song('/Two/b [abcdefghijk].m4a'),
    ]);
    final result = parseLocalPlaylist('Old title [abcdefghijk].m4a', index);
    expect(result.songs, isEmpty);
    expect(result.unresolved, hasLength(1));
  });
}
