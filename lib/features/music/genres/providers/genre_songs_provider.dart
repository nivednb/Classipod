import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/utils/library_languages.dart';
import 'package:classipod/features/music/genres/providers/playlist_language_provider.dart';
import 'package:classipod/features/music/songs/provider/songs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final genreSongsMetadataListProvider = Provider.autoDispose
    .family<List<MusicMetadata>, String>((ref, genreName) {
      final List<MusicMetadata> genreSongsMetadataList = [];

      final languages = ref.watch(playlistLanguagesProvider);
      for (final metadata in ref.watch(songsProvider)) {
        if (libraryCategories(
          metadata,
          playlistLanguages: languages[metadata.identity] ?? const [],
        ).contains(genreName)) {
          genreSongsMetadataList.add(metadata);
        }
      }

      return genreSongsMetadataList;
    });
