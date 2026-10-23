import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/utils/name_order.dart';

String normalizeLibraryPath(String path) {
  var value = path.replaceAll('\\', '/');
  if (value.startsWith('file:')) {
    value = Uri.parse(value).toFilePath(windows: false);
  }
  final parts = <String>[];
  for (final part in value.split('/')) {
    if (part == '.' || part.isEmpty) continue;
    if (part == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(part);
    }
  }
  return '${value.startsWith('/') ? '/' : ''}${parts.join('/')}';
}

class FolderEntry {
  final String name;
  final String path;
  final MusicMetadata? song;
  const FolderEntry({required this.name, required this.path, this.song});
  bool get isFolder => song == null;
}

/// A virtual explorer of indexed music only; it never enumerates private files.
class FolderIndex {
  final Map<String, List<FolderEntry>> _children = {};
  final Map<String, MusicMetadata> songsByPath = {};
  late final String root;

  FolderIndex(Iterable<MusicMetadata> songs) {
    for (final song in songs) {
      if (!song.isOnDevice || song.isSubsonic || song.filePath == null) {
        continue;
      }
      final path = normalizeLibraryPath(song.filePath!);
      if (path.contains('://') || !path.contains('/')) continue;
      songsByPath[path] = song;
    }
    final parents = songsByPath.keys.map((p) => p.split('/')..removeLast());
    final common = parents.isEmpty ? <String>[] : parents.first.toList();
    for (final parent in parents.skip(1)) {
      var length = 0;
      while (length < common.length &&
          length < parent.length &&
          common[length] == parent[length]) {
        length++;
      }
      common.length = length;
    }
    root = common.join('/');
    _children[root] = [];
    final folders = <String>{root};
    for (final item in songsByPath.entries) {
      final parts = item.key.split('/');
      var parent = root;
      for (var i = common.length; i < parts.length - 1; i++) {
        final child = parts.take(i + 1).join('/');
        if (folders.add(child)) {
          (_children[parent] ??= []).add(
            FolderEntry(name: parts[i], path: child),
          );
          _children[child] = [];
        }
        parent = child;
      }
      (_children[parent] ??= []).add(
        FolderEntry(name: parts.last, path: item.key, song: item.value),
      );
    }
    for (final children in _children.values) {
      children.sort(
        (a, b) => a.isFolder != b.isFolder
            ? (a.isFolder ? -1 : 1)
            : compareNames(a.name, b.name),
      );
    }
  }

  List<FolderEntry> children(String path) => _children[path] ?? const [];

  List<MusicMetadata> songsIn(String path) => songsByPath.entries
      .where((entry) => path.isEmpty || entry.key.startsWith('$path/'))
      .map((entry) => entry.value)
      .toList();
}
