import 'dart:async';
import 'dart:io';

import 'package:classipod/core/services/audio_player_service.dart';
import 'package:classipod/core/services/click_sound_service.dart';
import 'package:classipod/features/device/models/device_action.dart';
import 'package:classipod/features/settings/controller/library_experience_controller.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

final clickWheelGestureProvider =
    NotifierProvider<ClickWheelGestureNotifier, bool>(
      ClickWheelGestureNotifier.new,
    );

class ClickWheelGestureNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  set active(bool value) => state = value;
}

final deviceButtonsServiceProvider =
    NotifierProvider<DeviceButtonsServiceNotifier, DeviceAction?>(
      DeviceButtonsServiceNotifier.new,
    );

class DeviceButtonsServiceNotifier extends Notifier<DeviceAction?> {
  @override
  DeviceAction? build() {
    return null;
  }

  Future<void> buttonPressVibrate() async {
    if (!ref.read(settingsPreferencesControllerProvider).vibrate) return;
    if (!kIsWeb && Platform.isIOS) {
      if (ref.read(libraryExperienceProvider).wheelFeedback ==
          WheelFeedback.soft) {
        await HapticFeedback.selectionClick();
      } else {
        await HapticFeedback.lightImpact();
      }
    } else if (kIsWeb || Platform.isAndroid) {
      await Vibration.vibrate(duration: 5);
    }
  }

  // Publish detents synchronously. Awaiting a platform haptic must not reorder
  // rapid direction changes or deliver a stale action after a menu transition.
  void emitWheelRotation(bool forward, {bool feedback = true}) {
    state = null;
    state = forward ? DeviceAction.rotateForward : DeviceAction.rotateBackward;
    if (!feedback) return;
    unawaited(_wheelFeedback());
    unawaited(clickWheelSound());
  }

  Future<void> _wheelFeedback() async {
    if (!ref.read(settingsPreferencesControllerProvider).vibrate) return;
    if (!kIsWeb && Platform.isIOS) {
      if (ref.read(libraryExperienceProvider).wheelFeedback ==
          WheelFeedback.soft) {
        await HapticFeedback.selectionClick();
      } else {
        await HapticFeedback.lightImpact();
      }
    } else {
      await buttonPressVibrate();
    }
  }

  Future<void> clickWheelSound() async {
    if (ref.read(settingsPreferencesControllerProvider).clickWheelSound) {
      ref.read(clickSoundServiceProvider).click();
    }
  }

  Future<void> setDeviceAction(DeviceAction action) async {
    await Future.wait([buttonPressVibrate(), clickWheelSound()]);
    state = null;
    state = action;
  }

  Future<void> playPauseButtonClick() async {
    await Future.wait([buttonPressVibrate(), clickWheelSound()]);
    state = null;
    state = DeviceAction.playPause;
    await ref.read(audioPlayerServiceProvider.notifier).togglePlayback();
  }

  void resetDeviceAction() {
    state = null;
  }
}
