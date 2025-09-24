import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:music_app/features/playlists/domain/entities/playlist.dart';
import 'package:music_app/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/screens/tabs/music_service.dart';

part 'home_event.dart';
part 'home_state.dart';
part 'home_bloc.freezed.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final PlaylistRepository playlistRepository;
  final MusicPlayerService musicService;
  StreamSubscription<void>? _libraryChangedSubscription;

  HomeBloc({
    required this.playlistRepository,
    required this.musicService,
  }) : super(const HomeState.initial()) {
    on<_LoadData>(_onLoadData);
    on<_RefreshData>(_onRefreshData);
    on<_SongPlayed>(_onSongPlayed);

    // Listen to music service changes to automatically refresh data
    _libraryChangedSubscription = musicService.libraryChanged.listen((_) {
      add(const HomeEvent.songPlayed());
    });
  }

  Future<void> _onLoadData(_LoadData event, Emitter<HomeState> emit) async {
    try {
      emit(const HomeState.loading());

      final recentlyPlayed =
          await playlistRepository.getSongsForSystemPlaylist('recently_played');
      final allPlaylists = await playlistRepository.fetchAllPlaylists();
      final userPlaylists =
          allPlaylists.where((p) => p.isSystem == false).toList();
      final systemPlaylists =
          allPlaylists.where((p) => p.isSystem == true).toList();

      emit(HomeState.loaded(
        recentlyPlayedSongs: recentlyPlayed.take(3).toList(),
        userPlaylists: userPlaylists.take(3).toList(),
        systemPlaylists: systemPlaylists,
      ));
    } catch (e) {
      emit(HomeState.error(e.toString()));
    }
  }

  Future<void> _onRefreshData(
      _RefreshData event, Emitter<HomeState> emit) async {
    add(const HomeEvent.loadData());
  }

  Future<void> _onSongPlayed(_SongPlayed event, Emitter<HomeState> emit) async {
    // Only refresh if we have loaded data
    if (state is _Loaded) {
      try {
        final recentlyPlayed = await playlistRepository
            .getSongsForSystemPlaylist('recently_played');
        final allPlaylists = await playlistRepository.fetchAllPlaylists();
        final userPlaylists =
            allPlaylists.where((p) => p.isSystem == false).toList();
        final systemPlaylists =
            allPlaylists.where((p) => p.isSystem == true).toList();

        emit(HomeState.loaded(
          recentlyPlayedSongs: recentlyPlayed.take(3).toList(),
          userPlaylists: userPlaylists.take(3).toList(),
          systemPlaylists: systemPlaylists,
        ));
      } catch (e) {
        // Don't emit error state, just keep current state
        print('Error refreshing home data: $e');
      }
    }
  }

  @override
  Future<void> close() {
    _libraryChangedSubscription?.cancel();
    return super.close();
  }
}
