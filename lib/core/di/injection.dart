import 'package:get_it/get_it.dart';

import 'initDataInjection.dart';

final locator = GetIt.instance;

Future<void> initInjections() async {

  await initDataInjections();

  await locator.allReady();
}