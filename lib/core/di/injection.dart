import 'package:get_it/get_it.dart';
import 'package:music_app/core/di/initUseCasesInjections.dart';

import 'initLocalDataSourceInjection.dart';
import 'initRepositoryInjections.dart';

final locator = GetIt.instance;

Future<void> initInjections() async {

  await initLocalDataSourceInjections();
  await initRepositoryInjections();
  await initUseCaseInjections();

  await locator.allReady();
}