import 'package:music_app/features/playlists/data/dataSource/playlist_local_data_source.dart';
import 'package:music_app/features/settings/data/dataSource/backup_options_local_data_source.dart';
import 'package:music_app/features/settings/data/dataSource/scan_preferences_local_data_source.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/songs/data/dataSource/song_local_data_source.dart';
import '../../features/folders/data/dataSource/folder_local_data_source.dart';
import '../../features/artists/data/dataSource/artist_local_data_source.dart';
import '../../features/albums/data/dataSource/album_local_data_source.dart';
import '../../features/genres/data/dataSource/genre_local_data_source.dart';
import '../db/app_database.dart';
import 'injection.dart';

Future<void> initLocalDataSourceInjections() async {
  final db = await AppDatabase.instance();

  locator.registerLazySingleton<Database>(() => db);

  ///---> Songs DataSource
  locator.registerLazySingleton<SongLocalDataSource>(
    () => SongLocalDataSourceImpl(locator<Database>()),
  );

  ///---> Playlist DataSource
  locator.registerLazySingleton<PlaylistLocalDataSource>(
    () => PlaylistLocalDataSourceImpl(locator<Database>()),
  );

  ///---> Folder DataSource
  locator.registerLazySingleton<FolderLocalDataSource>(
    () => FolderLocalDataSourceImpl(
      locator<Database>(),
      locator<SongLocalDataSource>(),
    ),
  );

  ///---> Artist DataSource
  locator.registerLazySingleton<ArtistLocalDataSource>(
    () => ArtistLocalDataSourceImpl(locator<Database>()),
  );

  ///---> Album DataSource
  locator.registerLazySingleton<AlbumLocalDataSource>(
    () => AlbumLocalDataSourceImpl(locator<Database>()),
  );

  ///---> Genre DataSource
  locator.registerLazySingleton<GenreLocalDataSource>(
    () => GenreLocalDataSourceImpl(locator<Database>()),
  );

  ///---> Settings / Backup Options DataSource
  locator.registerLazySingleton<BackupOptionsLocalDataSource>(
    () => BackupOptionsLocalDataSourceImpl(locator<Database>()),
  );

  ///---> Scan preferences DataSource
  locator.registerLazySingleton<ScanPreferencesLocalDataSource>(
    () => ScanPreferencesLocalDataSourceImpl(locator<Database>()),
  );
}
