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

enum WheelStyle { classic, firstGeneration }

enum WheelPosition { normal, higher, lower }

class LibraryExperience {
  final SongView songView;
  final bool acceleratedWheel;
  final WheelFeedback wheelFeedback;
  final WheelColor wheelColor;
  final WheelLabelColor wheelLabelColor;
  final WheelStyle wheelStyle;
  final WheelPosition wheelPosition;

  const LibraryExperience({
    this.songView = SongView.artwork,
    this.acceleratedWheel = true,
    this.wheelFeedback = WheelFeedback.soft,
    this.wheelColor = WheelColor.device,
    this.wheelLabelColor = WheelLabelColor.device,
    this.wheelStyle = WheelStyle.classic,
    this.wheelPosition = WheelPosition.normal,
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
      wheelStyle:
          WheelStyle.values
              .where((v) => v.name == preferences.getString('wheelStyle'))
              .firstOrNull ??
          WheelStyle.classic,
      wheelPosition:
          WheelPosition.values
              .where((v) => v.name == preferences.getString('wheelPosition'))
              .firstOrNull ??
          WheelPosition.normal,
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
    await preferences.remove('wheelStyle');
    await preferences.remove('wheelPosition');
  }

  Future<void> setView(SongView view) async {
    state = LibraryExperience(
      songView: view,
      acceleratedWheel: state.acceleratedWheel,
      wheelFeedback: state.wheelFeedback,
      wheelColor: state.wheelColor,
      wheelLabelColor: state.wheelLabelColor,
      wheelStyle: state.wheelStyle,
      wheelPosition: state.wheelPosition,
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
      wheelStyle: state.wheelStyle,
      wheelPosition: state.wheelPosition,
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
      wheelStyle: state.wheelStyle,
      wheelPosition: state.wheelPosition,
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
      wheelStyle: state.wheelStyle,
      wheelPosition: state.wheelPosition,
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
      wheelStyle: state.wheelStyle,
      wheelPosition: state.wheelPosition,
    );
    await ref
        .read(sharedPreferencesWithCacheProvider)
        .requireValue
        .setString('wheelLabelColor', next.name);
  }

  Future<void> toggleWheelStyle() async {
    final next = state.wheelStyle == WheelStyle.classic
        ? WheelStyle.firstGeneration
        : WheelStyle.classic;
    state = LibraryExperience(
      songView: state.songView,
      acceleratedWheel: state.acceleratedWheel,
      wheelFeedback: state.wheelFeedback,
      wheelColor: state.wheelColor,
      wheelLabelColor: state.wheelLabelColor,
      wheelStyle: next,
      wheelPosition: state.wheelPosition,
    );
    await ref
        .read(sharedPreferencesWithCacheProvider)
        .requireValue
        .setString('wheelStyle', next.name);
  }

  Future<void> cycleWheelPosition() async {
    final next = WheelPosition
        .values[(state.wheelPosition.index + 1) % WheelPosition.values.length];
    state = LibraryExperience(
      songView: state.songView,
      acceleratedWheel: state.acceleratedWheel,
      wheelFeedback: state.wheelFeedback,
      wheelColor: state.wheelColor,
      wheelLabelColor: state.wheelLabelColor,
      wheelStyle: state.wheelStyle,
      wheelPosition: next,
    );
    await ref
        .read(sharedPreferencesWithCacheProvider)
        .requireValue
        .setString('wheelPosition', next.name);
  }
}
