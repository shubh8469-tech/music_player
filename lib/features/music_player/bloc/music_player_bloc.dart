import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../../songs/data/models/song_model.dart';
import '../../../services/music_player/music_player_service.dart';
import 'music_player_state.dart';

/// Bloc that subscribes to [MusicPlayerService] streams and emits unified
/// [MusicPlayerState]. Replaces scattered StreamBuilders across the app.
class MusicPlayerBloc extends Bloc<MusicPlayerEvent, MusicPlayerState> {
  MusicPlayerBloc({required MusicPlayerService musicService})
    : _musicService = musicService,
      super(MusicPlayerState()) {
    _init();
  }

  final MusicPlayerService _musicService;

  StreamSubscription<List<SongsModel>>? _songsSub;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<LoopMode>? _loopModeSub;
  StreamSubscription<bool>? _shuffleSub;

  MusicPlayerService get musicService => _musicService;

  void _init() {
    _emitCurrent();

    _songsSub = _musicService.songsChanged.listen((_) => _emitCurrent());
    _indexSub = _musicService.currentIndexStream.listen((_) => _emitCurrent());
    _playingSub = _musicService.isPlayingStream.listen((_) => _emitCurrent());
    _loopModeSub = _musicService.loopModeStream.listen((_) => _emitCurrent());
    _shuffleSub = _musicService.shuffleStream.listen((_) => _emitCurrent());

    _positionSub = _musicService.positionStream.listen((_) => _emitCurrent());
    _durationSub = _musicService.durationStream.listen((_) => _emitCurrent());
  }

  void _emitCurrent() {
    if (!isClosed) {
      var position = _musicService.position;
      var duration = _musicService.duration;

      // Filter transient position/duration resets during shuffle toggle (rebuild).
      // When the same song is playing, ignore brief 0/null from setAudioSource.
      final sameSong = state.currentSongId == _musicService.currentSongId;
      final looksLikeReset =
          position == Duration.zero &&
          (duration == null || duration.inMilliseconds <= 0);
      final hadValidProgress =
          state.position.inMilliseconds > 0 && state.duration != null;

      if (sameSong &&
          looksLikeReset &&
          hadValidProgress &&
          state.songs.isNotEmpty) {
        position = state.position;
        duration = state.duration;
      }

      emit(
        MusicPlayerState(
          songs: _musicService.songs,
          currentIndex: _musicService.currentIndex >= 0
              ? _musicService.currentIndex
              : null,
          currentSongId: _musicService.currentSongId,
          isPlaying: _musicService.isPlaying,
          position: position,
          duration: duration,
          loopMode: _musicService.loopMode,
          shuffleEnabled: _musicService.isShuffleEnabled,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _songsSub?.cancel();
    _indexSub?.cancel();
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _loopModeSub?.cancel();
    _shuffleSub?.cancel();
    return super.close();
  }
}

/// Placeholder event - this Bloc is stream-driven, no user events needed.
/// Kept for potential future actions (e.g. refresh).
abstract class MusicPlayerEvent {}
