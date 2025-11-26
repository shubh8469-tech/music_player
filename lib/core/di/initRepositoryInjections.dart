import 'package:music_app/features/playlists/data/dataSource/playlist_local_data_source.dart';
import 'package:music_app/features/playlists/data/repositories/playlist_repository_impl.dart';
import 'package:music_app/features/playlists/domain/repositories/playlist_repository.dart';
import '../../features/songs/data/dataSource/song_local_data_source.dart';
import '../../features/songs/data/repositories/song_repository_impl.dart';
import '../../features/songs/domain/repositories/song_repository.dart';
import '../../features/folders/data/dataSource/folder_local_data_source.dart';
import '../../features/folders/data/repositories/folder_repository_impl.dart';
import '../../features/folders/domain/repositories/folder_repository.dart';
import '../../features/artists/data/dataSource/artist_local_data_source.dart';
import '../../features/artists/data/repositories/artist_repository_impl.dart';
import '../../features/artists/domain/repositories/artist_repository.dart';
import '../../features/albums/data/dataSource/album_local_data_source.dart';
import '../../features/albums/data/repositories/album_repository_impl.dart';
import '../../features/albums/domain/repositories/album_repository.dart';
import '../../features/genres/data/dataSource/genre_local_data_source.dart';
import '../../features/genres/data/repositories/genre_repository_impl.dart';
import '../../features/genres/domain/repositories/genre_repository.dart';
import 'injection.dart';

Future<void> initRepositoryInjections() async {
  ///---> Songs Repositories
  locator.registerLazySingleton<SongRepository>(
    () => SongRepositoryImpl(locator<SongLocalDataSource>()),
  );

  ///---> Playlists Repositories
  locator.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(locator<PlaylistLocalDataSource>()),
  );

  ///---> Folders Repositories
  locator.registerLazySingleton<FolderRepository>(
    () => FolderRepositoryImpl(locator<FolderLocalDataSource>()),
  );

  ///---> Artists Repositories
  locator.registerLazySingleton<ArtistRepository>(
    () => ArtistRepositoryImpl(locator<ArtistLocalDataSource>()),
  );

  ///---> Albums Repositories
  locator.registerLazySingleton<AlbumRepository>(
    () => AlbumRepositoryImpl(locator<AlbumLocalDataSource>()),
  );

  ///---> Genres Repositories
  locator.registerLazySingleton<GenreRepository>(
    () => GenreRepositoryImpl(locator<GenreLocalDataSource>()),
  );
}
