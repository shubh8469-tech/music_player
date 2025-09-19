import 'package:music_app/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:music_app/features/playlists/domain/usecases/add_playlist.dart';
import '../../features/songs/domain/repositories/song_repository.dart';
import '../../features/songs/domain/usecases/add_song.dart';
import '../../features/songs/domain/usecases/get_all_songs.dart';
import 'injection.dart';

Future<void> initUseCaseInjections() async {

  ///---> Songs UseCases
  locator.registerFactory(() => GetAllSongs(locator<SongRepository>()));
  locator.registerFactory(() => AddSong(locator<SongRepository>()));

  ///---> Playlists UseCases
  locator.registerFactory(() => AddPlaylist(locator<PlaylistRepository>()));
}
