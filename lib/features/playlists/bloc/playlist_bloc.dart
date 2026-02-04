import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/entities/playlist.dart';
import '../domain/repositories/playlist_repository.dart';
import '../../songs/data/models/song_model.dart';

part 'playlist_event.dart';
part 'playlist_state.dart';
part 'playlist_bloc.freezed.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final PlaylistRepository repository;
  bool _isRefreshing = false;
  int? _favoritesPlaylistId;

  int? get favoritesPlaylistId => _favoritesPlaylistId;

  PlaylistBloc(this.repository) : super(const PlaylistState.initial()) {

    on<_AddPlaylist>((event, emit) async {
      try {
        log('Adding playlist: ${event.name}');
        emit(const PlaylistState.loading());
        repository.addPlaylist(event.name);
        final playlists = await repository.fetchAllPlaylists();
        // emit(PlaylistState.loaded(playlists));

        final songs = await repository.getSongsForSystemPlaylist(
          'recently_played',
        );
        final systemPlaylistSongs = <String, List<SongsModel>>{
          'recently_played': songs,
        };
        emit(
          PlaylistState.loaded(
            playlists,
            systemPlaylistSongs: systemPlaylistSongs,
          ),
        );
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_FetchAllPlaylists>((event, emit) async {
      try {
        log('Fetching all playlists inside bloc');
        emit(const PlaylistState.loading());
        final playlists = await repository.fetchAllPlaylists();

        final songs = await repository.getSongsForSystemPlaylist(
          'recently_played',
        );
        final systemPlaylistSongs = <String, List<SongsModel>>{
          'recently_played': songs,
        };

        playlists.forEach((element) {
          log('Playlist: ${element.name} (length: ${element.songCount})');
        },);
        emit(PlaylistState.loaded(playlists, systemPlaylistSongs: systemPlaylistSongs));
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_DeletePlaylist>((event, emit) async {
      try {
        // emit(const PlaylistState.loading());
        await repository.deletePlaylist(event.id);
        final playlist = await repository.fetchAllPlaylists();
        final songs = await repository.getSongsForSystemPlaylist(
          'recently_played',
        );

        // Create a map with the system key and its songs
        final systemPlaylistSongs = <String, List<SongsModel>>{
          'recently_played': songs,
        };
        emit(
          PlaylistState.loaded(
            playlist,
            systemPlaylistSongs: systemPlaylistSongs,
          ),
        );
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_RenamePlaylist>((event, emit) async {
      try {
        final previousSystemSongs = state.maybeWhen(
          loaded: (_, systemPlaylistSongs) => systemPlaylistSongs,
          orElse: () => null,
        );
        await repository.renamePlaylist(event.id, event.newName);
        final playlists = await repository.fetchAllPlaylists();
        emit(
          PlaylistState.loaded(
            playlists,
            systemPlaylistSongs: previousSystemSongs,
          ),
        );
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_UpdatePlaylistCover>((event, emit) async {
      try {
        final previousSystemSongs = state.maybeWhen(
          loaded: (_, systemPlaylistSongs) => systemPlaylistSongs,
          orElse: () => null,
        );
        await repository.updatePlaylistCover(event.id, event.coverPath);
        final playlists = await repository.fetchAllPlaylists();
        emit(
          PlaylistState.loaded(
            playlists,
            systemPlaylistSongs: previousSystemSongs,
          ),
        );
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_AddSongToPlaylist>((event, emit) async {
      try {
        await repository.addSongToPlaylist(
          event.playlistId,
          event.songId,
          event.position,
        );
        final songs = await repository.fetchAllPlaylists();
        emit(PlaylistState.loaded(songs));
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_AddMultipleSongsToPlaylist>((event, emit) async {
      try {
        log(
          'Adding ${event.songIds.length} songs to playlist ${event.playlistId}',
        );
        await repository.addMultipleSongsToPlaylist(
          event.playlistId,
          event.songIds,
        );
        final playlists = await repository.fetchAllPlaylists();

        final songs = await repository.getSongsForSystemPlaylist(
          'recently_played',
        );
        final systemPlaylistSongs = <String, List<SongsModel>>{
          'recently_played': songs,
        };
        emit(
          PlaylistState.loaded(
            playlists,
            systemPlaylistSongs: systemPlaylistSongs,
          ),
        );

        // emit(PlaylistState.loaded(playlists));
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_RemoveSongFromPlaylist>((event, emit) async {
      try {
        await repository.removeSongFromPlaylist(event.playlistId, event.songId);
        final songs = await repository.fetchAllPlaylists();
        emit(PlaylistState.loaded(songs));
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_RemoveMultipleSongsFromPlaylist>((event, emit) async {
      try {
        log(
          'Removing ${event.songIds.length} songs from playlist ${event.playlistId}',
        );
        await repository.removeMultipleSongsFromPlaylist(
          event.playlistId,
          event.songIds,
        );
        final songs = await repository.fetchAllPlaylists();
        emit(PlaylistState.loaded(songs));
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_RefreshPlaylists>((event, emit) async {
      try {
        // Prevent multiple simultaneous refreshes
        if (_isRefreshing) return;

        log('Refreshing playlist:');

        // Only refresh if we have loaded data (don't show loading)
        if (state is _Loaded) {
          _isRefreshing = true;
          final playlists = await repository.fetchAllPlaylists();
          // Only emit if the data has actually changed
          final currentState = state as _Loaded;

          // Get songs for the specific system playlist
          final songs = await repository.getSongsForSystemPlaylist(
            'recently_played',
          );

          // Create a map with the system key and its songs
          final systemPlaylistSongs = <String, List<SongsModel>>{
            'recently_played': songs,
          };

          if (currentState.playlists != playlists) {
            emit(
              PlaylistState.loaded(
                playlists,
                systemPlaylistSongs: systemPlaylistSongs,
              ),
            );
          }
          _isRefreshing = false;
        } else if (state is _Initial) {
          // If we're in initial state, do a normal fetch
          _isRefreshing = true;
          emit(const PlaylistState.loading());
          final playlists = await repository.fetchAllPlaylists();
          // Get songs for the specific system playlist
          final songs = await repository.getSongsForSystemPlaylist(
            'recently_played',
          );

          // Create a map with the system key and its songs
          final systemPlaylistSongs = <String, List<SongsModel>>{
            'recently_played': songs,
          };
          emit(
            PlaylistState.loaded(
              playlists,
              systemPlaylistSongs: systemPlaylistSongs,
            ),
          );
          _isRefreshing = false;
        }
        // If we're already loading or in error state, don't do anything
      } catch (e) {
        _isRefreshing = false;
        // Don't emit error state, just keep current state
        print('Error refreshing playlists: $e');
      }
    });

    on<_FetchSongsForSystemPlaylist>((event, emit) async {
      try {
        log('Fetching songs for system playlist: ${event.systemKey}');

        // Get current playlists
        final playlists = await repository.fetchAllPlaylists();

        // Get songs for the specific system playlist
        final songs = await repository.getSongsForSystemPlaylist(
          event.systemKey,
        );

        // Create a map with the system key and its songs
        final systemPlaylistSongs = <String, List<SongsModel>>{
          event.systemKey: songs,
        };

        emit(
          PlaylistState.loaded(
            playlists,
            systemPlaylistSongs: systemPlaylistSongs,
          ),
        );
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_GetFavoritesPlaylistId>((event, emit) async {
      try {
        final playlists = await repository.fetchAllPlaylists();
        final favoritesPlaylist = playlists.firstWhere(
          (playlist) => playlist.systemKey == 'favorites',
          orElse: () => throw Exception('Favorites playlist not found'),
        );
        _favoritesPlaylistId = favoritesPlaylist.id!;
        // Emit the current state with the favorites playlist ID available
        emit(PlaylistState.loaded(playlists));
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    // To refresh from UI, re-dispatch fetchAllPlaylists()
  }
}
