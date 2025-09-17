import 'package:sqflite/sqflite.dart';
import '../../features/songs/data/dataSource/song_local_data_source.dart';
import '../../features/songs/data/repositories/song_repository_impl.dart';
import '../../features/songs/domain/repositories/song_repository.dart';
import '../../features/songs/domain/usecases/add_song.dart';
import '../../features/songs/domain/usecases/get_all_songs.dart';
import '../db/app_database.dart';
import 'injection.dart';

Future<void> initDataInjections() async {
  final db = await AppDatabase.instance();

  locator.registerLazySingleton<Database>(() => db);

  locator.registerLazySingleton<SongLocalDataSource>(
          () => SongLocalDataSourceImpl(locator<Database>()));

  // Repositories
  locator.registerLazySingleton<SongRepository>(
          () => SongRepositoryImpl(locator<SongLocalDataSource>()));

  // Usecases (you can group or keep separate)
  locator.registerFactory(() => GetAllSongs(locator<SongRepository>()));
  locator.registerFactory(() => AddSong(locator<SongRepository>()));

}
