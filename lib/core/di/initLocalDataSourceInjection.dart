import 'package:music_app/features/playlists/data/dataSource/playlist_local_data_source.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/songs/data/dataSource/song_local_data_source.dart';
import '../db/app_database.dart';
import 'injection.dart';

Future<void> initLocalDataSourceInjections() async {
  final db = await AppDatabase.instance();

  locator.registerLazySingleton<Database>(() => db);

  ///---> Songs DataSource
  locator.registerLazySingleton<SongLocalDataSource>(() => SongLocalDataSourceImpl(locator<Database>()));

  ///---> Playlist DataSource
  locator.registerLazySingleton<PlaylistLocalDataSource>(() => PlaylistLocalDataSourceImpl(locator<Database>()));

}
