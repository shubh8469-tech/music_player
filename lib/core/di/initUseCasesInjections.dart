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
import '../../features/artists/domain/usecases/update_artist_name.dart';
import '../../features/albums/domain/repositories/album_repository.dart';
import '../../features/albums/domain/usecases/add_album.dart';
import '../../features/albums/domain/usecases/get_all_albums.dart';
import '../../features/albums/domain/usecases/get_album_songs.dart';
import '../../features/albums/domain/usecases/add_song_to_album.dart';
import '../../features/albums/domain/usecases/get_albums_by_artist.dart';
import '../../features/albums/domain/usecases/update_album_cover.dart';
import '../../features/albums/domain/usecases/update_album_name.dart';
import '../../features/genres/domain/repositories/genre_repository.dart';
import '../../features/genres/domain/usecases/add_genre.dart';
import '../../features/genres/domain/usecases/get_all_genres.dart';
import '../../features/genres/domain/usecases/get_genre_songs.dart';
import '../../features/genres/domain/usecases/add_song_to_genre.dart';
import '../../features/genres/domain/usecases/update_genre_cover.dart';
import '../../features/genres/domain/usecases/update_genre_name.dart';
import '../../features/music_player/domain/repositories/playback_repository.dart';
import '../../features/music_player/domain/usecases/get_playback_state_stream.dart';
import '../../features/music_player/domain/usecases/set_playlist.dart';
import '../../features/music_player/domain/usecases/sync_playlist_with_updated_songs.dart';
import '../../features/music_player/domain/usecases/play_playback.dart';
import '../../features/music_player/domain/usecases/pause_playback.dart';
import '../../features/music_player/domain/usecases/seek_playback.dart';
import '../../features/music_player/domain/usecases/next_playback.dart';
import '../../features/music_player/domain/usecases/previous_playback.dart';
import '../../features/music_player/domain/usecases/toggle_shuffle_playback.dart';
import '../../features/music_player/domain/usecases/set_loop_mode_playback.dart';
import '../../features/music_player/domain/usecases/set_shuffle_playlist.dart';
import '../../features/music_player/domain/usecases/play_next_single_song.dart';
import '../../features/music_player/domain/usecases/add_single_song_to_queue.dart';
import '../../features/music_player/domain/usecases/stop_and_clear_queue.dart';
import '../../features/music_player/domain/usecases/set_playback_speed.dart';
import '../../features/music_player/domain/usecases/reorder_song_in_queue.dart';
import '../../features/music_player/domain/usecases/swap_reorder_song_in_queue.dart';
import '../../features/music_player/domain/usecases/prepare_reorder_for_current_song.dart';
import '../../features/music_player/domain/usecases/play_next_multiple_songs.dart';
import '../../features/music_player/domain/usecases/add_multiple_songs_to_queue.dart';
import '../../features/music_player/domain/usecases/reset_playlist.dart';
import '../../features/music_player/domain/usecases/update_songs_list_playback.dart';
import '../../features/music_player/domain/usecases/ensure_shuffle_on_reshuffle_playback.dart';
import '../../features/music_player/domain/usecases/ensure_shuffle_off_playback.dart';
import '../../features/music_player/domain/usecases/ensure_shuffle_on_reshuffle_index_playback.dart';
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
  locator.registerFactory(() => UpdateArtistName(locator<ArtistRepository>()));

  ///---> Albums UseCases
  locator.registerFactory(() => AddAlbum(locator<AlbumRepository>()));
  locator.registerFactory(() => GetAllAlbums(locator<AlbumRepository>()));
  locator.registerFactory(() => GetAlbumSongs(locator<AlbumRepository>()));
  locator.registerFactory(() => AddSongToAlbum(locator<AlbumRepository>()));
  locator.registerFactory(() => GetAlbumsByArtist(locator<AlbumRepository>()));
  locator.registerFactory(() => UpdateAlbumCover(locator<AlbumRepository>()));
  locator.registerFactory(() => UpdateAlbumName(locator<AlbumRepository>()));

  ///---> Genres UseCases
  locator.registerFactory(() => AddGenre(locator<GenreRepository>()));
  locator.registerFactory(() => GetAllGenres(locator<GenreRepository>()));
  locator.registerFactory(() => GetGenreSongs(locator<GenreRepository>()));
  locator.registerFactory(() => AddSongToGenre(locator<GenreRepository>()));
  locator.registerFactory(() => UpdateGenreCover(locator<GenreRepository>()));
  locator.registerFactory(() => UpdateGenreName(locator<GenreRepository>()));

  ///---> Playback (music player) UseCases
  locator.registerFactory(() => GetPlaybackStateStream(locator<PlaybackRepository>()));
  locator.registerFactory(() => SetPlaylist(locator<PlaybackRepository>()));
  locator.registerFactory(() => SyncPlaylistWithUpdatedSongs(locator<PlaybackRepository>()));
  locator.registerFactory(() => PlayPlayback(locator<PlaybackRepository>()));
  locator.registerFactory(() => PausePlayback(locator<PlaybackRepository>()));
  locator.registerFactory(() => SeekPlayback(locator<PlaybackRepository>()));
  locator.registerFactory(() => NextPlayback(locator<PlaybackRepository>()));
  locator.registerFactory(() => PreviousPlayback(locator<PlaybackRepository>()));
  locator.registerFactory(() => ToggleShufflePlayback(locator<PlaybackRepository>()));
  locator.registerFactory(() => SetLoopModePlayback(locator<PlaybackRepository>()));
  locator.registerFactory(() => SetShufflePlaylist(locator<PlaybackRepository>()));
  locator.registerFactory(() => PlayNextSingleSong(locator<PlaybackRepository>()));
  locator.registerFactory(() => AddSingleSongToQueue(locator<PlaybackRepository>()));
  locator.registerFactory(() => StopAndClearQueue(locator<PlaybackRepository>()));
  locator.registerFactory(() => SetPlaybackSpeed(locator<PlaybackRepository>()));
  locator.registerFactory(() => ReorderSongInQueue(locator<PlaybackRepository>()));
  locator.registerFactory(() => SwapReorderSongInQueue(locator<PlaybackRepository>()));
  locator.registerFactory(() => PrepareReorderForCurrentSong(locator<PlaybackRepository>()));
  locator.registerFactory(() => PlayNextMultipleSongs(locator<PlaybackRepository>()));
  locator.registerFactory(() => AddMultipleSongsToQueue(locator<PlaybackRepository>()));
  locator.registerFactory(() => ResetPlaylist(locator<PlaybackRepository>()));
  locator.registerFactory(() => UpdateSongsListPlayback(locator<PlaybackRepository>()));
  locator.registerFactory(() => EnsureShuffleOnAndReshufflePlayback(locator<PlaybackRepository>()));
  locator.registerFactory(() => EnsureShuffleOffPlayback(locator<PlaybackRepository>()));
  locator.registerFactory(() => EnsureShuffleOnReshuffleIndexPlayback(locator<PlaybackRepository>()));
}
