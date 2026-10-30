import 'package:classipod/core/providers/shared_preferences_with_cache_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SongView {
  compact,
  list,
  artwork,
  covers;

  double get extent => switch (this) {
    compact => 32,
    list || artwork => 54,
    covers => 132,
  };
}

enum WheelFeedback { soft, crisp }

enum WheelColor { device, red, black, white, blue, orange, green, purple }

enum WheelLabelColor { device, white, black }

class LibraryExperience {
  final SongView songView;
  final bool acceleratedWheel;
  final WheelFeedback wheelFeedback;
  final WheelColor wheelColor;
  final WheelLabelColor wheelLabelColor;

  const LibraryExperience({
    this.songView = SongView.artwork,
    this.acceleratedWheel = true,
    this.wheelFeedback = WheelFeedback.soft,
    this.wheelColor = WheelColor.device,
    this.wheelLabelColor = WheelLabelColor.device,
  });
}

final libraryExperienceProvider =
    NotifierProvider<LibraryExperienceController, LibraryExperience>(
      LibraryExperienceController.new,
    );

class LibraryExperienceController extends Notifier<LibraryExperience> {
  @override
  LibraryExperience build() {
    final preferences = ref.watch(sharedPreferencesWithCacheProvider).value;
    if (preferences == null) return const LibraryExperience();
    final savedView = preferences.getString('librarySongView');
    return LibraryExperience(
      songView:
          SongView.values.where((v) => v.name == savedView).firstOrNull ??
          SongView.artwork,
      acceleratedWheel: preferences.getBool('acceleratedWheel') ?? true,
      wheelColor:
          WheelColor.values
              .where((v) => v.name == preferences.getString('wheelColor'))
              .firstOrNull ??
          WheelColor.device,
      wheelLabelColor:
          WheelLabelColor.values
              .where((v) => v.name == preferences.getString('wheelLabelColor'))
              .firstOrNull ??
          WheelLabelColor.device,
      wheelFeedback: preferences.getString('wheelFeedback') == 'crisp'
          ? WheelFeedback.crisp
          : WheelFeedback.soft,
    );
  }

  Future<void> reset() async {
    state = const LibraryExperience();
    final preferences = ref
        .read(sharedPreferencesWithCacheProvider)
        .requireValue;
    await preferences.remove('librarySongView');
    await preferences.remove('acceleratedWheel');
    await preferences.remove('wheelFeedback');
    await preferences.remove('wheelColor');
    await preferences.remove('wheelLabelColor');
  }

  Future<void> setView(SongView view) async {
    state = LibraryExperience(
      songView: view,
      acceleratedWheel: state.acceleratedWheel,
      wheelFeedback: state.wheelFeedback,
      wheelColor: state.wheelColor,
      wheelLabelColor: state.wheelLabelColor,
    );
    await ref
        .read(sharedPreferencesWithCacheProvider)
        .requireValue
        .setString('librarySongView', view.name);
  }

  Future<void> toggleAcceleration() async {
    state = LibraryExperience(
      songView: state.songView,
      acceleratedWheel: !state.acceleratedWheel,
      wheelFeedback: state.wheelFeedback,
      wheelColor: state.wheelColor,
      wheelLabelColor: state.wheelLabelColor,
    );
    await ref
        .read(sharedPreferencesWithCacheProvider)
        .requireValue
        .setBool('acceleratedWheel', state.acceleratedWheel);
  }

  Future<void> toggleFeedback() async {
    state = LibraryExperience(
      songView: state.songView,
      acceleratedWheel: state.acceleratedWheel,
      wheelColor: state.wheelColor,
      wheelLabelColor: state.wheelLabelColor,
      wheelFeedback: state.wheelFeedback == WheelFeedback.soft
          ? WheelFeedback.crisp
          : WheelFeedback.soft,
    );
    await ref
        .read(sharedPreferencesWithCacheProvider)
        .requireValue
        .setString('wheelFeedback', state.wheelFeedback.name);
  }

  Future<void> cycleWheelColor() async {
    final next = WheelColor
        .values[(state.wheelColor.index + 1) % WheelColor.values.length];
    state = LibraryExperience(
      songView: state.songView,
      acceleratedWheel: state.acceleratedWheel,
      wheelFeedback: state.wheelFeedback,
      wheelColor: next,
      wheelLabelColor: state.wheelLabelColor,
    );
    await ref
        .read(sharedPreferencesWithCacheProvider)
        .requireValue
        .setString('wheelColor', next.name);
  }

  Future<void> cycleWheelLabelColor() async {
    final next =
        WheelLabelColor.values[(state.wheelLabelColor.index + 1) %
            WheelLabelColor.values.length];
    state = LibraryExperience(
      songView: state.songView,
      acceleratedWheel: state.acceleratedWheel,
      wheelFeedback: state.wheelFeedback,
      wheelColor: state.wheelColor,
      wheelLabelColor: next,
    );
    await ref
        .read(sharedPreferencesWithCacheProvider)
        .requireValue
        .setString('wheelLabelColor', next.name);
  }
}
