import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../../../songs/data/models/song_model.dart';
import 'package:music_app/features/music_player/data/services/music_player_service.dart';
import '../../domain/entities/playback_loop_mode.dart';
import '../../domain/entities/playback_state.dart';
import '../../domain/repositories/playback_repository.dart';
import '../../domain/usecases/get_playback_state_stream.dart';
import 'music_player_event.dart';
import 'music_player_state.dart';

/// Bloc for playback: subscribes to [GetPlaybackStateStream], handles events via [PlaybackRepository],
/// and exposes [libraryChangedStream], [equalizerService], and [player] for UI that needs them.
class MusicPlayerBloc extends Bloc<MusicPlayerEvent, MusicPlayerState> {
  MusicPlayerBloc({
    required MusicPlayerService musicService,
    required GetPlaybackStateStream getPlaybackStateStream,
    required PlaybackRepository playbackRepository,
  })  : _musicService = musicService,
        _getPlaybackStateStream = getPlaybackStateStream,
        _repository = playbackRepository,
        super(const MusicPlayerState()) {
    _init();
    _registerHandlers();
  }

  final MusicPlayerService _musicService;
  final GetPlaybackStateStream _getPlaybackStateStream;
  final PlaybackRepository _repository;
  StreamSubscription<PlaybackState>? _stateSub;

  Stream<void> get libraryChangedStream => _musicService.libraryChanged;
  dynamic get equalizerService => _musicService.equalizerService;
  dynamic get player => _musicService.player;
  double get playbackSpeed => _musicService.playbackSpeed;

  /// Syncs the current queue with updated song data (e.g. from SongsBloc after
  /// artwork/favorite change). Bypasses domain so metadata (isFavorite, playCount, etc.) is preserved.
  void syncPlaylistWithUpdatedSongsFromModels(List<SongsModel> updatedSongs) {
    _musicService.syncCurrentPlaylistWithUpdatedSongs(updatedSongs);
  }

  static LoopMode _toLoopMode(PlaybackLoopMode mode) {
    switch (mode) {
      case PlaybackLoopMode.off:
        return LoopMode.off;
      case PlaybackLoopMode.one:
        return LoopMode.one;
      case PlaybackLoopMode.all:
        return LoopMode.all;
    }
  }

  void _init() {
    _stateSub = _getPlaybackStateStream.call().listen((domainState) {
      if (isClosed) return;
      emit(
        MusicPlayerState(
          songs: domainState.songs
              .map((s) => SongsModel.fromDomain(s))
              .toList(),
          currentIndex: domainState.currentIndex,
          currentSongId: domainState.currentSongId,
          isPlaying: domainState.isPlaying,
          position: domainState.position,
          duration: domainState.duration,
          loopMode: _toLoopMode(domainState.loopMode),
          shuffleEnabled: domainState.shuffleEnabled,
        ),
      );
    });
  }

  void _registerHandlers() {
    on<SetPlaylistEvent>((event, emit) async {
      await _repository.setPlaylist(
        event.songs,
        startIndex: event.startIndex,
        autoPlay: event.autoPlay,
      );
    });
    on<SetShufflePlaylistEvent>((event, emit) async {
      await _repository.setShufflePlaylist(
        event.songs,
        startIndex: event.startIndex,
        autoPlay: event.autoPlay,
      );
    });
    on<ResetPlaylistEvent>((event, emit) async {
      await _repository.resetPlaylist(event.songs);
    });
    on<SyncPlaylistWithUpdatedSongsEvent>((event, emit) {
      _repository.syncPlaylistWithUpdatedSongs(event.songs);
    });
    on<UpdateSongsListEvent>((event, emit) {
      _repository.updateSongsList(event.songs);
    });
    on<UpdateSongsInQueueWithIndexEvent>((event, emit) async {
      await _repository.updateSongsInQueueWithIndex(
        event.songs,
        event.preserveIndex,
      );
    });
    on<PlayEvent>((event, emit) async => await _repository.play());
    on<PauseEvent>((event, emit) async => await _repository.pause());
    on<NextEvent>((event, emit) async => await _repository.next());
    on<PreviousEvent>((event, emit) async => await _repository.previous());
    on<SeekEvent>((event, emit) async {
      await _repository.seek(event.position, index: event.index);
    });
    on<StopAndClearQueueEvent>((event, emit) async {
      await _repository.stopAndClearQueue();
    });
    on<ToggleShuffleEvent>((event, emit) async => await _repository.toggleShuffle());
    on<SetLoopModeEvent>((event, emit) async {
      await _repository.setLoopMode(event.mode);
    });
    on<SetPlaybackSpeedEvent>((event, emit) async {
      await _repository.setPlaybackSpeed(event.speed);
    });
    on<EnsureShuffleOnAndReshuffleEvent>((event, emit) async {
      await _repository.ensureShuffleOnAndReshuffle();
    });
    on<EnsureShuffleOffEvent>((event, emit) async {
      await _repository.ensureShuffleOff();
    });
    on<EnsureShuffleOnReshuffleIndexEvent>((event, emit) async {
      await _repository.ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();
    });
    on<ToggleRepeatEvent>((event, emit) async {
      final current = state.loopMode;
      final next = current == LoopMode.off
          ? PlaybackLoopMode.one
          : current == LoopMode.one
              ? PlaybackLoopMode.all
              : PlaybackLoopMode.off;
      await _repository.setLoopMode(next);
    });
    on<PlayNextSingleSongEvent>((event, emit) async {
      await _repository.playNextSingleSong(event.song);
    });
    on<PlayNextMultipleSongsEvent>((event, emit) async {
      await _repository.playNextMultipleSongs(event.songs);
    });
    on<AddSingleSongToQueueEvent>((event, emit) async {
      await _repository.addSingleSongToQueue(event.song);
    });
    on<AddMultipleSongsToQueueEvent>((event, emit) async {
      await _repository.addMultipleSongsToQueue(event.songs);
    });
    on<RemoveFromQueueAtIndexEvent>((event, emit) async {
      await _repository.removeFromQueueAtIndex(
        event.removeIndex,
        event.newCurrentIndex,
      );
    });
    on<PrepareReorderForCurrentSongEvent>((event, emit) {
      _repository.prepareReorderForCurrentSong(event.oldIndex, event.newIndex);
    });
    on<SwapReorderSongInQueueEvent>((event, emit) async {
      await _repository.swapReorderSongInQueue(event.oldIndex, event.newIndex);
    });
    on<ReorderSongInQueueEvent>((event, emit) async {
      await _repository.reorderSongInQueue(event.oldIndex, event.newIndex);
    });
    on<RemoveDeletedSongFromQueueEvent>((event, emit) async {
      await _repository.removeDeletedSongFromQueue(event.songId);
    });
    on<RemoveDeletedSongsFromQueueEvent>((event, emit) async {
      await _repository.removeDeletedSongsFromQueue(event.songIds);
    });
  }

  @override
  Future<void> close() {
    _stateSub?.cancel();
    return super.close();
  }
}
