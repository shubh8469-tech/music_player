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

  getIt.registerLazySingleton<Database>(() => db);

  getIt.registerLazySingleton<SongLocalDataSource>(
          () => SongLocalDataSourceImpl(getIt<Database>()));

  // Repositories
  getIt.registerLazySingleton<SongRepository>(
          () => SongRepositoryImpl(getIt<SongLocalDataSource>()));

  // Usecases (you can group or keep separate)
  getIt.registerFactory(() => GetAllSongs(getIt<SongRepository>()));
  getIt.registerFactory(() => AddSong(getIt<SongRepository>()));

}
