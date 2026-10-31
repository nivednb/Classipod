import 'package:classipod/core/models/music_metadata.dart';

Future<List<MusicMetadata>> readBrowserSongs() async => [];
Future<int> importBrowserSongs() async => 0;
Future<List<Map<String, String>>> pickBrowserPlaylists() async => [];
Future<MusicMetadata> resolveBrowserSong(MusicMetadata song) async => song;

Future<bool> browserOfflineReady() async => false;
