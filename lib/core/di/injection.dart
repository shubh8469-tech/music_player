import 'package:get_it/get_it.dart';
import 'package:music_app/core/di/initUseCasesInjections.dart';
import 'package:music_app/core/services/app_state_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'initLocalDataSourceInjection.dart';
import 'initRepositoryInjections.dart';

final locator = GetIt.instance;

Future<void> initInjections() async {
  // Register SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  locator.registerSingleton<SharedPreferences>(prefs);

  // Register AppStateService
  locator.registerSingleton<AppStateService>(AppStateService(locator()));

  await initLocalDataSourceInjections();
  await initRepositoryInjections();
  await initUseCaseInjections();

  await locator.allReady();
}
