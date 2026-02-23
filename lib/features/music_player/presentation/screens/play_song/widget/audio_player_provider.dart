import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_app/features/music_player/presentation/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_event.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_state.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';

class AudioPlayerProvider extends ChangeNotifier {
  AudioPlayerProvider({required MusicPlayerBloc bloc}) : _bloc = bloc {
    _init();
  }

  final MusicPlayerBloc _bloc;
  StreamSubscription<MusicPlayerState>? _stateSub;

  bool _isSeeking = false;
  Duration _dragPosition = Duration.zero;

  MusicPlayerState get _state => _bloc.state;

  Duration get duration => _state.duration ?? Duration.zero;
  Duration get position => _isSeeking ? _dragPosition : _state.position;
  bool get isPlaying => _state.isPlaying;
  SongsModel? get currentSong => _state.currentSong;
  LoopMode get loopMode => _state.loopMode;
  bool get isShuffleEnabled => _state.shuffleEnabled;

  bool get isSeeking => _isSeeking;
  Duration get dragPosition => _dragPosition;

  double get sliderValue {
    final effective = _isSeeking ? _dragPosition : _state.position;
    return effective.inMilliseconds.toDouble().clamp(0, sliderMax);
  }

  double get sliderMax {
    final d = (_state.duration ?? Duration.zero).inMilliseconds.toDouble();
    return d > 0 ? d : 1.0;
  }

  void _init() {
    _stateSub = _bloc.stream.listen((_) => notifyListeners());
  }

  void startSeeking() {
    _isSeeking = true;
    _dragPosition = _state.position;
    notifyListeners();
  }

  void updateDrag(Duration pos) {
    _dragPosition = pos;
    notifyListeners();
  }

  Future<void> seekTo(Duration pos) async {
    try {
      _bloc.add(SeekEvent(pos));
      if (_isSeeking) _dragPosition = pos;
    } finally {
      _isSeeking = false;
      notifyListeners();
    }
  }

  Future<void> toggleRepeat() async {
    _bloc.add(const ToggleRepeatEvent());
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    _bloc.add(const ToggleShuffleEvent());
    notifyListeners();
  }

  void previous() => _bloc.add(const PreviousEvent());
  void next() => _bloc.add(const NextEvent());
  void play() => _bloc.add(const PlayEvent());
  void pause() => _bloc.add(const PauseEvent());

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }
}
