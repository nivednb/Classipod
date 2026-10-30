import 'package:classipod/core/models/music_metadata.dart';

/// Language cues are conservative: ambiguous and multilingual titles are omitted.
List<String> libraryCategories(MusicMetadata song) {
  final categories = {...song.genres};
  final source = '${song.filePath ?? ''} ${song.trackName ?? ''}'.toLowerCase();
  final matches = <String>{};
  for (final language in ['Malayalam', 'Tamil', 'Hindi', 'English']) {
    if (RegExp('\\b${language.toLowerCase()}\\b').hasMatch(source)) {
      matches.add(language);
    }
  }
  if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(source)) matches.add('Malayalam');
  if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(source)) matches.add('Tamil');
  if (matches.length == 1) categories.add('Language: ${matches.single}');
  return categories.toList();
}
