import 'dart:async';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/settings/controller/library_experience_controller.dart';
import 'package:classipod/features/settings/widgets/settings_list_tile.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String songViewTitle(BuildContext context, SongView view) => switch (view) {
  SongView.compact => context.localization.songViewCompact,
  SongView.list => context.localization.songViewList,
  SongView.artwork => context.localization.songViewArtwork,
  SongView.covers => context.localization.songViewCovers,
};

class LibraryExperienceScreen extends ConsumerStatefulWidget {
  const LibraryExperienceScreen({super.key});
  @override
  ConsumerState<LibraryExperienceScreen> createState() =>
      _LibraryExperienceScreenState();
}

class _LibraryExperienceScreenState
    extends ConsumerState<LibraryExperienceScreen>
    with CustomScreen {
  @override
  String get routeName => Routes.libraryExperience.name;
  @override
  List<int> get displayItems => const [0, 1, 2, 3, 4, 5];

  @override
  void onSelectPressed() => _select(selectedDisplayItem);

  void _select(int index) {
    setState(() => selectedDisplayItem = index);
    final controller = ref.read(libraryExperienceProvider.notifier);
    final settings = ref.read(libraryExperienceProvider);
    switch (index) {
      case 0:
        unawaited(
          controller.setView(
            SongView.values[(settings.songView.index + 1) %
                SongView.values.length],
          ),
        );
      case 1:
        unawaited(controller.toggleAcceleration());
      case 2:
        unawaited(controller.toggleFeedback());
      case 3:
        unawaited(controller.cycleWheelColor());
      case 4:
        unawaited(controller.cycleWheelLabelColor());
      case 5:
        unawaited(controller.toggleWheelStyle());
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(libraryExperienceProvider);
    final l = context.localization;
    final titles = [
      l.songViewSetting,
      l.wheelResponseSetting,
      l.wheelFeedbackSetting,
      'Wheel color',
      'Wheel text & icons',
      'Wheel style',
    ];
    final values = [
      songViewTitle(context, settings.songView),
      settings.acceleratedWheel
          ? l.wheelResponseSmooth
          : l.wheelResponsePrecise,
      settings.wheelFeedback == WheelFeedback.soft
          ? l.wheelFeedbackSoft
          : l.wheelFeedbackCrisp,
      settings.wheelColor.name,
      settings.wheelLabelColor.name,
      settings.wheelStyle == WheelStyle.classic
          ? 'Current'
          : 'First generation',
    ];
    return CupertinoPageScaffold(
      child: ListView.builder(
        controller: scrollController,
        itemExtent: displayTileHeight,
        itemCount: displayItems.length,
        itemBuilder: (context, index) => SettingsListTile(
          text: titles[index],
          value: values[index],
          isSelected: selectedDisplayItem == index,
          onTap: () => _select(index),
        ),
      ),
    );
  }
}
