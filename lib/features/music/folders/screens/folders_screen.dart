import 'dart:convert';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/extensions/go_router_extensions.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/core/theme/ipod_gradients.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/music/folders/models/folder_index.dart';
import 'package:classipod/features/music/folders/models/local_playlist_import.dart';
import 'package:classipod/features/music/playlist/models/playlist_model.dart';
import 'package:classipod/features/music/playlist/providers/playlists_provider.dart';
import 'package:classipod/features/music/songs/provider/songs_provider.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final folderIndexProvider = Provider<FolderIndex>((ref) {
  return FolderIndex(ref.watch(songsProvider));
});

class FoldersScreen extends ConsumerStatefulWidget {
  const FoldersScreen({super.key});
  @override
  ConsumerState<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends ConsumerState<FoldersScreen>
    with CustomScreen {
  String? _path;
  final List<({String path, int selection})> _parents = [];
  bool _importing = false;

  @override
  String get routeName => Routes.folders.name;
  @override
  String get screenStateKey => routeName;
  @override
  double get displayTileHeight => 54;
  FolderIndex get _index => ref.read(folderIndexProvider);
  String get _currentPath => _path ?? _index.root;
  @override
  List<FolderEntry> get displayItems => _index.children(_currentPath);

  @override
  Future<void> onSelectPressed() async {
    if (displayItems.isNotEmpty) await _select(selectedDisplayItem);
  }

  @override
  void onMenuButtonPressed() {
    if (_parents.isEmpty) {
      super.onMenuButtonPressed();
      return;
    }
    final parent = _parents.removeLast();
    setState(() {
      _path = parent.path;
      selectedDisplayItem = parent.selection;
    });
    revealDisplayItem(parent.selection);
  }

  @override
  Future<void> onSelectLongPress() async {
    if (displayItems.isEmpty) return;
    final entry = displayItems[selectedDisplayItem];
    if (entry.isFolder) await _play(_index.songsIn(entry.path), 0);
  }

  Future<void> _select(int index) async {
    final entry = displayItems[index];
    setState(() => selectedDisplayItem = index);
    if (entry.isFolder) {
      _parents.add((path: _currentPath, selection: index));
      setState(() {
        _path = entry.path;
        selectedDisplayItem = 0;
      });
      if (scrollController.hasClients) scrollController.jumpTo(0);
    } else {
      final songs = displayItems
          .where((e) => !e.isFolder)
          .map((e) => e.song!)
          .toList();
      await _play(
        songs,
        songs.indexWhere((s) => s.identity == entry.song!.identity),
      );
    }
  }

  Future<void> _play(List<MusicMetadata> songs, int index) async {
    if (songs.isEmpty || index < 0) return;
    await ref
        .read(audioPlayerServiceProvider.notifier)
        .playPlaylist(
          playlistDetail: PlaylistModel(name: _currentPath, songs: songs),
          songIndex: index,
        );
    if (mounted) await context.openUniqueNamed(Routes.nowPlaying.name);
  }

  Future<void> _importPlaylist() async {
    if (_importing) return;
    setState(() => _importing = true);
    String? message;
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['m3u', 'm3u8'],
      );
      if (!mounted || result == null) return;
      final file = result;
      final path = file.path?.replaceAll('\\', '/');
      final imported = parseLocalPlaylist(
        utf8.decode(await file.readAsBytes()),
        _index,
        playlistDirectory: path == null || !path.contains('/')
            ? null
            : path.substring(0, path.lastIndexOf('/')),
      );
      if (imported.songs.isNotEmpty) {
        await ref
            .read(playlistsProvider.notifier)
            .importNamedPlaylist(
              name: file.name.replaceFirst(
                RegExp(r'\.m3u8?$', caseSensitive: false),
                '',
              ),
              songs: imported.songs,
            );
      }
      if (mounted) {
        message = context.localization.playlistImportedSummary(
          imported.songs.length,
          imported.unresolved.length,
        );
      }
    } catch (_) {
      if (mounted) message = context.localization.playlistImportFailed;
    } finally {
      if (mounted) setState(() => _importing = false);
    }
    if (!mounted || message == null) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(context.localization.playlistImportResult),
        content: Text(message!),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.localization.playlistImportDone),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(folderIndexProvider);
    final l = context.localization;
    final title = _parents.isEmpty
        ? l.musicLibraryRoot
        : _currentPath.split('/').last;
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Row(
            children: [
              if (_parents.isNotEmpty)
                CupertinoButton(
                  padding: const EdgeInsets.all(6),
                  onPressed: onMenuButtonPressed,
                  child: Icon(
                    CupertinoIcons.chevron_left,
                    semanticLabel: l.backToParentFolder,
                    size: 18,
                  ),
                ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(6),
                onPressed: _importing ? null : _importPlaylist,
                child: _importing
                    ? const CupertinoActivityIndicator()
                    : Icon(
                        CupertinoIcons.doc_append,
                        semanticLabel: l.importLocalPlaylist,
                        size: 19,
                      ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(6),
                onPressed: displayItems.isEmpty
                    ? null
                    : () => _play(_index.songsIn(_currentPath), 0),
                child: Icon(
                  CupertinoIcons.play_fill,
                  semanticLabel: l.playFolder,
                  size: 19,
                ),
              ),
            ],
          ),
          Expanded(
            child: displayItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        l.localFoldersEmpty,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemExtent: displayTileHeight,
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final entry = displayItems[index];
                      final selected = selectedDisplayItem == index;
                      final color = selected
                          ? context.appInverseTextColor
                          : context.appPrimaryTextColor;
                      return Semantics(
                        button: true,
                        selected: selected,
                        child: GestureDetector(
                          onTap: () => _select(index),
                          onLongPress: entry.isFolder
                              ? () => _play(_index.songsIn(entry.path), 0)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? IpodGradients.selectionFor(context)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  entry.isFolder
                                      ? CupertinoIcons.folder_fill
                                      : CupertinoIcons.music_note,
                                  color: color,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (entry.isFolder)
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: color,
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
