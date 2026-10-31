import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/utils/library_languages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes explicit language and preserves musical genre', () {
    final categories = libraryCategories(
      MusicMetadata(
        filePath: '/Malayalam Hits/song.m4a',
        genres: const ['Pop'],
      ),
    );
    expect(categories, containsAll(['Pop', 'Language: Malayalam']));
  });
  test('recognizes Tamil script and labels multilingual mixes', () {
    expect(
      libraryCategories(MusicMetadata(trackName: 'தமிழ் பாடல்')),
      contains('Language: Tamil'),
    );
    expect(
      libraryCategories(MusicMetadata(trackName: 'Tamil Hindi mashup')),
      contains('Language: Mix'),
    );
    expect(
      libraryCategories(MusicMetadata(trackName: 'Unknown song')),
      isEmpty,
    );
  });
  test('user-maintained named playlists supply language labels', () {
    expect(playlistLanguage('M.playlist'), 'Malayalam');
    expect(playlistLanguage('H.playlist'), 'Hindi');
    expect(playlistLanguage('E.playlist'), 'English');
    expect(playlistLanguage('T.playlist'), 'Tamil');
    expect(playlistLanguage('R.playlist'), isNull);
    final song = MusicMetadata(trackName: 'Song');
    expect(
      libraryCategories(song, playlistLanguages: ['Hindi']),
      contains('Language: Hindi'),
    );
    expect(
      libraryCategories(song, playlistLanguages: ['Hindi', 'Tamil']),
      contains('Language: Mix'),
    );
  });
}
