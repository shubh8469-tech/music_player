import 'package:music_app/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:music_app/features/playlists/domain/usecases/add_playlist.dart';
import '../../features/songs/domain/repositories/song_repository.dart';
import '../../features/songs/domain/usecases/add_song.dart';
import '../../features/songs/domain/usecases/get_all_songs.dart';
import '../../features/folders/domain/repositories/folder_repository.dart';
import '../../features/folders/domain/usecases/add_folder.dart';
import '../../features/folders/domain/usecases/get_all_folders.dart';
import '../../features/folders/domain/usecases/get_folder_songs.dart';
import '../../features/folders/domain/usecases/get_hidden_folders.dart';
import '../../features/folders/domain/usecases/add_song_to_folder.dart';
import '../../features/folders/domain/usecases/delete_folder.dart';
import '../../features/folders/domain/usecases/update_folder_hidden_status.dart';
import '../../features/artists/domain/repositories/artist_repository.dart';
import '../../features/artists/domain/usecases/add_artist.dart';
import '../../features/artists/domain/usecases/get_all_artists.dart';
import '../../features/artists/domain/usecases/get_artist_songs.dart';
import '../../features/artists/domain/usecases/add_song_to_artist.dart';
import '../../features/artists/domain/usecases/update_artist_cover.dart';
import '../../features/albums/domain/repositories/album_repository.dart';
import '../../features/albums/domain/usecases/add_album.dart';
import '../../features/albums/domain/usecases/get_all_albums.dart';
import '../../features/albums/domain/usecases/get_album_songs.dart';
import '../../features/albums/domain/usecases/add_song_to_album.dart';
import '../../features/albums/domain/usecases/get_albums_by_artist.dart';
import '../../features/albums/domain/usecases/update_album_cover.dart';
import 'injection.dart';

Future<void> initUseCaseInjections() async {
  ///---> Songs UseCases
  locator.registerFactory(() => GetAllSongs(locator<SongRepository>()));
  locator.registerFactory(() => AddSong(locator<SongRepository>()));

  ///---> Playlists UseCases
  locator.registerFactory(() => AddPlaylist(locator<PlaylistRepository>()));

  ///---> Folders UseCases
  locator.registerFactory(() => AddFolder(locator<FolderRepository>()));
  locator.registerFactory(() => GetAllFolders(locator<FolderRepository>()));
  locator.registerFactory(() => GetFolderSongs(locator<FolderRepository>()));
  locator.registerFactory(() => GetHiddenFolders(locator<FolderRepository>()));
  locator.registerFactory(() => AddSongToFolder(locator<FolderRepository>()));
  locator.registerFactory(() => DeleteFolder(locator<FolderRepository>()));
  locator.registerFactory(
    () => UpdateFolderHiddenStatus(locator<FolderRepository>()),
  );

  ///---> Artists UseCases
  locator.registerFactory(() => AddArtist(locator<ArtistRepository>()));
  locator.registerFactory(() => GetAllArtists(locator<ArtistRepository>()));
  locator.registerFactory(() => GetArtistSongs(locator<ArtistRepository>()));
  locator.registerFactory(() => AddSongToArtist(locator<ArtistRepository>()));
  locator.registerFactory(() => UpdateArtistCover(locator<ArtistRepository>()));

  ///---> Albums UseCases
  locator.registerFactory(() => AddAlbum(locator<AlbumRepository>()));
  locator.registerFactory(() => GetAllAlbums(locator<AlbumRepository>()));
  locator.registerFactory(() => GetAlbumSongs(locator<AlbumRepository>()));
  locator.registerFactory(() => AddSongToAlbum(locator<AlbumRepository>()));
  locator.registerFactory(() => GetAlbumsByArtist(locator<AlbumRepository>()));
  locator.registerFactory(() => UpdateAlbumCover(locator<AlbumRepository>()));
}
