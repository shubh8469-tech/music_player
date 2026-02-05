import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:just_audio/just_audio.dart';

import '../../tabs/music_service.dart';

class AudioPlayerProvider extends ChangeNotifier {
  AudioPlayerProvider() {
    _init();
  }

  final MusicPlayerService _musicService = MusicPlayerService();

  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playerStateSub;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  bool _isSeeking = false;
  Duration _dragPosition = Duration.zero;

  Duration get duration => _duration;
  Duration get position => _position;
  bool get isPlaying => _isPlaying;

  bool get isSeeking => _isSeeking;
  Duration get dragPosition => _dragPosition;

  /// Expose current loop mode for the UI
  LoopMode get loopMode => _musicService.loopMode;

  /// Value to be used by the Slider
  double get sliderValue {
    final effective = _isSeeking ? _dragPosition : _position;
    return effective.inMilliseconds.toDouble().clamp(0, sliderMax);
  }

  double get sliderMax {
    final d = _duration.inMilliseconds.toDouble();
    return d > 0 ? d : 1.0;
  }

  MusicPlayerService get musicService => _musicService;

  void _init() {
    // Initialize from current player state
    _duration = _musicService.duration ?? Duration.zero;
    _position = _musicService.position;
    _isPlaying = _musicService.isPlaying;

    _durationSub = _musicService.durationStream.listen((d) {
      if (d == null) return;
      _duration = d;
      notifyListeners();
    });

    _positionSub = _musicService.positionStream.listen((p) {
      if (_isSeeking) return; // While seeking, don't override drag position
      _position = p;
      notifyListeners();
    });

    _playerStateSub = _musicService.isPlayingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });
  }

  void startSeeking() {
    _isSeeking = true;
    _dragPosition = _position;
    notifyListeners();
  }

  void updateDrag(Duration pos) {
    _dragPosition = pos;
    notifyListeners();
  }

  Future<void> seekTo(Duration pos) async {
    try {
      await _musicService.seek(pos);
      _position = pos;
    } finally {
      _isSeeking = false;
      notifyListeners();
    }
  }

  /// Toggle repeat and notify listeners so the icon updates even when paused
  Future<void> toggleRepeat() async {
    await _musicService.toggleRepeat();
    notifyListeners();
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    super.dispose();
  }
}

