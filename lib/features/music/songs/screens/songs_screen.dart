import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/extensions/go_router_extensions.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/core/widgets/empty_state_widget.dart';
import 'package:classipod/core/widgets/fast_scroll_indicator.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/music/songs/provider/songs_provider.dart';
import 'package:classipod/features/music/songs/widgets/music_view_tile.dart';
import 'package:classipod/features/now_playing/provider/now_playing_details_provider.dart';
import 'package:classipod/features/settings/controller/library_experience_controller.dart';
import 'package:classipod/features/settings/screens/library_experience_screen.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SongsScreen extends ConsumerStatefulWidget {
  const SongsScreen({super.key});

  @override
  ConsumerState createState() => _SongsScreenState();
}

class _SongsScreenState extends ConsumerState<SongsScreen> with CustomScreen {
  @override
  String get screenStateKey => routeName;

  @override
  double get displayTileHeight =>
      ref.read(libraryExperienceProvider).songView.extent;

  @override
  String get routeName => Routes.songs.name;

  @override
  List<MusicMetadata> get displayItems => ref.read(songsProvider);

  @override
  Future<void> onSelectPressed() async {
    if (displayItems.isNotEmpty) await _playSong(selectedDisplayItem);
  }

  @override
  void onSelectLongPress() {
    if (displayItems.isNotEmpty) {
      _navigateToSongMoreOptionsModal(selectedDisplayItem);
    }
  }

  void _navigateToSongMoreOptionsModal(int index) {
    setState(() => selectedDisplayItem = index);
    context.goNamed(Routes.songsMoreOptions.name, extra: displayItems[index]);
  }

  Future<void> _playSong(int displayIndex) async {
    setState(() => selectedDisplayItem = displayIndex);
    final String songId = displayItems[displayIndex].identity;

    await ref
        .read(audioPlayerServiceProvider.notifier)
        .playSongFromLibrary(songId);

    if (mounted) {
      await context.openUniqueNamed(Routes.nowPlaying.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(songsProvider);
    final view = ref.watch(libraryExperienceProvider).songView;
    final String? currentlyPlayingOriginalIndex = ref
        .watch(nowPlayingDetailsProvider.select((e) => e.currentMetadata))
        ?.identity;
    if (displayItems.isEmpty) {
      return CupertinoPageScaffold(
        child: Column(
          children: [
            Expanded(
              child: EmptyStateWidget(
                emptyDescription: context.localization.noMusicFilesFound,
              ),
            ),
          ],
        ),
      );
    }

    return CupertinoPageScaffold(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              onPressed: () async {
                await ref
                    .read(libraryExperienceProvider.notifier)
                    .setView(
                      SongView.values[(view.index + 1) %
                          SongView.values.length],
                    );
                if (mounted) revealDisplayItem(selectedDisplayItem);
              },
              child: Semantics(
                label: context.localization.songViewSwitch,
                child: Text(
                  songViewTitle(context, view),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
          Flexible(
            child: FastScrollIndicator(
              wheelScrollIndex: wheelScrollIndex,
              itemCount: displayItems.length,
              itemExtent: displayTileHeight,
              labelAt: (index) =>
                  displayItems[index].trackName ??
                  context.localization.unknownSong,
              child: CupertinoScrollbar(
                controller: scrollController,
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: displayItems.length,
                  itemExtent: displayTileHeight,
                  itemBuilder: (context, index) => MusicViewTile(
                    song: displayItems[index],
                    view: view,
                    selected: selectedDisplayItem == index,
                    playing:
                        currentlyPlayingOriginalIndex ==
                        displayItems[index].identity,
                    onTap: () async => _playSong(index),
                    onLongPress: () => _navigateToSongMoreOptionsModal(index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
