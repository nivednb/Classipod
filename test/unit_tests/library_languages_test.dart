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
  test('recognizes Tamil script but avoids ambiguous multilingual mixes', () {
    expect(
      libraryCategories(MusicMetadata(trackName: 'தமிழ் பாடல்')),
      contains('Language: Tamil'),
    );
    expect(
      libraryCategories(MusicMetadata(trackName: 'Tamil Hindi mashup')),
      isEmpty,
    );
    expect(
      libraryCategories(MusicMetadata(trackName: 'Unknown song')),
      isEmpty,
    );
  });
}
