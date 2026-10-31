import 'package:classipod/core/models/music_metadata.dart';

/// Named local playlists provide user-maintained language labels.
String? playlistLanguage(String name) {
  final normalized = name.toLowerCase().trim();
  final shortName = normalized.replaceAll(RegExp(r'\.playlist$'), '');
  switch (shortName) {
    case 'm':
      return 'Malayalam';
    case 't':
      return 'Tamil';
    case 'h':
      return 'Hindi';
    case 'e':
      return 'English';
  }
  final matches = ['Malayalam', 'Tamil', 'Hindi', 'English']
      .where(
        (language) =>
            RegExp('\\b${language.toLowerCase()}\\b').hasMatch(normalized),
      )
      .toList();
  return matches.length == 1 ? matches.single : null;
}

List<String> libraryCategories(
  MusicMetadata song, {
  Iterable<String> playlistLanguages = const [],
}) {
  final categories = {...song.genres};
  final source = '${song.filePath ?? ''} ${song.trackName ?? ''}'.toLowerCase();
  final matches = <String>{...playlistLanguages};
  for (final language in ['Malayalam', 'Tamil', 'Hindi', 'English']) {
    if (RegExp('\\b${language.toLowerCase()}\\b').hasMatch(source)) {
      matches.add(language);
    }
  }
  if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(source)) matches.add('Malayalam');
  if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(source)) matches.add('Tamil');
  if (matches.length == 1) categories.add('Language: ${matches.single}');
  if (matches.length > 1 ||
      RegExp(r'\bmultilingual\b|\bmulti[ -]?language\b').hasMatch(source)) {
    categories.add('Language: Mix');
  }
  return categories.toList();
}
