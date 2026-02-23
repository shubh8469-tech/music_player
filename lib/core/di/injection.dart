import 'package:get_it/get_it.dart';
import 'package:music_app/core/di/initUseCasesInjections.dart';
import 'package:music_app/core/services/app_state_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:music_app/features/music_player/data/services/music_player_service.dart';
import 'package:music_app/features/music_player/data/services/unified_equalizer_service.dart';
import 'initLocalDataSourceInjection.dart';
import 'initRepositoryInjections.dart';

final locator = GetIt.instance;

Future<void> initInjections() async {
  // Register SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(prefs);

  UnifiedEqualizerService().attachPrefs(prefs);
  // Register AppStateService
  locator.registerSingleton<AppStateService>(AppStateService(locator()));

  // Singleton music player (used by PlaybackRepositoryImpl and optionally by Bloc until Phase 2)
  locator.registerSingleton<MusicPlayerService>(MusicPlayerService());

  await initLocalDataSourceInjections();
  await initRepositoryInjections();
  await initUseCaseInjections();

  await locator.allReady();
}
