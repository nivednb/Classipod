import 'package:classipod/core/utils/library_languages.dart';
import 'package:classipod/features/music/playlist/providers/playlists_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final playlistLanguagesProvider = Provider<Map<String, Set<String>>>((ref) {
  final languages = <String, Set<String>>{};
  for (final playlist in ref.watch(playlistsProvider)) {
    final language = playlistLanguage(playlist.name);
    if (language == null) continue;
    for (final song in playlist.songs) {
      (languages[song.identity] ??= {}).add(language);
    }
  }
  return languages;
});
