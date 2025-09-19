import 'package:music_app/features/playlists/data/dataSource/playlist_local_data_source.dart';
import 'package:music_app/features/playlists/data/repositories/playlist_repository_impl.dart';
import 'package:music_app/features/playlists/domain/repositories/playlist_repository.dart';
import '../../features/songs/data/dataSource/song_local_data_source.dart';
import '../../features/songs/data/repositories/song_repository_impl.dart';
import '../../features/songs/domain/repositories/song_repository.dart';
import 'injection.dart';

Future<void> initRepositoryInjections() async {

  ///---> Songs Repositories
  locator.registerLazySingleton<SongRepository>(() => SongRepositoryImpl(locator<SongLocalDataSource>()));

  ///---> Playlists Repositories
  locator.registerLazySingleton<PlaylistRepository>(() => PlaylistRepositoryImpl(locator<PlaylistLocalDataSource>()));

}
