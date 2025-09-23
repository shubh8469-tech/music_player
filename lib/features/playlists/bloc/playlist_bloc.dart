import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/entities/playlist.dart';
import '../domain/repositories/playlist_repository.dart';

part 'playlist_event.dart';
part 'playlist_state.dart';
part 'playlist_bloc.freezed.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  final PlaylistRepository repository;

  PlaylistBloc(this.repository) : super(const PlaylistState.initial()) {
    on<_AddPlaylist>((event, emit) async {
      try {
        emit(const PlaylistState.loading());
        repository.addPlaylist(event.name);
        final playlists = await repository.fetchAllPlaylists();
        emit(PlaylistState.loaded(playlists));
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_FetchAllPlaylists>((event, emit) async {
      try {
        emit(const PlaylistState.loading());
        final playlists = await repository.fetchAllPlaylists();
        emit(PlaylistState.loaded(playlists));
      } catch (e) {
        emit(PlaylistState.error(e.toString()));
      }
    });

    on<_DeletePlaylist>((event, emit) async {
      try {
        emit(const PlaylistState.loading());
        await repository.deletePlaylist(event.id);
        final songs = await repository.fetchAllPlaylists();
        emit(PlaylistState.loaded(songs));
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

    // To refresh from UI, re-dispatch fetchAllPlaylists()
  }
}
