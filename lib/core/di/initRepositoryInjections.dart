import 'package:music_app/features/playlists/data/datasources/playlist_local_data_source.dart';
import 'package:music_app/features/playlists/data/repositories/playlist_repository_impl.dart';
import 'package:music_app/features/playlists/domain/repositories/playlist_repository.dart';
import '../../features/songs/data/datasources/song_local_data_source.dart';
import '../../features/songs/data/repositories/song_repository_impl.dart';
import '../../features/songs/domain/repositories/song_repository.dart';
import '../../features/folders/data/datasources/folder_local_data_source.dart';
import '../../features/folders/data/repositories/folder_repository_impl.dart';
import '../../features/folders/domain/repositories/folder_repository.dart';
import '../../features/artists/data/datasources/artist_local_data_source.dart';
import '../../features/artists/data/repositories/artist_repository_impl.dart';
import '../../features/artists/domain/repositories/artist_repository.dart';
import '../../features/albums/data/datasources/album_local_data_source.dart';
import '../../features/albums/data/repositories/album_repository_impl.dart';
import '../../features/albums/domain/repositories/album_repository.dart';
import '../../features/genres/data/datasources/genre_local_data_source.dart';
import '../../features/genres/data/repositories/genre_repository_impl.dart';
import '../../features/genres/domain/repositories/genre_repository.dart';
import '../../features/music_player/data/repositories/playback_repository_impl.dart';
import '../../features/music_player/domain/repositories/playback_repository.dart';
import 'package:music_app/features/music_player/data/services/music_player_service.dart';
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

  ///---> Playback (music player) Repository
  locator.registerLazySingleton<PlaybackRepository>(
    () => PlaybackRepositoryImpl(locator<MusicPlayerService>()),
  );
}
