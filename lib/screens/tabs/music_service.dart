import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../features/songs/data/models/song_model.dart';
import '../../core/db/app_database.dart';
import '../../services/ios_audio_player_service.dart';
import '../../services/unified_equalizer_service.dart';

class MusicPlayerService {
  static final MusicPlayerService _instance = MusicPlayerService._internal();

  factory MusicPlayerService() => _instance;

  // Platform-specific players
  AudioPlayer? _androidPlayer;
  IOSAudioPlayer? _iosPlayer;

  List<SongsModel> songs = [];
  List<int> _shuffleIndices = []; // Track shuffle order
  // Equalizer
  final UnifiedEqualizerService equalizerService = UnifiedEqualizerService();

  // Emits events when library-affecting stats change
  final StreamController<void> _libraryChangedController =
      StreamController<void>.broadcast();

  Stream<void> get libraryChanged => _libraryChangedController.stream;

  // Emits events when the songs list changes
  final StreamController<List<SongsModel>> _songsChangedController =
      StreamController<List<SongsModel>>.broadcast();

  Stream<List<SongsModel>> get songsChanged => _songsChangedController.stream;

  /// Expose the songs changed controller for direct manipulation
  /// (Used by queue screen for seamless updates)
  StreamController<List<SongsModel>> get songsChangedController =>
      _songsChangedController;

  int? _lastUpdatedSongId;

  /// Cache for Option A: correct "current song ID" during reorder (list updated before player index).
  int? _reorderCurrentSongId;
  int? _reorderTargetIndex;

  /// True only after we've done songs = mutableSongs in swapReorderSongInQueue (so we don't clear cache and use songs[idx] while list is still old).
  bool _reorderListUpdated = false;

  /// When we set _reorderListUpdated = true, store time so we don't clear cache in the same frame (avoids 1-frame glitch).
  DateTime? _reorderListUpdatedAt;
  Timer? _reorderClearTimer;

  // Loop and Shuffle state variables
  LoopMode _loopMode = LoopMode.off;
  bool _isShuffleEnabled = false;
  double _playbackSpeed = 1.0;

  // Loop mode change notifications
  final StreamController<LoopMode> _loopModeController =
      StreamController<LoopMode>.broadcast();

  Stream<LoopMode> get loopModeStream => _loopModeController.stream;

  // Shuffle state change notifications
  final StreamController<bool> _shuffleController =
      StreamController<bool>.broadcast();

  Stream<bool> get shuffleStream => _shuffleController.stream;

  double get playbackSpeed => _playbackSpeed;

  // ============================================
  // Public getters for backward compatibility
  // ============================================

  void updateSongsList(List<SongsModel> newSongs) {
    // Create a new mutable list
    songs = List<SongsModel>.from(newSongs);
    songsChangedController.add(List.from(songs));
    print('📝 Songs list updated: ${songs.length} songs');
  }

  Future<void> removeFromQueueAtIndex(
    int removeIndex,
    int newCurrentIndex,
  ) async {
    if (!Platform.isIOS) {
      throw Exception('This method is only for iOS');
    }

    try {
      print(
        '📱 iOS: Removing song at index $removeIndex, new current: $newCurrentIndex',
      );

      await _iosPlayer!.removeFromQueueAtIndex(removeIndex, newCurrentIndex);

      print('✅ iOS: Song removed seamlessly');
    } catch (e) {
      print('❌ iOS: Error removing song: $e');
      rethrow;
    }
  }

  /// Access to the underlying player (platform-agnostic)
  dynamic get player {
    if (Platform.isAndroid) {
      return _androidPlayer;
    } else if (Platform.isIOS) {
      return _iosPlayer;
    }
    return null;
  }

  /// Duration stream - works on both platforms
  Stream<Duration?> get durationStream {
    if (Platform.isAndroid && _androidPlayer != null) {
      return _androidPlayer!.durationStream;
    } else if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer!.durationStream;
    }
    return Stream.value(null);
  }

  /// Position stream - works on both platforms
  Stream<Duration> get positionStream {
    if (Platform.isAndroid && _androidPlayer != null) {
      return _androidPlayer!.positionStream;
    } else if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer!.positionStream;
    }
    return Stream.value(Duration.zero);
  }

  /// Player state stream - works on both platforms
  Stream<PlayerState> get playerStateStream {
    if (Platform.isAndroid) {
      return _androidPlayer!.playerStateStream;
    } else if (Platform.isIOS) {
      // Convert iOS playing stream to PlayerState
      return _iosPlayer!.playingStream.map((isPlaying) {
        return PlayerState(
          isPlaying,
          isPlaying ? ProcessingState.ready : ProcessingState.idle,
        );
      });
    }
    return Stream.value(PlayerState(false, ProcessingState.idle));
  }

  /// Current duration - works on both platforms
  Duration? get duration {
    if (Platform.isAndroid && _androidPlayer != null) {
      developer.log(
        'android Player ${_androidPlayer == null} ${_androidPlayer!.duration}',
      );
      return _androidPlayer?.duration;
    } else if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer?.duration;
    }
    return null;
  }

  /// Current position - works on both platforms
  Duration get position {
    if (Platform.isAndroid) {
      return _androidPlayer?.position ?? Duration.zero;
    } else if (Platform.isIOS) {
      return _iosPlayer?.position ?? Duration.zero;
    }
    return Duration.zero;
  }

  Stream<double> get playbackSpeedStream {
    if (Platform.isAndroid) {
      return _androidPlayer!.speedStream;
    } else {
      // iOS doesn't support speed stream yet
      return Stream.value(_playbackSpeed);
    }
  }

  bool get isShuffleEnabled => _isShuffleEnabled;

  LoopMode get loopMode => _loopMode;

  // Expose current index
  int get currentIndex {
    if (Platform.isAndroid) {
      return _androidPlayer?.currentIndex ?? -1;
    } else if (Platform.isIOS) {
      return _iosPlayer?.currentIndex ?? -1;
    }
    return -1;
  }

  Stream<int?> get currentIndexStream {
    if (Platform.isAndroid && _androidPlayer != null) {
      return _androidPlayer!.currentIndexStream;
    } else if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer!.currentIndexStream;
    }
    return Stream.value(null);
  }

  int? get currentSongId {
    // Option A: during reorder, return cached playing song ID until player index catches up AND list is updated
    if (_reorderCurrentSongId != null && _reorderTargetIndex != null) {
      if (currentIndex == _reorderTargetIndex &&
          _reorderListUpdated &&
          _reorderListUpdatedAt != null) {
        // Don't clear in the first 100ms after list update (avoids 1-frame glitch when stream emits same frame)
        final elapsed = DateTime.now().difference(_reorderListUpdatedAt!);
        if (elapsed.inMilliseconds >= 100) {
          _reorderClearTimer?.cancel();
          _reorderClearTimer = null;
          _reorderCurrentSongId = null;
          _reorderTargetIndex = null;
          _reorderListUpdated = false;
          _reorderListUpdatedAt = null;
        } else {
          return _reorderCurrentSongId;
        }
      } else {
        return _reorderCurrentSongId;
      }
    }
    final idx = currentIndex;
    if (idx >= 0 && idx < songs.length) return songs[idx].id;
    return null;
  }

  Stream<int?> get currentSongIdStream => currentIndexStream.map((i) {
    final idx = i ?? -1;
    if (idx >= 0 && idx < songs.length) return songs[idx].id;
    return null;
  });

  // Expose play state
  bool get isPlaying {
    if (Platform.isAndroid && _androidPlayer != null) {
      return _androidPlayer?.playing ?? false;
    } else if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer?.playing ?? false;
    }
    return false;
  }

  Stream<bool> get isPlayingStream {
    if (Platform.isAndroid && _androidPlayer != null) {
      return _androidPlayer!.playingStream;
    } else if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer!.playingStream;
    }
    return Stream.value(false);
  }

  MusicPlayerService._internal() {
    _initializePlayers();
  }

  Future<void> _initializePlayers() async {
    if (Platform.isAndroid) {
      // Create Android player with equalizer
      _androidPlayer = equalizerService.createAndroidPlayerWithEqualizer();
      _androidPlayer!.setLoopMode(_loopMode);
      _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

      // Setup Android listeners
      _setupAndroidListeners();

      // DON'T initialize equalizer here - wait for audio to load!
    } else if (Platform.isIOS) {
      _iosPlayer = await equalizerService.createIOSPlayer();
      _setupIOSListeners();

      // iOS equalizer can be initialized immediately
      await _initializeIOSEqualizer();
    }
  }

  Future<void> _initializeAndroidEqualizer() async {
    try {
      await equalizerService.initialize(_androidPlayer!);
      print('Android Equalizer initialized successfully');
    } catch (e) {
      print('Error initializing Android equalizer: $e');
    }
  }

  Future<void> _initializeIOSEqualizer() async {
    try {
      await equalizerService.initialize(_iosPlayer!);
      print('iOS Equalizer initialized successfully');
    } catch (e) {
      print('Error initializing iOS equalizer: $e');
    }
  }

  void _setupAndroidListeners() {
    _androidPlayer!.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        if (currentIndex >= (songs.length - 1)) {
          if (_loopMode == LoopMode.off && currentIndex >= (songs.length - 1)) {
            _androidPlayer!.stop();
          } else {
            await _androidPlayer!.seek(Duration.zero);
            await _androidPlayer!.play();
          }
        } else {
          await _androidPlayer!.seekToNext();
          await _androidPlayer!.play();
        }
      }
    });

    _androidPlayer!.playingStream.listen((isPlaying) async {
      if (isPlaying) {
        await _updateSongStats();
      }
    });

    _androidPlayer!.currentIndexStream.listen((i) async {
      final idx = i ?? -1;
      if (!_androidPlayer!.playing) return;
      if (idx < 0 || idx >= songs.length) return;
      await _updateSongStats();
    });

    _androidPlayer!.speedStream.listen((speed) {
      _playbackSpeed = speed;
    });
  }

  void _setupIOSListeners() {
    _iosPlayer!.playingStream.listen((isPlaying) async {
      if (isPlaying) {
        await _updateSongStats();
      }
    });

    // Listen to native index changes - no manual tracking needed!
    _iosPlayer!.currentIndexStream.listen((i) async {
      final idx = i ?? -1;
      if (!_iosPlayer!.playing) return;
      if (idx < 0 || idx >= songs.length) return;

      await _updateSongStats();
    });
  }

  Future<void> _updateSongStats() async {
    final idx = currentIndex;
    if (idx >= 0 && idx < songs.length) {
      final current = songs[idx];
      if (_lastUpdatedSongId == current.id) return;
      try {
        final db = await AppDatabase.instance();
        await db.rawUpdate(
          "UPDATE songs SET play_count = play_count + 1, last_played = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW') WHERE id = ?",
          [current.id],
        );
        _libraryChangedController.add(null);
        _lastUpdatedSongId = current.id;
      } catch (_) {}
    }
  }

  // Generate shuffle indices in random order
  void _generateShuffleIndices() {
    _shuffleIndices = List.generate(songs.length, (i) => i);
    _shuffleIndices.shuffle(Random());
    print('🔀 Shuffle indices generated: $_shuffleIndices');
  }

  Future<void> setPlaylist(
    List<SongsModel> songModels, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    if (songModels.isEmpty) {
      await stopAndClearQueue();
      return;
    }

    _reorderClearTimer?.cancel();
    _reorderClearTimer = null;
    _reorderCurrentSongId = null;
    _reorderTargetIndex = null;
    _reorderListUpdated = false;
    _reorderListUpdatedAt = null;

    print(
      '🎵 MusicPlayerService.setPlaylist called - startIndex: $startIndex, songCount: ${songModels.length}',
    );

    // songs = songModels;
    // _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      print('📱 Android: Setting playlist...');
      await _setAndroidPlaylist(songModels, startIndex, autoPlay);
    } else if (Platform.isIOS) {
      print('🍎 iOS: Setting playlist...');
      await _setIOSPlaylist(songModels, startIndex, autoPlay);
    }
  }

  Future<void> _setAndroidPlaylist(
    List<SongsModel> songModels,
    int startIndex,
    bool autoPlay,
  ) async {
    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songModels.map((song) {
        Uri? artUri;
        try {
          if (song.artwork_path != null && song.artwork_path!.isNotEmpty) {
            artUri = Uri.file(song.artwork_path!);
          }
        } catch (e) {
          // Ignore artwork errors
        }

        return AudioSource.uri(
          Uri.file(song.filePath),
          tag: MediaItem(
            id: song.id?.toString() ?? '',
            title: song.title,
            artist: song.artist,
            album: song.album,
            duration: Duration(milliseconds: song.duration),
            artUri: artUri,
          ),
        );
      }).toList(),
    );

    try {
      print('📍 Step 1: Setting audio source...');
      // ✅ Set the audio source - this will update the playlist
      await _androidPlayer!.setAudioSource(playlist, initialIndex: startIndex);

      print('✅ Step 1: Audio source set at index $startIndex');

      // ✅ Step 2: Set shuffle mode
      print('📍 Step 2: Setting shuffle to $_isShuffleEnabled');
      await _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

      if (_isShuffleEnabled) {
        await _androidPlayer!.shuffle();
        print('✅ Android: Shuffle enabled');
      } else {
        print('✅ Step 2: Shuffle disabled');
      }

      // IMPORTANT: Wait for duration to load
      print('📍 Step 3: Waiting for duration to load...');
      await _androidPlayer!.durationStream.firstWhere((d) => d != null);
      print('✅ Step 3: Duration loaded');

      // ✅ NOW initialize equalizer after audio is loaded
      if (!equalizerService.isInitialized) {
        await _initializeAndroidEqualizer();
      }

      songs = songModels;
      _songsChangedController.add(songs);

      // ✅ Only play if autoPlay is true
      // If autoPlay is false and music is already playing, it will continue playing the old song
      // This allows playlist updates without interruption
      if (autoPlay) {
        await _androidPlayer!.play();
        print('▶️ Android: Playing from shuffle index $startIndex');
      } else {
        // ✅ If already playing, don't pause - just update the queue
        if (isPlaying) {
          print(
            '⏸️ Android: autoPlay is false and music already playing - continuing current playback',
          );
        } else {
          print(
            '⏸️ Android: autoPlay is false - playlist ready but not playing',
          );
        }
      }
    } catch (e) {
      print('❌ Android Playlist Error: $e');
      rethrow;
    }

    print('✅ Android: Playlist set successfully');
  }

  Future<void> _setIOSPlaylist(
    List<SongsModel> songModels,
    int startIndex,
    bool autoPlay,
  ) async {
    final filePaths = songModels.map((song) => song.filePath).toList();

    print('📀 iOS: Setting playlist with ${filePaths.length} songs');
    print(
      '  Starting at index: $startIndex, autoPlay: $autoPlay, shuffle: $_isShuffleEnabled',
    );

    try {
      // ✅ CRITICAL FIX: Pass autoPlay=true to native and WAIT for completion
      print('📍 Step 1: Setting audio source and waiting...');
      await _iosPlayer!.setAudioSource(
        filePaths,
        initialIndex: startIndex,
        autoPlay: autoPlay, // Pass autoPlay directly
      );
      print(
        '✅ Step 1: Audio source set and playback started (if autoPlay=true)',
      );

      // Set loop mode
      String iosLoopMode = 'off';
      if (_loopMode == LoopMode.one) {
        iosLoopMode = 'one';
      } else if (_loopMode == LoopMode.all) {
        iosLoopMode = 'all';
      }
      print('📍 Step 2: Setting loop mode to $iosLoopMode');
      await _iosPlayer!.setLoopMode(iosLoopMode);
      print('✅ Step 2: Loop mode set');

      // Set shuffle
      print('📍 Step 3: Setting shuffle to $_isShuffleEnabled');
      await _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
      print('✅ Step 3: Shuffle mode set');

      print('✅ iOS: Playlist set successfully');
    } catch (e) {
      print('❌ Error in _setIOSPlaylist: $e');
      rethrow;
    }
  }

  /*
  Future<void> _setIOSPlaylist(List<SongsModel> songModels, int startIndex, bool autoPlay) async {
    final filePaths = songModels.map((song) => song.filePath).toList();

    print('📀 iOS: Setting playlist with ${filePaths.length} songs');
    print('  Starting at index: $startIndex, autoPlay: $autoPlay, shuffle: $_isShuffleEnabled');


    try{
      print('📍 Step 1: Setting audio source (no wait)...');
      _iosPlayer!.setAudioSource(
        filePaths,
        initialIndex: startIndex,
        autoPlay: false, // Always false, we control playback manually
      ).then((_) {
        print('✅ Audio source loading completed in background');
      }).catchError((e) {
        print('❌ Error loading audio source: $e');
      });
      print('✅ Step 1: Audio source set (launching in background)');

    // Wait for duration to load before playing

      // Set loop mode
      String iosLoopMode = 'off';
      if (_loopMode == LoopMode.one) {
        iosLoopMode = 'one';
      } else if (_loopMode == LoopMode.all) {
        iosLoopMode = 'all';
      }
      print('📍 Step 2: Setting loop mode to $iosLoopMode');
      await _iosPlayer!.setLoopMode(iosLoopMode);
      print('✅ Step 2: Loop mode set');

      // Set shuffle
      print('📍 Step 3: Setting shuffle to $_isShuffleEnabled');
      await _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
      print('✅ Step 3: Shuffle mode set');

      // Wait a bit for everything to settle
      print('📍 Step 4: Waiting 150ms for initialization...');
      await Future.delayed(Duration(milliseconds: 200));
      print('✅ Step 4: Initialization complete');

      if (autoPlay) {
        print('📍 Step 5: Starting playback (autoPlay: true)...');
        await _iosPlayer!.play();
        print('✅ Step 5: Play command executed');
      } else {
        if (isPlaying) {
          print('⏸️ Step 5: autoPlay is false and music already playing - continuing current playback');
        } else {
          print('⏸️ Step 5: autoPlay is false - playlist ready but not playing');
        }
      }
      print('✅ iOS: Playlist set successfully');
    }catch(e){
      print('❌ Error in _setIOSPlaylist: $e');
      rethrow;
    }





  }*/

  Future<void> setShufflePlaylist(
    List<SongsModel> songModels, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    // Same as setPlaylist but ensures shuffle is on
    _isShuffleEnabled = true;
    _generateShuffleIndices();

    // Get a random starting index from shuffle indices
    // final randomStartIndex = _shuffleIndices[0];
    final randomStartIndex = Random().nextInt(songModels.length);

    print(
      '🔀 Shuffle Playlist - Starting from random shuffle index: $randomStartIndex (shuffle order: $_shuffleIndices)',
    );
    print('🔀 Setting playlist with shuffle enabled');

    songs = songModels;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      await _setAndroidPlaylist(songModels, randomStartIndex, autoPlay);
      // Enable shuffle on Android
      await _androidPlayer!.setShuffleModeEnabled(true);
      await _androidPlayer!.shuffle();
    } else if (Platform.isIOS) {
      // ✅ CRITICAL: Enable shuffle BEFORE setting playlist on iOS
      await _iosPlayer!.setShuffleModeEnabled(true);
      print('✅ iOS: Shuffle mode enabled');

      // Now set the playlist with shuffle already enabled
      await _setIOSPlaylist(songModels, randomStartIndex, autoPlay);
      print('✅ iOS: Playlist set with shuffle enabled');
    }
    // await setPlaylist(songModels, startIndex: startIndex, autoPlay: autoPlay);
  }

  Future<void> resetPlaylist(List<SongsModel> songModels) async {
    // songs = songModels;
    // _songsChangedController.add(songs);
    // await stop();
    if (songModels.isEmpty) {
      await stopAndClearQueue();
    } else {
      await setPlaylist(songModels);
    }
  }

  Future<void> play() async {
    if (Platform.isAndroid) {
      developer.log(
        '▶️ Android: Calling play()... ${_androidPlayer!.processingState == ProcessingState.completed}',
      );
      if (_androidPlayer!.processingState == ProcessingState.completed) {
        await _androidPlayer!.seek(Duration.zero);
      }
      await _androidPlayer!.play();
    } else if (Platform.isIOS) {
      try {
        print('▶️ iOS: Calling play()...');
        await _iosPlayer!.play();
        print('✅ iOS: Play command executed successfully');
      } catch (e) {
        print('❌ iOS: Play error: $e');
        rethrow;
      }
    }
  }

  Future<void> pause() async {
    if (Platform.isAndroid) {
      await _androidPlayer!.pause();
    } else if (Platform.isIOS) {
      await _iosPlayer!.pause();
    }
  }

  bool _isChangingTrack = false;

  Future<void> next() async {
    if (_isChangingTrack) {
      print('⚠️ Track change already in progress, ignoring next() call');
      return;
    }

    _reorderClearTimer?.cancel();
    _reorderClearTimer = null;
    _reorderCurrentSongId = null;
    _reorderTargetIndex = null;
    _reorderListUpdated = false;
    _reorderListUpdatedAt = null;
    _isChangingTrack = true;

    if (Platform.isAndroid) {
      final nextIndex = (currentIndex + 1) % songs.length;
      await _androidPlayer!.seek(Duration.zero, index: nextIndex);
      // await _androidPlayer!.play();
    } else if (Platform.isIOS) {
      print(
        '🎵 MusicPlayerService.next() called - current index: $currentIndex, total songs: ${songs.length}',
      );
      await _iosPlayer!.seekToNext();
    }

    // Clear flag after delay
    Future.delayed(Duration(milliseconds: 500), () {
      _isChangingTrack = false;
    });
  }

  Future<void> stop() async {
    try {
      if (Platform.isAndroid) {
        await _androidPlayer!.stop();
        print('⏹️ Android: Stopped');
      } else if (Platform.isIOS) {
        await _iosPlayer!.stop();
        print('⏹️ iOS: Stopped');
      }
    } catch (e) {
      print('❌ Stop error: $e');
    }
  }

  Future<void> stopAndClearQueue() async {
    try {
      if (Platform.isAndroid && _androidPlayer != null) {
        await _androidPlayer!.stop();
        await _androidPlayer!.seek(Duration.zero);
      } else if (Platform.isIOS && _iosPlayer != null) {
        await _iosPlayer!.stop();
        await _iosPlayer!.seek(Duration.zero);
      }
    } catch (_) {}

    // 🔴 CRITICAL: reset internal state
    // songs.clear();
    songs = [];
    _shuffleIndices.clear();
    _lastUpdatedSongId = null;
    _reorderClearTimer?.cancel();
    _reorderClearTimer = null;
    _reorderCurrentSongId = null;
    _reorderTargetIndex = null;
    _reorderListUpdated = false;
    _reorderListUpdatedAt = null;

    // Reset modes
    _isShuffleEnabled = false;
    _loopMode = LoopMode.off;

    // 🔴 Notify ALL listeners
    _songsChangedController.add([]);

    print('✅ Queue cleared and playback stopped');
  }

  Future<void> previous() async {
    if (_isChangingTrack) {
      print('⚠️ Track change already in progress, ignoring previous() call');
      return;
    }

    _reorderClearTimer?.cancel();
    _reorderClearTimer = null;
    _reorderCurrentSongId = null;
    _reorderTargetIndex = null;
    _reorderListUpdated = false;
    _reorderListUpdatedAt = null;
    _isChangingTrack = true;

    if (Platform.isAndroid) {
      final prevIndex = currentIndex > 0 ? currentIndex - 1 : songs.length - 1;
      await _androidPlayer!.seek(Duration.zero, index: prevIndex);
      await _androidPlayer!.play();
    } else if (Platform.isIOS) {
      await _iosPlayer!.seekToPrevious();
    }

    // Clear flag after delay
    Future.delayed(Duration(milliseconds: 500), () {
      _isChangingTrack = false;
    });
  }

  Future<void> seek(Duration position, {int? index}) async {
    if (Platform.isAndroid) {
      await _androidPlayer!.seek(position, index: index);
    } else if (Platform.isIOS) {
      await _iosPlayer!.seek(position, index: index);
    }
  }

  Future<void> toggleShuffle() async {
    _isShuffleEnabled = !_isShuffleEnabled;
    if (Platform.isAndroid) {
      await _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

      if (_isShuffleEnabled) {
        await _androidPlayer!.shuffle();
        print('✅ Android Shuffle: ON - Playlist shuffled');
      } else {
        print('✅ Android Shuffle: OFF - Normal order');
      }
    } else if (Platform.isIOS) {
      await _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
      print('✅ iOS Shuffle: ${_isShuffleEnabled ? "ON" : "OFF"}');
    }
    // Notify listeners that shuffle state changed
    _shuffleController.add(_isShuffleEnabled);
    // if (Platform.isAndroid) {
    //   await _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
    //   if (_isShuffleEnabled) {
    //     await _androidPlayer!.shuffle();
    //     final total = songs.length;
    //     if (total > 0) {
    //       final randomIndex = (DateTime.now().millisecondsSinceEpoch % total);
    //       await _androidPlayer!.seek(Duration.zero, index: randomIndex);
    //     }
    //   }
    // } else if (Platform.isIOS) {
    //   await _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
    // }
  }

  Future<void> ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition() async {
    if (!_isShuffleEnabled) {
      _isShuffleEnabled = true;
      _generateShuffleIndices();
      if (Platform.isAndroid) {
        await _androidPlayer!.setShuffleModeEnabled(true);
        await _androidPlayer!.shuffle();
        // final total = songs.length;
        // if (total > 0) {
        //   final randomIndex = Random().nextInt(total);
        //   await _androidPlayer!.seek(Duration.zero, index: randomIndex);
        //   await _androidPlayer!.currentIndexStream.firstWhere((idx) => idx == randomIndex);
        // }
      } else if (Platform.isIOS) {
        await _iosPlayer!.setShuffleModeEnabled(true);
        print('✅ iOS: Shuffle enabled');
      }
    }
  }

  Future<void> ensureShuffleOnAndReshuffle() async {
    if (!_isShuffleEnabled) {
      _isShuffleEnabled = true;

      if (Platform.isAndroid) {
        await _androidPlayer!.setShuffleModeEnabled(true);
        await _androidPlayer!.shuffle();
        // final total = songs.length;
        // if (total > 0 && _androidPlayer!.currentIndex == null) {
        //   final randomIndex = (DateTime.now().millisecondsSinceEpoch % total);
        //   await _androidPlayer!.seek(Duration.zero, index: randomIndex);
        // }
      } else if (Platform.isIOS) {
        await _iosPlayer!.setShuffleModeEnabled(true);
        print('✅ iOS: Shuffle ON');
      }
    }
  }

  Future<void> ensureShuffleOff() async {
    if (_isShuffleEnabled) {
      _isShuffleEnabled = false;

      if (Platform.isAndroid) {
        await _androidPlayer!.setShuffleModeEnabled(false);
        print('✅ Android Shuffle: OFF');
      } else if (Platform.isIOS) {
        await _iosPlayer!.setShuffleModeEnabled(false);
        print('✅ iOS Shuffle: OFF');
      }
    } else {
      print('ℹ️ Shuffle already OFF');
    }
    // if (_isShuffleEnabled) {
    //   _isShuffleEnabled = false;
    //
    //   if (Platform.isAndroid) {
    //     await _androidPlayer!.setShuffleModeEnabled(false);
    //   } else if (Platform.isIOS) {
    //     await _iosPlayer!.setShuffleModeEnabled(false);
    //   }
    // }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final clampedSpeed = speed.clamp(0.5, 2.0);
    _playbackSpeed = clampedSpeed;

    if (Platform.isAndroid) {
      await _androidPlayer!.setSpeed(clampedSpeed);
    } else if (Platform.isIOS) {
      await _iosPlayer!.setSpeed(clampedSpeed);
    }
  }

  Future<void> toggleRepeat() async {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }

    if (Platform.isAndroid) {
      await _androidPlayer!.setLoopMode(_loopMode);
      print('✅ Android Loop Mode: $_loopMode');
    } else if (Platform.isIOS) {
      String iosLoopMode = 'off';
      if (_loopMode == LoopMode.one) {
        iosLoopMode = 'one';
      } else if (_loopMode == LoopMode.all) {
        iosLoopMode = 'all';
      }
      await _iosPlayer!.setLoopMode(iosLoopMode);
    }

    // Notify listeners (e.g. queue screen, mini player) that loop mode changed
    _loopModeController.add(_loopMode);
  }

  /// Re-schedule the current track to apply new loop mode immediately
  Future<void> _scheduleLoopModeUpdate() async {
    // For both Android and iOS, the loop mode is already set via setLoopMode()
    // The native players will apply it on the next completion event
    // No need to seek or reschedule - just let it continue playing
    print('✅ Loop mode updated - will apply on next track completion');
  }

  // Optimized updateSongsInQueue - only for major changes (not reordering)
  Future<void> updateSongsInQueue(List<SongsModel> newSongsList) async {
    print('🎵 Updating songs queue (major update)');

    // ✅ CRITICAL: Ensure we have a mutable copy
    final mutableSongsList = List<SongsModel>.from(newSongsList);

    // Get current state
    final wasPlaying = isPlaying;
    final currentPlayingSongId = currentSongId;
    final currentPos = position;

    print('  Current song ID: $currentPlayingSongId');
    print('  Was playing: $wasPlaying');

    // Update internal list
    songs = mutableSongsList;
    _songsChangedController.add(songs);

    // Find new index by song ID
    int newCurrentIndex = 0;
    if (currentPlayingSongId != null) {
      final foundIndex = mutableSongsList.indexWhere(
        (song) => song.id == currentPlayingSongId,
      );
      if (foundIndex >= 0) {
        newCurrentIndex = foundIndex;
        print('  Found current song at new index: $newCurrentIndex');
      } else {
        print('  ⚠️ Current song not found in new list, defaulting to 0');
      }
    }

    if (Platform.isAndroid) {
      try {
        final source = _androidPlayer!.audioSource;

        if (source is ConcatenatingAudioSource) {
          final currentCount = source.children.length;
          final newCount = mutableSongsList.length;

          print(
            '  Android: Modifying playlist (old: $currentCount, new: $newCount)',
          );

          // ✅ FIX: Track if we need to adjust the player's internal index
          bool needsIndexAdjustment = currentCount != newCount;

          // Smart update: only modify what changed
          if (currentCount > newCount) {
            // Remove excess items from the end
            for (int i = currentCount - 1; i >= newCount; i--) {
              await source.removeAt(i);
            }
          } else if (newCount > currentCount) {
            // Add new items
            for (int i = currentCount; i < newCount; i++) {
              await source.add(_createAudioSource(mutableSongsList[i]));
            }
          }

          // ✅ If the current playing index changed, we need to rebuild to update it
          if (needsIndexAdjustment && currentIndex != newCurrentIndex) {
            print(
              '  Index changed: $currentIndex → $newCurrentIndex, rebuilding...',
            );
            await _rebuildPlaylist(
              mutableSongsList,
              newCurrentIndex,
              currentPos,
              wasPlaying,
            );
          } else {
            print('✅ Android: Queue updated via smart modification');
          }
        } else {
          // Fallback: full rebuild
          await _rebuildPlaylist(
            mutableSongsList,
            newCurrentIndex,
            currentPos,
            wasPlaying,
          );
        }
      } catch (e) {
        print('❌ Android update error: $e, falling back to rebuild');
        await _rebuildPlaylist(
          mutableSongsList,
          newCurrentIndex,
          currentPos,
          wasPlaying,
        );
      }
    } else if (Platform.isIOS) {
      // iOS: Always rebuild to ensure correct index
      await _rebuildIOSPlaylist(mutableSongsList, newCurrentIndex, wasPlaying);
    }
  }

  // Helper: Rebuild Android playlist
  Future<void> _rebuildPlaylist(
    List<SongsModel> songsList,
    int newIndex,
    Duration currentPos,
    bool wasPlaying,
  ) async {
    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songsList.map(_createAudioSource).toList(),
    );

    await _androidPlayer!.setAudioSource(
      playlist,
      initialIndex: newIndex,
      initialPosition: currentPos,
      preload: false,
    );

    _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

    if (wasPlaying) {
      _androidPlayer!.play();
    }
  }

  // Helper: Rebuild iOS playlist
  Future<void> _rebuildIOSPlaylist(
    List<SongsModel> songsList,
    int startIndex,
    bool autoPlay,
  ) async {
    final filePaths = songsList.map((song) => song.filePath).toList();

    await _iosPlayer!.setAudioSource(
      filePaths,
      initialIndex: startIndex,
      autoPlay: autoPlay,
    );

    _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

    String iosLoopMode = 'off';
    if (_loopMode == LoopMode.one) {
      iosLoopMode = 'one';
    } else if (_loopMode == LoopMode.all) {
      iosLoopMode = 'all';
    }
    _iosPlayer!.setLoopMode(iosLoopMode);
  }

  // Keep the old _rebuildAndroidPlaylist for backwards compatibility
  Future<void> _rebuildAndroidPlaylist(
    List<SongsModel> songsList, {
    bool preservePlayback = false,
  }) async {
    final wasPlaying = isPlaying;
    final currentIdx = currentIndex;
    final currentPos = position;

    if (preservePlayback && currentIdx >= 0) {
      await _rebuildPlaylist(songsList, currentIdx, currentPos, wasPlaying);
    } else {
      await _rebuildPlaylist(songsList, 0, Duration.zero, false);
    }
  }

  // Helper: Create AudioSource from song
  AudioSource _createAudioSource(SongsModel song) {
    Uri? artUri;
    try {
      if (song.artwork_path != null && song.artwork_path!.isNotEmpty) {
        artUri = Uri.file(song.artwork_path!);
      }
    } catch (e) {}

    return AudioSource.uri(
      Uri.file(song.filePath),
      tag: MediaItem(
        id: song.id?.toString() ?? '',
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: Duration(milliseconds: song.duration),
        artUri: artUri,
      ),
    );
  }

  /*  Future<void> updateSongsInQueue(List<SongsModel> newSongsList) async {
    print('🎵 Updating songs queue (seamless update)');
    print('  Old queue size: ${songs.length}');
    print('  New queue size: ${newSongsList.length}');
    print('  Current playing index: $currentIndex');

    // Get current state BEFORE any updates
    final wasPlaying = isPlaying;
    final currentPlayingSongId = currentSongId; // Get the ID of currently playing song
    final currentPos = position; // Get current playback position

    print('  Current state: playing=$wasPlaying, songId=$currentPlayingSongId, pos=${currentPos.inSeconds}s');

    // Update the songs list
    songs = newSongsList;

    // Notify listeners that songs changed
    _songsChangedController.add(songs);

    // Find the new index of the currently playing song
    int newCurrentIndex = 0;
    if (currentPlayingSongId != null) {
      final foundIndex = newSongsList.indexWhere((song) => song.id == currentPlayingSongId);
      if (foundIndex >= 0) {
        newCurrentIndex = foundIndex;
        print('  Found current song at new index: $newCurrentIndex');
      } else {
        print('  ⚠️ Current song not found in new list, defaulting to index 0');
      }
    }

    if (Platform.isAndroid) {
      try {
        print('📱 Android: Seamless queue update');

        // Build new playlist
        final playlist = ConcatenatingAudioSource(
          useLazyPreparation: true,
          children: newSongsList.map((song) {
            Uri? artUri;
            try {
              if (song.artwork_path != null && song.artwork_path!.isNotEmpty) {
                artUri = Uri.file(song.artwork_path!);
              }
            } catch (e) {
              // Ignore artwork errors
            }

            return AudioSource.uri(
              Uri.file(song.filePath),
              tag: MediaItem(
                id: song.id?.toString() ?? '',
                title: song.title,
                artist: song.artist,
                album: song.album,
                duration: Duration(milliseconds: song.duration),
                artUri: artUri,
              ),
            );
          }).toList(),
        );

        // ⚡ OPTIMIZATION: Don't pause, just rebuild in one go
        // Set audio source with current position preserved
        await _androidPlayer!.setAudioSource(
          playlist,
          initialIndex: newCurrentIndex,
          initialPosition: currentPos, // ✅ Preserve playback position
          preload: false, // Don't preload to reduce delay
        );

        // Restore shuffle state (without awaiting to reduce delay)
        _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

        // Resume playback immediately if it was playing
        if (wasPlaying) {
          _androidPlayer!.play(); // Don't await - let it play immediately
        }

        print('✅ Android queue updated - Index: $newCurrentIndex, Pos: ${currentPos.inSeconds}s, Playing: $wasPlaying');
      } catch (e) {
        print('❌ Error updating Android queue: $e');
        rethrow;
      }
    } else if (Platform.isIOS) {
      try {
        final filePaths = newSongsList.map((song) => song.filePath).toList();

        print('📀 iOS: Seamless queue update');
        print('  Target: idx=$newCurrentIndex, pos=${currentPos.inSeconds}s, playing=$wasPlaying');

        // ⚡ OPTIMIZATION: Don't pause/unpause, rebuild instantly
        // Update the audio source with current index
        await _iosPlayer!.setAudioSource(
          filePaths,
          initialIndex: newCurrentIndex,
          autoPlay: wasPlaying, // ✅ Auto-resume if was playing
        );
        print('✅ iOS: Audio source set');

        // Restore settings quickly (no await to reduce delay)
        _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

        String iosLoopMode = 'off';
        if (_loopMode == LoopMode.one) {
          iosLoopMode = 'one';
        } else if (_loopMode == LoopMode.all) {
          iosLoopMode = 'all';
        }
        _iosPlayer!.setLoopMode(iosLoopMode);

        // ⚡ Seek to exact position (this is critical for seamless playback)
        if (currentPos > Duration.zero) {
          await _iosPlayer!.seek(currentPos, index: newCurrentIndex);
          print('✅ iOS: Seeked to ${currentPos.inSeconds}s at index $newCurrentIndex');
        }

        print('✅ iOS queue updated successfully');
      } catch (e) {
        print('❌ Error updating iOS queue: $e');
        rethrow;
      }
    }

    print('✅ Queue updated successfully');
  }*/

  void _scheduleReorderCacheClear() {
    _reorderClearTimer?.cancel();
    _reorderClearTimer = Timer(const Duration(milliseconds: 350), () {
      _reorderCurrentSongId = null;
      _reorderTargetIndex = null;
      _reorderListUpdated = false;
      _reorderListUpdatedAt = null;
      _reorderClearTimer = null;
    });
  }

  /// New index of the item that was at [currentIndex] after reorder: remove at [oldIndex], insert at [newIndex].
  static int _newCurrentIndexAfterReorder(
    int oldIndex,
    int newIndex,
    int currentIndex,
  ) {
    final c = oldIndex < currentIndex ? currentIndex - 1 : currentIndex;
    return c + (newIndex <= c ? 1 : 0);
  }

  /// Call this before updating UI list on reorder so currentSongId is correct on first rebuild.
  void prepareReorderForCurrentSong(int oldIndex, int newIndex) {
    _reorderListUpdated = false;
    _reorderListUpdatedAt = null;
    _reorderClearTimer?.cancel();
    final idx = currentIndex;
    if (idx >= 0 && idx < songs.length) {
      if (idx == oldIndex) {
        // Moving the currently playing item: cache its ID and its new index
        _reorderCurrentSongId = songs[oldIndex].id;
        _reorderTargetIndex = newIndex;
      } else {
        // Moving a different item: cache actual current song's ID and where it will be after reorder
        _reorderCurrentSongId = songs[idx].id;
        _reorderTargetIndex = _newCurrentIndexAfterReorder(
          oldIndex,
          newIndex,
          idx,
        );
      }
    } else {
      _reorderCurrentSongId = null;
      _reorderTargetIndex = null;
    }
  }

  Future<void> swapReorderSongInQueue(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    print('🔄 Reordering song: $oldIndex → $newIndex (seamless mode)');

    // Option A: cache actual current song's ID and its (new) index so gif stays on correct row
    _reorderListUpdated = false;
    _reorderListUpdatedAt = null;
    _reorderClearTimer?.cancel();
    final idx = currentIndex;
    if (idx >= 0 && idx < songs.length) {
      if (idx == oldIndex) {
        _reorderCurrentSongId = songs[oldIndex].id;
        _reorderTargetIndex = newIndex;
      } else {
        _reorderCurrentSongId = songs[idx].id;
        _reorderTargetIndex = _newCurrentIndexAfterReorder(
          oldIndex,
          newIndex,
          idx,
        );
      }
    } else {
      _reorderCurrentSongId = null;
      _reorderTargetIndex = null;
    }

    // ✅ CRITICAL FIX: Create a mutable copy of the list
    final mutableSongs = List<SongsModel>.from(songs);

    // Update internal songs list
    final item = mutableSongs.removeAt(oldIndex);
    mutableSongs.insert(newIndex, item);

    if (Platform.isAndroid) {
      try {
        // ⚡ ANDROID: Use ConcatenatingAudioSource's move() - NO REBUILD!
        final source = _androidPlayer!.audioSource;
        if (source is ConcatenatingAudioSource) {
          // This is INSTANT - no audio interruption at all!
          await source.move(oldIndex, newIndex);
          songs = mutableSongs;
          _reorderListUpdated = true;
          _reorderListUpdatedAt = DateTime.now();
          _scheduleReorderCacheClear();
          _songsChangedController.add(songs);
          print('✅ Android: Song moved seamlessly (no rebuild)');
        } else {
          print(
            '⚠️ Android: Source is not ConcatenatingAudioSource, falling back',
          );
          songs = mutableSongs;
          _reorderListUpdated = true;
          _reorderListUpdatedAt = DateTime.now();
          _scheduleReorderCacheClear();
          _songsChangedController.add(songs);
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        print('❌ Android reorder error: $e');
        songs = mutableSongs;
        _reorderListUpdated = true;
        _reorderListUpdatedAt = DateTime.now();
        _scheduleReorderCacheClear();
        _songsChangedController.add(songs);
      }
    } else if (Platform.isIOS) {
      // iOS: Update internal list; native playlist not updated during playback.
      // Option A cache ensures currentSongId stays correct (player index won't change).
      songs = mutableSongs;
      _reorderListUpdated = true;
      _reorderListUpdatedAt = DateTime.now();
      _scheduleReorderCacheClear();
      _songsChangedController.add(songs);
      print('✅ iOS: Internal list updated (no native update during playback)');

      if (!isPlaying && currentIndex < 0) {
        await updateSongsInQueue(songs);
      }
    }
  }

  Future<void> reorderSongInQueue(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    print('🔄 Reordering song: $oldIndex → $newIndex (seamless mode)');

    // ✅ CRITICAL FIX: Create a mutable copy of the list
    final mutableSongs = List<SongsModel>.from(songs);

    // Update internal songs list
    final item = mutableSongs.removeAt(oldIndex);
    mutableSongs.insert(newIndex, item);

    // Now update the actual songs list
    songs = mutableSongs;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      try {
        // ⚡ ANDROID: Use ConcatenatingAudioSource's move() - NO REBUILD!
        final source = _androidPlayer!.audioSource;
        if (source is ConcatenatingAudioSource) {
          // This is INSTANT - no audio interruption at all!
          await source.move(oldIndex, newIndex);
          print('✅ Android: Song moved seamlessly (no rebuild)');
        } else {
          print(
            '⚠️ Android: Source is not ConcatenatingAudioSource, falling back',
          );
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        print('❌ Android reorder error: $e');
      }
    } else if (Platform.isIOS) {
      // iOS: For reordering, we DON'T update the native playlist at all
      // Just update our internal list and wait for natural transitions
      // The native player will keep playing the current song uninterrupted
      print('✅ iOS: Internal list updated (no native update during playback)');

      // Only update the native playlist if nothing is playing
      if (!isPlaying && currentIndex < 0) {
        await updateSongsInQueue(songs);
      }
    }
  }

  Future<int> playNextMultipleSongs(List<SongsModel> nextSongs) async {
    if (nextSongs.isEmpty) return 0;
    if (currentIndex < 0 || currentIndex >= songs.length) return 0;

    print('⏭️ Play Next (multiple songs): ${nextSongs.length}');

    // 🔹 Copy current queue (DO NOT REMOVE FROM THIS)
    final mutableSongs = List<SongsModel>.from(songs);

    // 🔹 Filter songs that are NOT already in queue
    final addingList = nextSongs
        .where((song) => !songs.any((q) => q.id == song.id))
        .toList();

    if (addingList.isEmpty) return 0;

    // 🔹 Safe insert index
    final rawInsertIndex = currentIndex + 1;
    final insertIndex = rawInsertIndex.clamp(0, mutableSongs.length);

    // 🔹 Insert new songs ONLY
    mutableSongs.insertAll(insertIndex, addingList);

    // 🔹 Update internal queue
    songs = mutableSongs;
    _songsChangedController.add(songs);

    // ====================== ANDROID ======================
    if (Platform.isAndroid) {
      try {
        final player = _androidPlayer!;
        final source = player.audioSource;

        if (source is ConcatenatingAudioSource) {
          // 🔒 Preserve playback state
          final int? currentIndexBefore = player.currentIndex;
          final Duration currentPosition = player.position;
          final bool wasPlaying = player.playing;

          int targetIndex = insertIndex;

          for (final song in addingList) {
            await source.insert(targetIndex, _createAudioSource(song));
            targetIndex++;
          }

          // 🔁 Restore playback
          if (currentIndexBefore != null &&
              player.currentIndex == currentIndexBefore) {
            await player.seek(currentPosition, index: currentIndexBefore);
            if (wasPlaying) await player.play();
          }
        } else {
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        developer.log('❌ Android Play Next error: $e');
      }
    }
    // ======================== iOS ========================
    else if (Platform.isIOS) {
      // Do NOT touch native queue during playback
      if (!isPlaying && currentIndex < 0) {
        await updateSongsInQueue(songs);
      }
    }

    return addingList.length;
  }

  Future<bool> playNextSingleSong(SongsModel song) async {
    if (currentIndex < 0 || currentIndex >= songs.length) return false;

    // 🔹 If song already exists, fallback to reorder logic
    final existingIndex = songs.indexWhere((s) => s.id == song.id);
    if (existingIndex != -1) {
      await reorderSongInQueue(existingIndex, currentIndex + 1);
      return true;
    }

    print('⏭️ Play Next (single song)');

    // 🔹 Internal queue update
    final mutableSongs = List<SongsModel>.from(songs);

    final rawInsertIndex = currentIndex + 1;
    final insertIndex = rawInsertIndex.clamp(0, mutableSongs.length);

    mutableSongs.insert(insertIndex, song);

    songs = mutableSongs;
    _songsChangedController.add(songs);

    // ====================== ANDROID ======================
    if (Platform.isAndroid) {
      try {
        final player = _androidPlayer!;
        final source = player.audioSource;

        if (source is ConcatenatingAudioSource) {
          // 🔒 Preserve playback state
          final int? currentIndexBefore = player.currentIndex;
          final Duration currentPosition = player.position;
          final bool wasPlaying = player.playing;

          // 🔹 Insert ONE audio source
          await source.insert(insertIndex, _createAudioSource(song));

          // 🔁 Restore playback (CRITICAL)
          if (currentIndexBefore != null &&
              player.currentIndex == currentIndexBefore) {
            await player.seek(currentPosition, index: currentIndexBefore);
            if (wasPlaying) await player.play();
          }

          print('✅ Android: Single song inserted without restart');
        } else {
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        print('❌ Android Play Next (single) error: $e');
      }
    }
    // ======================== iOS ========================
    else if (Platform.isIOS) {
      // iOS: do NOT touch native queue during playback
      if (!isPlaying && currentIndex < 0) {
        await updateSongsInQueue(songs);
      }
    }

    return true;
  }

  // Helper: Rebuild playlist without seeking (for fallback only)
  Future<void> _rebuildPlaylistNoSeek(
    List<SongsModel> songsList,
    int currentIdx,
    bool wasPlaying,
  ) async {
    print('  Rebuilding Android playlist at index $currentIdx');

    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songsList.map(_createAudioSource).toList(),
    );

    // DON'T set initialPosition - let it continue from current position
    await _androidPlayer!.setAudioSource(
      playlist,
      initialIndex: currentIdx,
      preload: false,
    );

    _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

    if (wasPlaying) {
      _androidPlayer!.play();
    }
  }

  Future<void> updateSongsInQueueWithIndex(
    List<SongsModel> newSongsList,
    int preserveIndex,
  ) async {
    print('🎵 Updating queue with preserved index: $preserveIndex');
    print('  Old queue size: ${songs.length}');
    print('  New queue size: ${newSongsList.length}');

    // ✅ CRITICAL: Ensure we have a mutable copy
    final mutableList = List<SongsModel>.from(newSongsList);

    // Get current state
    final wasPlaying = isPlaying;
    final currentPos = position;

    // Validate preserve index
    final safePreserveIndex = preserveIndex.clamp(0, mutableList.length - 1);

    if (preserveIndex != safePreserveIndex) {
      print(
        '⚠️ Adjusted preserve index from $preserveIndex to $safePreserveIndex',
      );
    }

    print('  Preserving playback at index: $safePreserveIndex');
    print('  Current position: ${currentPos.inSeconds}s');
    print('  Was playing: $wasPlaying');

    // Update internal list
    songs = mutableList;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      try {
        print('📱 Android: Seamlessly updating queue without interruption');

        final source = _androidPlayer!.audioSource;

        if (source is ConcatenatingAudioSource) {
          // ✅ SMART UPDATE: Modify existing playlist without rebuilding
          final currentCount = source.children.length;
          final newCount = mutableList.length;

          print(
            '  Current playlist count: $currentCount, New count: $newCount',
          );

          // Calculate the difference
          if (currentCount > newCount) {
            // Remove excess items from the end (except the one we're preserving)
            for (int i = currentCount - 1; i >= newCount; i--) {
              if (i != safePreserveIndex) {
                print('  Removing index $i');
                await source.removeAt(i);
              }
            }
          } else if (newCount > currentCount) {
            // Add new items
            for (int i = currentCount; i < newCount; i++) {
              print('  Adding new song at index $i');
              await source.add(_createAudioSource(mutableList[i]));
            }
          }

          // ✅ CRITICAL: If the preserve index is different from current, we need to rebuild
          // because ConcatenatingAudioSource doesn't have a method to change current index
          if (_androidPlayer!.currentIndex != safePreserveIndex) {
            print(
              '  Index mismatch: ${_androidPlayer!.currentIndex} != $safePreserveIndex',
            );
            print('  Rebuilding playlist to correct index...');
            await _rebuildPlaylistNoSeek(
              mutableList,
              safePreserveIndex,
              wasPlaying,
            );
          } else {
            print(
              '✅ Android: Queue updated seamlessly (no playback interruption)',
            );
          }
        } else {
          print(
            '⚠️ Android: Source is not ConcatenatingAudioSource, rebuilding',
          );
          await _rebuildPlaylistNoSeek(
            mutableList,
            safePreserveIndex,
            wasPlaying,
          );
        }
      } catch (e) {
        print('❌ Android update error: $e, falling back');
        await _rebuildPlaylistNoSeek(
          mutableList,
          safePreserveIndex,
          wasPlaying,
        );
      }
    } else if (Platform.isIOS) {
      try {
        print('📀 iOS: Updating queue with preserved index');

        // For iOS, if currently playing, always rebuild to ensure correct index
        if (wasPlaying && currentIndex >= 0) {
          print('  Rebuilding playlist at preserved index');
          final filePaths = mutableList.map((song) => song.filePath).toList();

          await _iosPlayer!.setAudioSource(
            filePaths,
            initialIndex: safePreserveIndex,
            autoPlay: false, // Don't auto-play, let it continue
          );

          _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

          String iosLoopMode = 'off';
          if (_loopMode == LoopMode.one) {
            iosLoopMode = 'one';
          } else if (_loopMode == LoopMode.all) {
            iosLoopMode = 'all';
          }
          _iosPlayer!.setLoopMode(iosLoopMode);

          // Resume playing if it was playing
          if (wasPlaying) {
            await _iosPlayer!.play();
          }
        } else {
          print('  Not playing, updating quietly');
          final filePaths = mutableList.map((song) => song.filePath).toList();

          await _iosPlayer!.setAudioSource(
            filePaths,
            initialIndex: safePreserveIndex,
            autoPlay: false,
          );

          _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

          String iosLoopMode = 'off';
          if (_loopMode == LoopMode.one) {
            iosLoopMode = 'one';
          } else if (_loopMode == LoopMode.all) {
            iosLoopMode = 'all';
          }
          _iosPlayer!.setLoopMode(iosLoopMode);
        }

        print('✅ iOS: Queue updated successfully at index $safePreserveIndex');
      } catch (e) {
        print('❌ iOS update error: $e');
        rethrow;
      }
    }

    print('✅ Queue updated with preserved index (no interruption)');
  }

  /// Add to queue at the end

  Future<bool> addSingleSongToQueue(SongsModel song) async {
    // ❌ Skip if already in queue
    if (songs.any((s) => s.id == song.id)) {
      print('⚠️ Song already in queue, skipping');
      return false;
    }

    print('➕ Add to Queue (single song)');

    // 🔹 Update internal queue
    final mutableSongs = List<SongsModel>.from(songs);
    final insertIndex = mutableSongs.length;

    mutableSongs.add(song);

    songs = mutableSongs;
    _songsChangedController.add(songs);

    // ====================== ANDROID ======================
    if (Platform.isAndroid) {
      try {
        final source = _androidPlayer!.audioSource;

        if (source is ConcatenatingAudioSource) {
          await source.add(_createAudioSource(song));
          print('✅ Android: Song appended without restart');
        } else {
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        print('❌ Android Add to Queue error: $e');
      }
    }
    // ======================== iOS ========================
    else if (Platform.isIOS) {
      // iOS: never touch native queue during playback
      if (!isPlaying && currentIndex < 0) {
        await updateSongsInQueue(songs);
      }
    }

    return true;
  }

  Future<int> addMultipleSongsToQueue(List<SongsModel> songsToAdd) async {
    if (songsToAdd.isEmpty) return 0;

    print('➕ Add to Queue (multiple songs): ${songsToAdd.length}');

    // 🔹 Filter songs not already in queue
    final addingList = songsToAdd
        .where((song) => !songs.any((q) => q.id == song.id))
        .toList();

    if (addingList.isEmpty) return 0;

    // 🔹 Update internal queue
    final mutableSongs = List<SongsModel>.from(songs)..addAll(addingList);

    songs = mutableSongs;
    _songsChangedController.add(songs);

    // ====================== ANDROID ======================
    if (Platform.isAndroid) {
      try {
        final source = _androidPlayer!.audioSource;

        if (source is ConcatenatingAudioSource) {
          for (final song in addingList) {
            await source.add(_createAudioSource(song));
          }
          print('✅ Android: Multiple songs appended seamlessly');
        } else {
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        print('❌ Android Add to Queue (multi) error: $e');
      }
    }
    // ======================== iOS ========================
    else if (Platform.isIOS) {
      if (!isPlaying && currentIndex < 0) {
        await updateSongsInQueue(songs);
      }
    }

    return addingList.length;
  }

  /// Remove song from the playlist and queue

  Future<void> removeDeletedSongFromQueue(int songId) async {
    final removeIndex = songs.indexWhere((s) => s.id == songId);

    final mutableSongs = List<SongsModel>.from(songs);
    if (mutableSongs.length == 1) {
      final index = player.currentIndex ?? 0;

      await player.seek(player.position, index: index);
    }

    // Song not in queue → nothing to do
    if (removeIndex == -1) {
      print('ℹ️ Deleted song not found in queue');
      return;
    }

    await _removeSongFromQueueAtIndex(removeIndex);
  }

  Future<void> removeDeletedSongsFromQueue(Set<int> deletedSongIds) async {
    if (deletedSongIds.isEmpty) return;

    // Find all indexes to remove
    final indexesToRemove = <int>[];
    for (int i = 0; i < songs.length; i++) {
      if (deletedSongIds.contains(songs[i].id)) {
        indexesToRemove.add(i);
      }
    }

    if (indexesToRemove.isEmpty) {
      print('ℹ️ No deleted songs found in queue');
      return;
    }

    await _removeMultipleSongsFromQueueAtIndexes(indexesToRemove);
  }

  Future<void> _removeSongFromQueueAtIndex(int removeIndex) async {
    if (removeIndex < 0 || removeIndex >= songs.length) return;

    print('🗑 Removing deleted song from queue at index $removeIndex');

    final mutableSongs = List<SongsModel>.from(songs);
    mutableSongs.removeAt(removeIndex);

    // ✅ Update internal queue FIRST
    songs = mutableSongs;
    _songsChangedController.add(songs);

    // ====================== ANDROID ======================
    if (Platform.isAndroid) {
      try {
        final player = _androidPlayer!;
        final source = player.audioSource;

        if (source is ConcatenatingAudioSource) {
          final int? currentIndexBefore = player.currentIndex;
          final Duration currentPosition = player.position;
          final bool wasPlaying = player.playing;

          await source.removeAt(removeIndex);

          // 🧠 Removed song was BEFORE current
          if (currentIndexBefore != null && removeIndex < currentIndexBefore) {
            await player.seek(currentPosition, index: currentIndexBefore - 1);
          }
          // 🧠 Removed song IS the current song
          else if (currentIndexBefore == removeIndex) {
            if (mutableSongs.isNotEmpty) {
              final newIndex = removeIndex < mutableSongs.length
                  ? removeIndex
                  : mutableSongs.length - 1;

              await player.seek(Duration.zero, index: newIndex);
              if (wasPlaying) await player.play();
            }
          }

          print('✅ Android: Deleted song removed without restart');
        } else {
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        print('❌ Android remove error: $e');
        await updateSongsInQueue(songs);
      }
    }
    // ======================== iOS ========================
    else if (Platform.isIOS) {
      // iOS: Only rebuild if idle
      if (!isPlaying && currentIndex < 0) {
        await updateSongsInQueue(songs);
      }
    }
  }

  Future<void> _removeMultipleSongsFromQueueAtIndexes(
    List<int> removeIndexes,
  ) async {
    if (removeIndexes.isEmpty) return;

    print('🗑 Removing multiple songs from queue: $removeIndexes');

    // 🔥 CRITICAL: sort descending
    removeIndexes.sort((a, b) => b.compareTo(a));

    final player = _androidPlayer;
    final source = player?.audioSource;

    final int? currentIndexBefore = player?.currentIndex;
    final Duration currentPosition = player?.position ?? Duration.zero;
    final bool wasPlaying = player?.playing ?? false;

    // ===== Update internal queue FIRST =====
    final mutableSongs = List<SongsModel>.from(songs);
    for (final index in removeIndexes) {
      if (index >= 0 && index < mutableSongs.length) {
        mutableSongs.removeAt(index);
      }
    }

    songs = mutableSongs;
    _songsChangedController.add(songs);

    // ====================== ANDROID ======================
    if (Platform.isAndroid &&
        player != null &&
        source is ConcatenatingAudioSource) {
      try {
        // Remove from audio source (descending order)
        for (final index in removeIndexes) {
          if (index >= 0 && index < source.length) {
            await source.removeAt(index);
          }
        }

        if (currentIndexBefore != null) {
          // Count how many removed BEFORE current index
          final removedBefore = removeIndexes
              .where((i) => i < currentIndexBefore)
              .length;

          final isCurrentRemoved = removeIndexes.contains(currentIndexBefore);

          // 🧠 Case 1: current song still exists
          if (!isCurrentRemoved) {
            await player.seek(
              currentPosition,
              index: currentIndexBefore - removedBefore,
            );
          }
          // 🧠 Case 2: current song WAS deleted
          else if (mutableSongs.isNotEmpty) {
            final newIndex = (currentIndexBefore - removedBefore).clamp(
              0,
              mutableSongs.length - 1,
            );

            await player.seek(Duration.zero, index: newIndex);
            if (wasPlaying) await player.play();
          }
        }

        print('✅ Android: Multiple deleted songs removed seamlessly');
      } catch (e) {
        print('❌ Android multi-remove error: $e');
        await updateSongsInQueue(songs);
      }
    }
    // ======================== iOS ========================
    else if (Platform.isIOS) {
      if (!isPlaying && currentIndex < 0) {
        await updateSongsInQueue(songs);
      }
    }
  }
}
