import 'dart:io';
import 'dart:ui' as ui;

import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/features/music/songs/widgets/music_view_tile.dart';
import 'package:classipod/features/settings/controller/library_experience_controller.dart';
import 'package:classipod/l10n/generated/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all layouts fit a narrow screen and preserve touch actions', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final font = FontLoader('Helvetica')
        ..addFont(rootBundle.load('assets/fonts/Helvetica.ttf'));
      await font.load();
    });
    var taps = 0;
    var holds = 0;
    final track = MusicMetadata(
      trackName: 'Malare · A long multilingual song title',
      trackArtistNames: ['Vijay Yesudas'],
      filePath: '/Music/Malare.m4a',
    );
    const capture = ValueKey('music-view-gallery');
    await tester.pumpWidget(
      ProviderScope(
        child: CupertinoApp(
          theme: const CupertinoThemeData(
            textTheme: CupertinoTextThemeData(
              textStyle: TextStyle(fontFamily: 'Helvetica', fontSize: 14),
            ),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Center(
            child: RepaintBoundary(
              key: capture,
              child: SizedBox(
                width: 240,
                height: 430,
                child: ColoredBox(
                  color: CupertinoColors.white,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'CLASSIPOD · SONG VIEWS',
                        style: TextStyle(fontSize: 12),
                      ),
                      for (final view in SongView.values) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 3),
                          child: Text(
                            view.name.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        MusicViewTile(
                          song: track,
                          view: view,
                          selected: true,
                          playing: true,
                          onTap: () => taps++,
                          onLongPress: () => holds++,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    for (final tile in find.byType(MusicViewTile).evaluate()) {
      final finder = find.byWidget(tile.widget);
      await tester.tap(finder);
      await tester.longPress(finder);
    }
    expect(taps, 4);
    expect(holds, 4);
    expect(tester.takeException(), isNull);
    final output = Platform.environment['CLASSIPOD_CAPTURE'];
    if (output != null) {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        final image = await boundary.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(output).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
