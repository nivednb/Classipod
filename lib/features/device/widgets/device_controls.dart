import 'dart:async';

import 'package:classipod/core/constants/assets.dart';
import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/constants/keys.dart';
import 'package:classipod/core/custom_painter/next_button_custom_painter.dart';
import 'package:classipod/core/custom_painter/play_pause_button_custom_painter.dart';
import 'package:classipod/core/custom_painter/previous_button_custom_painter.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/core/services/click_sound_service.dart';
import 'package:classipod/features/device/models/device_action.dart';
import 'package:classipod/features/device/models/wheel_motion.dart';
import 'package:classipod/features/device/services/device_buttons_service_provider.dart';
import 'package:classipod/features/device/widgets/first_generation_wheel_painter.dart';
import 'package:classipod/features/menu/controller/split_screen_controller.dart';
import 'package:classipod/features/settings/controller/library_experience_controller.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:classipod/features/settings/models/click_wheel_sensitivity.dart';
import 'package:classipod/features/settings/models/click_wheel_size.dart';
import 'package:classipod/features/settings/models/device_color.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeviceControls extends ConsumerStatefulWidget {
  const DeviceControls({super.key});

  @override
  ConsumerState createState() => _DeviceControlsState();
}

class _DeviceControlsState extends ConsumerState<DeviceControls> {
  final WheelMotion _motion = WheelMotion();
  final Stopwatch _gestureClock = Stopwatch();

  void _endGesture() {
    _motion.reset();
    _gestureClock.stop();
    ref.read(clickWheelGestureProvider.notifier).active = false;
  }

  void onClickWheelScroll(
    DragUpdateDetails details,
    double radius,
    double radiansPerStep,
    bool accelerate,
  ) {
    final steps = _motion.update(
      x: details.localPosition.dx - radius,
      y: details.localPosition.dy - radius,
      radius: radius,
      milliseconds: _gestureClock.elapsedMilliseconds,
      radiansPerStep: radiansPerStep,
      accelerate: accelerate,
    );
    if (steps == 0) return;
    ref.read(splitScreenControllerProvider.notifier).onClickWheelScroll();
    final service = ref.read(deviceButtonsServiceProvider.notifier);
    for (var i = 0; i < steps.abs(); i++) {
      service.emitWheelRotation(steps > 0, feedback: i == 0);
    }
  }

  @override
  void dispose() {
    _gestureClock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DeviceColor deviceColor = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.deviceColor,
      ),
    );
    final deviceColorStyle = deviceColor.style;
    final clickWheelSize = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.clickWheelSize,
      ),
    );
    final clickWheelSensitivity = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.clickWheelSensitivity,
      ),
    );
    late final double clickWheelRadiusRatio;
    late final double selectButtonRadiusRatio;
    switch (clickWheelSize) {
      case ClickWheelSize.small:
        clickWheelRadiusRatio = Constants.deviceClickWheelSmallRadiusRatio;
        selectButtonRadiusRatio = Constants.deviceSelectButtonSmallRadiusRatio;
        break;
      case ClickWheelSize.medium:
        clickWheelRadiusRatio = Constants.deviceClickWheelMediumRadiusRatio;
        selectButtonRadiusRatio = Constants.deviceSelectButtonMediumRadiusRatio;
        break;
      case ClickWheelSize.large:
        clickWheelRadiusRatio = Constants.deviceClickWheelLargeRadiusRatio;
        selectButtonRadiusRatio = Constants.deviceSelectButtonLargeRadiusRatio;
        break;
    }

    final experience = ref.watch(libraryExperienceProvider);
    final wheelColor = switch (experience.wheelColor) {
      WheelColor.device => deviceColorStyle.controlBackgroundColor,
      WheelColor.red => const Color(0xFFAA101A),
      WheelColor.black => const Color(0xFF171717),
      WheelColor.white => const Color(0xFFF5F5F5),
      WheelColor.blue => const Color(0xFF2469B3),
      WheelColor.orange => const Color(0xFFE03800),
      WheelColor.green => const Color(0xFF298346),
      WheelColor.purple => const Color(0xFF7635A6),
    };
    final labelColor = switch (experience.wheelLabelColor) {
      WheelLabelColor.device => deviceColorStyle.buttonAccentColor,
      WheelLabelColor.white => CupertinoColors.white,
      WheelLabelColor.black => CupertinoColors.black,
    };
    final iconColor = experience.wheelLabelColor == WheelLabelColor.device
        ? deviceColorStyle.buttonIconColor
        : labelColor;
    final radiansPerStep = switch (clickWheelSensitivity) {
      ClickWheelSensitivity.veryLow => .24,
      ClickWheelSensitivity.low => .18,
      ClickWheelSensitivity.medium => .13,
      ClickWheelSensitivity.high => .09,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth + 40;

        return Align(
          heightFactor: 1,
          child: GestureDetector(
            onPanDown: (details) {
              if (ref
                  .read(settingsPreferencesControllerProvider)
                  .clickWheelSound) {
                ref.read(clickSoundServiceProvider).primeFromGesture();
              }
              _motion.reset();
              _gestureClock.reset();
              _gestureClock.start();
              final radius = screenWidth * clickWheelRadiusRatio / 2;
              _motion.update(
                x: details.localPosition.dx - radius,
                y: details.localPosition.dy - radius,
                radius: radius,
                milliseconds: 0,
                radiansPerStep: radiansPerStep,
              );
              ref.read(clickWheelGestureProvider.notifier).active = true;
            },
            onPanEnd: (_) => _endGesture(),
            onPanCancel: _endGesture,
            onPanUpdate: (details) => onClickWheelScroll(
              details,
              screenWidth * clickWheelRadiusRatio / 2,
              radiansPerStep,
              experience.acceleratedWheel,
            ),
            child: CustomPaint(
              foregroundPainter:
                  experience.wheelStyle == WheelStyle.firstGeneration
                  ? FirstGenerationWheelPainter(wheelColor)
                  : null,
              child: Container(
                height: screenWidth * clickWheelRadiusRatio,
                width: screenWidth * clickWheelRadiusRatio,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: wheelColor,
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async => ref
                            .read(deviceButtonsServiceProvider.notifier)
                            .setDeviceAction(DeviceAction.menu),
                        onLongPress: () async {
                          await Future.wait([
                            ref
                                .read(deviceButtonsServiceProvider.notifier)
                                .buttonPressVibrate(),
                            ref
                                .read(deviceButtonsServiceProvider.notifier)
                                .clickWheelSound(),
                          ]);
                          if (context.mounted) {
                            context.goNamed(Routes.menu.name);
                            if (!ref
                                .read(splitScreenViewControllerProvider)
                                .isScreenVisible) {
                              unawaited(
                                ref
                                    .read(splitScreenViewControllerProvider)
                                    .openSplitView(),
                              );
                            }
                          }
                        },
                        child: ColoredBox(
                          color: wheelColor,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Text(
                              context.localization.menuButtonText,
                              key: menuButtonGlobalKey,
                              style: TextStyle(
                                color: labelColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          key: previousButtonGlobalKey,
                          child: GestureDetector(
                            onTap: () async => ref
                                .read(deviceButtonsServiceProvider.notifier)
                                .setDeviceAction(DeviceAction.seekBackward),
                            onLongPress: () async => ref
                                .read(deviceButtonsServiceProvider.notifier)
                                .setDeviceAction(
                                  DeviceAction.seekBackwardLongPress,
                                ),
                            onLongPressEnd: (_) async => ref
                                .read(deviceButtonsServiceProvider.notifier)
                                .setDeviceAction(DeviceAction.longPressEnd),
                            child: SizedBox(
                              height: screenWidth * 0.2175,
                              child: ColoredBox(
                                color: wheelColor,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: CustomPaint(
                                    size: const Size(20, 10),
                                    painter: PreviousButtonCustomPainter(
                                      color: iconColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          key: centerButtonGlobalKey,
                          onTap: () async => ref
                              .read(deviceButtonsServiceProvider.notifier)
                              .setDeviceAction(DeviceAction.select),
                          onLongPress: () async => ref
                              .read(deviceButtonsServiceProvider.notifier)
                              .setDeviceAction(DeviceAction.selectLongPress),
                          onLongPressEnd: (_) async => ref
                              .read(deviceButtonsServiceProvider.notifier)
                              .setDeviceAction(DeviceAction.longPressEnd),
                          child: SizedBox(
                            height: screenWidth * selectButtonRadiusRatio,
                            width: screenWidth * selectButtonRadiusRatio,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: deviceColorStyle.controlBorderColor,
                                ),
                                image: const DecorationImage(
                                  image: AssetImage(Assets.noiseImage),
                                  fit: BoxFit.cover,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors:
                                      experience.wheelColor == WheelColor.device
                                      ? deviceColorStyle
                                            .innerButtonGradientColors
                                      : [wheelColor, wheelColor],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          key: nextButtonGlobalKey,
                          child: GestureDetector(
                            onTap: () async => ref
                                .read(deviceButtonsServiceProvider.notifier)
                                .setDeviceAction(DeviceAction.seekForward),
                            onLongPress: () async => ref
                                .read(deviceButtonsServiceProvider.notifier)
                                .setDeviceAction(
                                  DeviceAction.seekForwardLongPress,
                                ),
                            onLongPressEnd: (_) async => ref
                                .read(deviceButtonsServiceProvider.notifier)
                                .setDeviceAction(DeviceAction.longPressEnd),
                            child: SizedBox(
                              height: screenWidth * selectButtonRadiusRatio,
                              child: ColoredBox(
                                color: wheelColor,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: CustomPaint(
                                    size: const Size(20, 10),
                                    painter: NextButtonCustomPainter(
                                      color: iconColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async => ref
                            .read(deviceButtonsServiceProvider.notifier)
                            .playPauseButtonClick(),
                        child: ColoredBox(
                          color: wheelColor,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: CustomPaint(
                              key: playPauseButtonGlobalKey,
                              size: const Size(26, 12),
                              painter: PlayPauseButtonCustomPainter(
                                color: iconColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
