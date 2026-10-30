import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/features/music/album/providers/album_details_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('untagged browser songs have individual cover cards', () {
    final songs = [
      for (var i = 0; i < 320; i++)
        MusicMetadata(songId: 'browser:/song-$i.m4a', trackName: 'Song $i'),
    ];
    final albums = buildAlbumDetails(songs);
    expect(albums.length, 320);
    expect(albums.map((a) => a.coverFlowHeroTag).toSet().length, 320);
    expect(albums.every((album) => album.albumSongs.length == 1), isTrue);
    expect(albums.every((album) => album.albumName != 'Unknown Album'), isTrue);
  });

  test('songs with the same real album remain grouped', () {
    final albums = buildAlbumDetails([
      MusicMetadata(
        songId: 'browser:/a.m4a',
        trackName: 'A',
        albumName: 'Album',
        trackArtistNames: ['Artist'],
      ),
      MusicMetadata(
        songId: 'browser:/b.m4a',
        trackName: 'B',
        albumName: 'Album',
        trackArtistNames: ['Artist'],
      ),
    ]);
    expect(albums.length, 1);
    expect(albums.single.albumSongs.length, 2);
  });
}
