import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/theme/ipod_gradients.dart';
import 'package:classipod/core/widgets/album_art_song_list_tile.dart';
import 'package:classipod/core/widgets/artwork_image.dart';
import 'package:classipod/features/music/songs/widgets/song_list_tile.dart';
import 'package:classipod/features/settings/controller/library_experience_controller.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MusicViewTile extends ConsumerWidget {
  final MusicMetadata song;
  final SongView view;
  final bool selected;
  final bool playing;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MusicViewTile({
    super.key,
    required this.song,
    required this.view,
    required this.selected,
    required this.playing,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (view == SongView.list) {
      return SongListTile(
        songName: song.trackName,
        trackArtistNames: song.getTrackArtistNames,
        isSelected: selected,
        isCurrentlyPlaying: playing,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }
    if (view == SongView.artwork) {
      return AlbumArtSongListTile(
        songMetadata: song,
        isSelected: selected,
        isCurrentlyPlaying: playing,
        onTap: onTap,
        onLongPress: onLongPress,
      );
    }
    final textColor = selected
        ? context.appInverseTextColor
        : context.appPrimaryTextColor;
    return Semantics(
      button: true,
      selected: selected,
      label: '${song.getTrackName}, ${song.getMainArtistName}',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: view.extent,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            gradient: selected ? IpodGradients.selectionFor(context) : null,
          ),
          child: Row(
            children: [
              if (view == SongView.covers) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image(
                    image: artworkImage(ref, song.thumbnailPath),
                    width: 104,
                    height: 104,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 104,
                      height: 104,
                      child: Icon(CupertinoIcons.music_note, size: 42),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.getTrackName,
                      maxLines: view == SongView.covers ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (view == SongView.covers) ...[
                      const SizedBox(height: 6),
                      Text(
                        song.getMainArtistName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textColor, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              if (playing)
                Icon(CupertinoIcons.volume_up, size: 16, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}
