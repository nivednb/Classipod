import 'package:classipod/core/providers/shared_preferences_with_cache_provider.dart';
import 'package:classipod/features/settings/controller/library_experience_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'view and wheel choices survive rebuilding the provider container',
    () async {
      final previous = SharedPreferencesAsyncPlatform.instance;
      addTearDown(() => SharedPreferencesAsyncPlatform.instance = previous);
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final preferences = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );
      ProviderContainer create() => ProviderContainer(
        overrides: [
          sharedPreferencesWithCacheProvider.overrideWith(
            (ref) async => preferences,
          ),
        ],
      );
      final first = create();
      await first.read(sharedPreferencesWithCacheProvider.future);
      final settings = first.read(libraryExperienceProvider.notifier);
      await settings.setView(SongView.covers);
      await settings.toggleAcceleration();
      await settings.toggleFeedback();
      first.dispose();
      final restored = create();
      addTearDown(restored.dispose);
      await restored.read(sharedPreferencesWithCacheProvider.future);
      final value = restored.read(libraryExperienceProvider);
      expect(value.songView, SongView.covers);
      expect(value.acceleratedWheel, false);
      expect(value.wheelFeedback, WheelFeedback.crisp);
    },
  );
}
