import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:developer';

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:developer';

import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:developer';

/// iOS-specific audio player that integrates with native AVAudioEngine
/// This service communicates with native iOS code through platform channels
class IOSAudioPlayer {
  static const MethodChannel _channel = MethodChannel('com.example.music_app.ios_audio_player');

  // Event channels for streaming state
  static const EventChannel _playingChannel = EventChannel('com.example.music_app.ios_audio_player/playing_stream');
  static const EventChannel _positionChannel = EventChannel('com.example.music_app.ios_audio_player/position_stream');
  static const EventChannel _durationChannel = EventChannel('com.example.music_app.ios_audio_player/duration_stream');
  static const EventChannel _indexChannel = EventChannel('com.example.music_app.ios_audio_player/index_stream');

  bool _isInitialized = false;

  // Streams
  Stream<bool>? _playingStream;
  Stream<Duration>? _positionStream;
  Stream<Duration?>? _durationStream;
  Stream<int?>? _indexStream;

  // Current state
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  int _currentIndex = -1;

  // Callbacks
  final StreamController<void> _playerStateController = StreamController<void>.broadcast();
  Stream<void> get playerStateStream => _playerStateController.stream;

  bool get isInitialized => _isInitialized;
  bool get playing => _isPlaying;
  Duration get position => _position;
  Duration? get duration => _duration;
  int? get currentIndex => _currentIndex >= 0 ? _currentIndex : null;

  /// Stream of current track index - emits when index changes from native side
  Stream<int?> get currentIndexStream {
    _indexStream ??= _indexChannel
        .receiveBroadcastStream()
        .map((dynamic index) => index as int?)
        .distinct() // Only emit when value actually changes
        .handleError((error) {
      log('Error in index stream: $error');
      return null;
    });
    return _indexStream!;
  }

  /// Stream of playing state (true when playing, false when paused)
  Stream<bool> get playingStream {
    _playingStream ??= _playingChannel
        .receiveBroadcastStream()
        .map((dynamic playing) => playing as bool)
        .handleError((error) {
      log('Error in playing stream: $error');
      return false;
    });
    return _playingStream!;
  }

  /// Stream of current playback position
  Stream<Duration> get positionStream {
    _positionStream ??= _positionChannel
        .receiveBroadcastStream()
        .map((dynamic positionMs) {
      final position = Duration(milliseconds: positionMs as int);
      return position;
    })
        .handleError((error) {
      log('Error in position stream: $error');
      return Duration.zero;
    });
    return _positionStream!;
  }

  /// Stream of audio duration
  Stream<Duration?> get durationStream {
    _durationStream ??= _durationChannel
        .receiveBroadcastStream()
        .map((dynamic durationMs) {
      if (durationMs == null || durationMs == 0) return null;
      return Duration(milliseconds: durationMs as int);
    })
        .handleError((error) {
      log('Error in duration stream: $error');
      return null;
    });
    return _durationStream!;
  }

  /// Initialize the iOS audio player
  Future<bool> initialize() async {
    if (!Platform.isIOS) {
      log('IOSAudioPlayer: Not on iOS platform');
      return false;
    }

    try {
      final result = await _channel.invokeMethod('initialize');
      _isInitialized = result == true;

      if (_isInitialized) {
        // Listen to streams and update local state
        playingStream.listen((playing) {
          _isPlaying = playing;
          _playerStateController.add(null);
        });

        positionStream.listen((pos) {
          _position = pos;
        });

        durationStream.listen((dur) {
          _duration = dur;
        });

        // Listen to index changes from native
        currentIndexStream.listen((index) {
          if (index != null) {
            log('📱 Dart received index change: $_currentIndex -> $index');
            _currentIndex = index;
            _playerStateController.add(null);
          }
        });

        log('iOS Audio Player initialized successfully');
      }

      return _isInitialized;
    } catch (e) {
      log('Error initializing iOS audio player: $e');
      return false;
    }
  }

  /// Set playlist with audio files

  Future<void> setAudioSource(
      List<String> filePaths, {
        int initialIndex = 0,
        bool autoPlay = true,
      }) async {
    if (!_isInitialized) {
      throw Exception('Player not initialized');
    }

    try {
      print('🎵 Dart: Calling native setPlaylist with autoPlay=$autoPlay');

      // ✅ AWAIT the native call to ensure it completes
      await _channel.invokeMethod('setPlaylist', {
        'filePaths': filePaths,
        'startIndex': initialIndex,
        'autoPlay': autoPlay,
      });

      _currentIndex = initialIndex;
      _playerStateController.add(null);

      print('✅ Dart: Native setPlaylist completed');
    } catch (e) {
      log('❌ Error setting audio source: $e');
      rethrow;
    }
  }

 /* Future<void> setAudioSource(
      List<String> filePaths, {
        int initialIndex = 0,
        bool autoPlay = true,
      }) async {
    if (!_isInitialized) {
      throw Exception('Player not initialized');
    }

    try {
      await _channel.invokeMethod('setPlaylist', {
        'filePaths': filePaths,
        'startIndex': initialIndex,
        'autoPlay': autoPlay,
      });

      _currentIndex = initialIndex;
      _playerStateController.add(null);
    } catch (e) {
      log('Error setting audio source: $e');
      rethrow;
    }
  }*/

  /// Play audio
  Future<void> play() async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('play');
      _playerStateController.add(null);
    } catch (e) {
      log('Error playing: $e');
      rethrow;
    }
  }

  /// Pause audio
  Future<void> pause() async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('pause');
      _playerStateController.add(null);
    } catch (e) {
      log('Error pausing: $e');
      rethrow;
    }
  }

  /// Stop audio
  Future<void> stop() async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('stop');
      _position = Duration.zero;
      _playerStateController.add(null);
    } catch (e) {
      log('Error stopping: $e');
      rethrow;
    }
  }

  /// Seek to position
  Future<void> seek(Duration position, {int? index}) async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('seek', {
        'position': position.inMilliseconds,
        'index': index,
      });

      if (index != null) {
        _currentIndex = index;
      }
      _position = position;
      _playerStateController.add(null);
    } catch (e) {
      log('Error seeking: $e');
      rethrow;
    }
  }

  /// Seek to next track
  Future<void> seekToNext() async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('seekToNext');
      _playerStateController.add(null);
    } catch (e) {
      log('Error seeking to next: $e');
      rethrow;
    }
  }

  /// Seek to previous track
  Future<void> seekToPrevious() async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('seekToPrevious');
      _playerStateController.add(null);
    } catch (e) {
      log('Error seeking to previous: $e');
      rethrow;
    }
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('setSpeed', {'speed': speed});
    } catch (e) {
      log('Error setting speed: $e');
      rethrow;
    }
  }

  /// Set loop mode: "off", "one", "all"
  Future<void> setLoopMode(String mode) async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('setLoopMode', {'mode': mode});
    } catch (e) {
      log('Error setting loop mode: $e');
      rethrow;
    }
  }

  /// Set shuffle enabled
  Future<void> setShuffleModeEnabled(bool enabled) async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('setShuffleEnabled', {'enabled': enabled});
    } catch (e) {
      log('Error setting shuffle: $e');
      rethrow;
    }
  }



  /// Get current index
  Future<int?> getCurrentIndex() async {
    if (!_isInitialized) return null;

    try {
      final index = await _channel.invokeMethod('getCurrentIndex');
      return index as int?;
    } catch (e) {
      log('Error getting current index: $e');
      return null;
    }
  }

  /// Check if playing
  Future<bool> isPlaying() async {
    if (!_isInitialized) return false;

    try {
      final playing = await _channel.invokeMethod('isPlaying');
      return playing as bool;
    } catch (e) {
      log('Error checking if playing: $e');
      return false;
    }
  }

  /// Get current position
  Future<Duration> getPosition() async {
    if (!_isInitialized) return Duration.zero;

    try {
      final positionMs = await _channel.invokeMethod('getPosition');
      return Duration(milliseconds: positionMs as int);
    } catch (e) {
      log('Error getting position: $e');
      return Duration.zero;
    }
  }

  /// Get duration
  Future<Duration?> getDuration() async {
    if (!_isInitialized) return null;

    try {
      final durationMs = await _channel.invokeMethod('getDuration');
      if (durationMs == null || durationMs == 0) return null;
      return Duration(milliseconds: durationMs as int);
    } catch (e) {
      log('Error getting duration: $e');
      return null;
    }
  }

  // MARK: - Equalizer Methods

  /// Set equalizer enabled
  Future<bool> setEqualizerEnabled(bool enabled) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('eq_setEnabled', {
        'enabled': enabled,
      });
      return result == true;
    } catch (e) {
      log('Error setting equalizer enabled: $e');
      return false;
    }
  }

  /// Set equalizer band level
  Future<bool> setEqualizerBandLevel(int bandIndex, double gain) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('eq_setBandLevel', {
        'bandIndex': bandIndex,
        'gain': gain,
      });
      return result == true;
    } catch (e) {
      log('Error setting band level: $e');
      return false;
    }
  }

  /// Get equalizer band levels
  Future<List<double>?> getEqualizerBandLevels() async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('eq_getBandLevels');
      if (result is List) {
        return result.cast<double>();
      }
    } catch (e) {
      log('Error getting band levels: $e');
    }
    return null;
  }

  /// Get equalizer frequencies
  Future<List<double>?> getEqualizerFrequencies() async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('eq_getFrequencies');
      if (result is List) {
        return result.cast<double>();
      }
    } catch (e) {
      log('Error getting frequencies: $e');
    }
    return null;
  }

  /// Set bass boost (0.0 to 1.0)
  Future<bool> setBassBoost(double strength) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('eq_setBassBoost', {
        'strength': strength,
      });
      return result == true;
    } catch (e) {
      log('Error setting bass boost: $e');
      return false;
    }
  }

  /// Dispose and clean up resources
  void dispose() {
    _playerStateController.close();
  }
}
/*
/// iOS-specific audio player that integrates with native AVAudioEngine
/// This service communicates with native iOS code through platform channels
class IOSAudioPlayer {
  static const MethodChannel _channel = MethodChannel('com.example.music_app.ios_audio_player');

  // Event channels for streaming state
  static const EventChannel _playingChannel = EventChannel('com.example.music_app.ios_audio_player/playing_stream');
  static const EventChannel _positionChannel = EventChannel('com.example.music_app.ios_audio_player/position_stream');
  static const EventChannel _durationChannel = EventChannel('com.example.music_app.ios_audio_player/duration_stream');

  bool _isInitialized = false;

  // Streams
  Stream<bool>? _playingStream;
  Stream<Duration>? _positionStream;
  Stream<Duration?>? _durationStream;

  // Current state
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  int _currentIndex = -1;

  // Callbacks
  final StreamController<void> _playerStateController = StreamController<void>.broadcast();
  Stream<void> get playerStateStream => _playerStateController.stream;

  bool get isInitialized => _isInitialized;
  bool get playing => _isPlaying;
  Duration get position => _position;
  Duration? get duration => _duration;
  int? get currentIndex => _currentIndex >= 0 ? _currentIndex : null;

  /// Stream of playing state (true when playing, false when paused)
  Stream<bool> get playingStream {
    _playingStream ??= _playingChannel
        .receiveBroadcastStream()
        .map((dynamic playing) => playing as bool)
        .handleError((error) {
      log('Error in playing stream: $error');
      return false;
    });
    return _playingStream!;
  }

  /// Stream of current playback position
  Stream<Duration> get positionStream {
    _positionStream ??= _positionChannel
        .receiveBroadcastStream()
        .map((dynamic positionMs) {
      final position = Duration(milliseconds: positionMs as int);
      // log("Position Updated: $position");  // Debug log
      return position;
    })
        .handleError((error) {
      log('Error in position stream: $error');
      return Duration.zero;
    });
    return _positionStream!;
  }

  /// Stream of audio duration
  Stream<Duration?> get durationStream {
    _durationStream ??= _durationChannel
        .receiveBroadcastStream()
        .map((dynamic durationMs) {
      if (durationMs == null || durationMs == 0) return null;
      return Duration(milliseconds: durationMs as int);
    })
        .handleError((error) {
      log('Error in duration stream: $error');
      return null;
    });
    return _durationStream!;
  }

  /// Stream of current track index
  Stream<int?> get currentIndexStream {
    // Emit current index whenever player state changes
    return playerStateStream.asyncMap((_) async {
      return await getCurrentIndex();
    });
  }

  /// Initialize the iOS audio player
  Future<bool> initialize() async {
    if (!Platform.isIOS) {
      log('IOSAudioPlayer: Not on iOS platform');
      return false;
    }

    try {
      final result = await _channel.invokeMethod('initialize');
      _isInitialized = result == true;

      if (_isInitialized) {
        // Listen to streams and update local state
        playingStream.listen((playing) {
          _isPlaying = playing;
        });

        positionStream.listen((pos) {
          _position = pos;
        });

        durationStream.listen((dur) {
          _duration = dur;
        });

        log('iOS Audio Player initialized successfully');
      }

      return _isInitialized;
    } catch (e) {
      log('Error initializing iOS audio player: $e');
      return false;
    }
  }

  /// Set playlist with audio files
  Future<void> setAudioSource(
      List<String> filePaths, {
        int initialIndex = 0,
        bool autoPlay = true,
      }) async {
    if (!_isInitialized) {
      throw Exception('Player not initialized');
    }

    try {
      await _channel.invokeMethod('setPlaylist', {
        'filePaths': filePaths,
        'startIndex': initialIndex,
        'autoPlay': autoPlay,
      });

      _currentIndex = initialIndex;
      _playerStateController.add(null);
    } catch (e) {
      log('Error setting audio source: $e');
      rethrow;
    }
  }

  /// Play audio
  Future<void> play() async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('play');
      _playerStateController.add(null);
    } catch (e) {
      log('Error playing: $e');
      rethrow;
    }
  }

  /// Pause audio
  Future<void> pause() async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('pause');
      _playerStateController.add(null);
    } catch (e) {
      log('Error pausing: $e');
      rethrow;
    }
  }

  /// Stop audio
  Future<void> stop() async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('stop');
      _position = Duration.zero;
      _playerStateController.add(null);
    } catch (e) {
      log('Error stopping: $e');
      rethrow;
    }
  }

  /// Seek to position
  Future<void> seek(Duration position, {int? index}) async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('seek', {
        'position': position.inMilliseconds,
        'index': index,
      });

      if (index != null) {
        _currentIndex = index;
      }
      _position = position;
      _playerStateController.add(null);
    } catch (e) {
      log('Error seeking: $e');
      rethrow;
    }
  }

  /// Seek to next track
  Future<void> seekToNext() async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('seekToNext');
      _currentIndex = await getCurrentIndex() ?? 0;
      _playerStateController.add(null);
    } catch (e) {
      log('Error seeking to next: $e');
      rethrow;
    }
  }

  /// Seek to previous track
  Future<void> seekToPrevious() async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('seekToPrevious');
      _currentIndex = await getCurrentIndex() ?? 0;
      _playerStateController.add(null);
    } catch (e) {
      log('Error seeking to previous: $e');
      rethrow;
    }
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('setSpeed', {'speed': speed});
    } catch (e) {
      log('Error setting speed: $e');
      rethrow;
    }
  }

  /// Set loop mode: "off", "one", "all"
  Future<void> setLoopMode(String mode) async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('setLoopMode', {'mode': mode});
    } catch (e) {
      log('Error setting loop mode: $e');
      rethrow;
    }
  }

  /// Set shuffle enabled
  Future<void> setShuffleModeEnabled(bool enabled) async {
    if (!_isInitialized) throw Exception('Player not initialized');

    try {
      await _channel.invokeMethod('setShuffleEnabled', {'enabled': enabled});
    } catch (e) {
      log('Error setting shuffle: $e');
      rethrow;
    }
  }

  /// Get current index
  Future<int?> getCurrentIndex() async {
    if (!_isInitialized) return null;

    try {
      final index = await _channel.invokeMethod('getCurrentIndex');
      return index as int?;
    } catch (e) {
      log('Error getting current index: $e');
      return null;
    }
  }

  /// Check if playing
  Future<bool> isPlaying() async {
    if (!_isInitialized) return false;

    try {
      final playing = await _channel.invokeMethod('isPlaying');
      return playing as bool;
    } catch (e) {
      log('Error checking if playing: $e');
      return false;
    }
  }

  /// Get current position
  Future<Duration> getPosition() async {
    if (!_isInitialized) return Duration.zero;

    try {
      final positionMs = await _channel.invokeMethod('getPosition');
      return Duration(milliseconds: positionMs as int);
    } catch (e) {
      log('Error getting position: $e');
      return Duration.zero;
    }
  }

  /// Get duration
  Future<Duration?> getDuration() async {
    if (!_isInitialized) return null;

    try {
      final durationMs = await _channel.invokeMethod('getDuration');
      if (durationMs == null || durationMs == 0) return null;
      return Duration(milliseconds: durationMs as int);
    } catch (e) {
      log('Error getting duration: $e');
      return null;
    }
  }

  // MARK: - Equalizer Methods

  /// Set equalizer enabled
  Future<bool> setEqualizerEnabled(bool enabled) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('eq_setEnabled', {
        'enabled': enabled,
      });
      return result == true;
    } catch (e) {
      log('Error setting equalizer enabled: $e');
      return false;
    }
  }

  /// Set equalizer band level
  Future<bool> setEqualizerBandLevel(int bandIndex, double gain) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('eq_setBandLevel', {
        'bandIndex': bandIndex,
        'gain': gain,
      });
      return result == true;
    } catch (e) {
      log('Error setting band level: $e');
      return false;
    }
  }

  /// Get equalizer band levels
  Future<List<double>?> getEqualizerBandLevels() async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('eq_getBandLevels');
      if (result is List) {
        return result.cast<double>();
      }
    } catch (e) {
      log('Error getting band levels: $e');
    }
    return null;
  }

  /// Get equalizer frequencies
  Future<List<double>?> getEqualizerFrequencies() async {
    if (!_isInitialized) return null;

    try {
      final result = await _channel.invokeMethod('eq_getFrequencies');
      if (result is List) {
        return result.cast<double>();
      }
    } catch (e) {
      log('Error getting frequencies: $e');
    }
    return null;
  }

  /// Set bass boost (0.0 to 1.0)
  Future<bool> setBassBoost(double strength) async {
    if (!_isInitialized) return false;

    try {
      final result = await _channel.invokeMethod('eq_setBassBoost', {
        'strength': strength,
      });
      return result == true;
    } catch (e) {
      log('Error setting bass boost: $e');
      return false;
    }
  }

  /// Dispose and clean up resources
  void dispose() {
    _playerStateController.close();
  }
}
*/
