import 'package:get_it/get_it.dart';

import 'initDataInjection.dart';

final getIt = GetIt.instance;

Future<void> initInjections() async {

  await initDataInjections();

  await getIt.allReady();
}