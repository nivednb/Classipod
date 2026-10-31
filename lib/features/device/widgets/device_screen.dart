import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/features/settings/controller/library_experience_controller.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceScreen extends ConsumerWidget {
  final Widget child;

  const DeviceScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTouchScreenEnabled = ref.watch(
      settingsPreferencesControllerProvider.select(
        (e) => e.isTouchScreenEnabled,
      ),
    );

    final raised = ref.watch(
      libraryExperienceProvider.select((e) => e.threeDimensional),
    );
    final retro = context.isFirstGenerationTheme;
    final size = MediaQuery.sizeOf(context);

    return AbsorbPointer(
      absorbing: !isTouchScreenEnabled,
      child: Container(
        height: Constants.screenHeight + 10,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.appDeviceScreenBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: (raised || retro)
              ? const [
                  BoxShadow(
                    color: Color(0x88000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                  BoxShadow(
                    color: Color(0x55ffffff),
                    blurRadius: 2,
                    offset: Offset(-1, -1),
                  ),
                ]
              : null,
          border: Border.all(
            color: retro
                ? const Color(0xFF5B5D5C)
                : context.appDeviceScreenBorderColor,
            width: 5,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(size.width - 40 - 10, Constants.screenHeight),
              ),
              child: child,
            ),
            if (raised || retro)
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    border: retro
                        ? Border.all(color: const Color(0x80919B9C), width: 2)
                        : null,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x18ffffff),
                        Color(0x00000000),
                        Color(0x10000000),
                      ],
                      stops: [0, .2, 1],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
