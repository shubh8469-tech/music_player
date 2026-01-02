import 'dart:async';
import 'dart:io';
import 'dart:math';
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
  final StreamController<void> _libraryChangedController = StreamController<void>.broadcast();

  Stream<void> get libraryChanged => _libraryChangedController.stream;

  // Emits events when the songs list changes
  final StreamController<List<SongsModel>> _songsChangedController = StreamController<List<SongsModel>>.broadcast();

  Stream<List<SongsModel>> get songsChanged => _songsChangedController.stream;

  int? _lastUpdatedSongId;

  // Loop and Shuffle state variables
  LoopMode _loopMode = LoopMode.off;
  bool _isShuffleEnabled = false;
  double _playbackSpeed = 1.0;

  double get playbackSpeed => _playbackSpeed;

  // ============================================
  // Public getters for backward compatibility
  // ============================================

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
        return PlayerState(isPlaying, isPlaying ? ProcessingState.ready : ProcessingState.idle);
      });
    }
    return Stream.value(PlayerState(false, ProcessingState.idle));
  }

  /// Current duration - works on both platforms
  Duration? get duration {
    if (Platform.isAndroid && _androidPlayer != null) {
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
            [current.id]
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

  Future<void> setPlaylist(List<SongsModel> songModels, {int startIndex = 0, bool autoPlay = true}) async {
    if (songModels.isEmpty) return;

    print('🎵 MusicPlayerService.setPlaylist called - startIndex: $startIndex, songCount: ${songModels.length}');

    songs = songModels;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      print('📱 Android: Setting playlist...');
      await _setAndroidPlaylist(songModels, startIndex, autoPlay);
    } else if (Platform.isIOS) {
      print('🍎 iOS: Setting playlist...');
      await _setIOSPlaylist(songModels, startIndex, autoPlay);
    }
  }

  Future<void> _setAndroidPlaylist(List<SongsModel> songModels, int startIndex, bool autoPlay) async {
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

    try{
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
      }else {
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

      // ✅ Only play if autoPlay is true
      // If autoPlay is false and music is already playing, it will continue playing the old song
      // This allows playlist updates without interruption
      if (autoPlay) {
        await _androidPlayer!.play();
        print('▶️ Android: Playing from index $startIndex');
      } else {
        // ✅ If already playing, don't pause - just update the queue
        if (isPlaying) {
          print('⏸️ Android: autoPlay is false and music already playing - continuing current playback');
        } else {
          print('⏸️ Android: autoPlay is false - playlist ready but not playing');
        }
      }
    }catch(e){
      print('❌ Android Playlist Error: $e');
      rethrow;
    }



    print('✅ Android: Playlist set successfully');
  }

  Future<void> _setIOSPlaylist(List<SongsModel> songModels, int startIndex, bool autoPlay) async {
    final filePaths = songModels.map((song) => song.filePath).toList();

    print('📀 iOS: Setting playlist with ${filePaths.length} songs');
    print('  Starting at index: $startIndex, autoPlay: $autoPlay, shuffle: $_isShuffleEnabled');

    try {
      // ✅ CRITICAL FIX: Pass autoPlay=true to native and WAIT for completion
      print('📍 Step 1: Setting audio source and waiting...');
      await _iosPlayer!.setAudioSource(
        filePaths,
        initialIndex: startIndex,
        autoPlay: autoPlay, // Pass autoPlay directly
      );
      print('✅ Step 1: Audio source set and playback started (if autoPlay=true)');

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

  Future<void> setShufflePlaylist(List<SongsModel> songModels, {int startIndex = 0, bool autoPlay = true}) async {
    // Same as setPlaylist but ensures shuffle is on
    _isShuffleEnabled = true;
    _generateShuffleIndices();

    // Get a random starting index from shuffle indices
    // final randomStartIndex = _shuffleIndices[0];
    final randomStartIndex = Random().nextInt(songModels.length);

    print('🔀 Shuffle Playlist - Starting from random index: $randomStartIndex (shuffle order: $_shuffleIndices)');
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
    songs = songModels;
    _songsChangedController.add(songs);
    await stop();
  }

  Future<void> play() async {
    if (Platform.isAndroid) {
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

    _isChangingTrack = true;

    if (Platform.isAndroid) {
      final nextIndex = (currentIndex + 1) % songs.length;
      await _androidPlayer!.seek(Duration.zero, index: nextIndex);
      await _androidPlayer!.play();
    } else if (Platform.isIOS) {
      print('🎵 MusicPlayerService.next() called - current index: $currentIndex, total songs: ${songs.length}');
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

  Future<void> previous() async {
    if (_isChangingTrack) {
      print('⚠️ Track change already in progress, ignoring previous() call');
      return;
    }

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
    }else{
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


  }

  /// Re-schedule the current track to apply new loop mode immediately
  Future<void> _scheduleLoopModeUpdate() async {
    // For both Android and iOS, the loop mode is already set via setLoopMode()
    // The native players will apply it on the next completion event
    // No need to seek or reschedule - just let it continue playing
    print('✅ Loop mode updated - will apply on next track completion');
  }

  Future<void> updateSongsInQueue(List<SongsModel> newSongsList) async {
    print('🎵 Updating songs queue (seamless update)');
    print('  Old queue size: ${songs.length}');
    print('  New queue size: ${newSongsList.length}');
    print('  Current playing index: $currentIndex');

    // Update the songs list
    songs = newSongsList;

    // Notify listeners that songs changed
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      try {
        // Use ConcatenatingAudioSource's add/insert/remove methods for seamless updates
        final currentSource = _androidPlayer!.audioSource as ConcatenatingAudioSource?;

        if (currentSource == null) {
          print('⚠️ No audio source found, doing full rebuild');
          await _rebuildAndroidPlaylist(newSongsList);
          return;
        }

        // Get current state
        final wasPlaying = isPlaying;
        final currentIdx = currentIndex;
        final currentPos = position;

        // Calculate differences and update queue
        final oldLength = currentSource.children.length;
        final newLength = newSongsList.length;

        // Simple approach: rebuild playlist but preserve current playback
        await _rebuildAndroidPlaylist(newSongsList, preservePlayback: true);

        print('✅ Android queue updated seamlessly - Index: $currentIdx, Playing: $wasPlaying');
      } catch (e) {
        print('❌ Error updating Android queue: $e');
        rethrow;
      }
    } else if (Platform.isIOS) {
      try {
        // For iOS, we need to rebuild the playlist but preserve current playback
        final filePaths = newSongsList.map((song) => song.filePath).toList();
        final wasPlaying = isPlaying;
        final currentIdx = currentIndex;
        final currentPos = position;

        print('📀 iOS: Rebuilding playlist while preserving playback');
        print('  Current: idx=$currentIdx, pos=${currentPos.inSeconds}s, playing=$wasPlaying');

        // Stop playback temporarily
        if (wasPlaying) {
          await _iosPlayer!.pause();
        }

        // Update the audio source with current index
        await _iosPlayer!.setAudioSource(
          filePaths,
          initialIndex: currentIdx >= 0 ? currentIdx : 0,
          autoPlay: false,
        );

        // Restore shuffle state
        await _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

        // Seek back to the exact position in the current song
        if (currentPos > Duration.zero) {
          await _iosPlayer!.seek(currentPos, index: currentIdx);
        }

        // Resume playback if it was playing
        if (wasPlaying) {
          await _iosPlayer!.play();
        }

        print('✅ iOS queue updated - resumed at ${currentPos.inSeconds}s');
      } catch (e) {
        print('❌ Error updating iOS queue: $e');
        rethrow;
      }
    }

    print('✅ Queue updated successfully');
  }

  Future<void> _rebuildAndroidPlaylist(List<SongsModel> songsList, {bool preservePlayback = false}) async {
    final wasPlaying = isPlaying;
    final currentIdx = currentIndex;
    final currentPos = position;

    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songsList.map((song) {
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

    if (preservePlayback && currentIdx >= 0) {
      // Preserve current playback position
      await _androidPlayer!.setAudioSource(
        playlist,
        initialIndex: currentIdx,
        initialPosition: currentPos,
      );

      // Restore shuffle state
      await _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

      // Resume if was playing
      if (wasPlaying) {
        await _androidPlayer!.play();
      }
    } else {
      // Normal playlist set
      await _androidPlayer!.setAudioSource(playlist, initialIndex: 0);
      await _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
    }
  }
}

/*class MusicPlayerService {
  static final MusicPlayerService _instance = MusicPlayerService._internal();

  factory MusicPlayerService() => _instance;

  // Platform-specific players
  AudioPlayer? _androidPlayer;
  IOSAudioPlayer? _iosPlayer;

  List<SongsModel> songs = [];

  // Equalizer
  final UnifiedEqualizerService equalizerService = UnifiedEqualizerService();

  // Emits events when library-affecting stats change
  final StreamController<void> _libraryChangedController = StreamController<void>.broadcast();

  Stream<void> get libraryChanged => _libraryChangedController.stream;

  // Emits events when the songs list changes
  final StreamController<List<SongsModel>> _songsChangedController = StreamController<List<SongsModel>>.broadcast();

  Stream<List<SongsModel>> get songsChanged => _songsChangedController.stream;

  int? _lastUpdatedSongId;

  // Loop and Shuffle state variables
  LoopMode _loopMode = LoopMode.off;
  bool _isShuffleEnabled = false;
  double _playbackSpeed = 1.0;

  double get playbackSpeed => _playbackSpeed;

  // ============================================
  // NEW: Public getters for backward compatibility
  // ============================================

  /// Access to the underlying player (platform-agnostic)
  /// Use this for streams and player state
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
        return PlayerState(isPlaying, isPlaying ? ProcessingState.ready : ProcessingState.idle);
      });
    }
    return Stream.value(PlayerState(false, ProcessingState.idle));
  }

  /// Current duration - works on both platforms
  Duration? get duration {
    if (Platform.isAndroid && _androidPlayer != null) {
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

  *//*Future<void> _initializePlayers() async {
    if (Platform.isAndroid) {
      // Create Android player with equalizer
      _androidPlayer = equalizerService.createAndroidPlayerWithEqualizer();
      _androidPlayer!.setLoopMode(LoopMode.all);
      _androidPlayer!.setLoopMode(_loopMode);
      _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

      // Initialize equalizer
      await _initializeAndroidEqualizer();

      // Setup Android listeners
      _setupAndroidListeners();

    } else if (Platform.isIOS) {
      // Create iOS player
      _iosPlayer = await equalizerService.createIOSPlayer();

      // Initialize equalizer
      await _initializeIOSEqualizer();

      // Setup iOS listeners
      _setupIOSListeners();
    }
  }*//*

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

    // _iosPlayer!.currentIndexStream.listen((i) async {
    //   final idx = i ?? -1;
    //   if (!_iosPlayer!.playing) return;
    //   if (idx < 0 || idx >= songs.length) return;
    //   await _updateSongStats();
    // });

    _iosPlayer!.currentIndexStream.listen((i) async {
      final idx = i ?? -1;
      print(' iOS Current Index changed: $idx');

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
        await db.rawUpdate("UPDATE songs SET play_count = play_count + 1, last_played = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW') WHERE id = ?", [current.id]);
        _libraryChangedController.add(null);
        _lastUpdatedSongId = current.id;
      } catch (_) {}
    }
  }

  Future<void> setPlaylist(List<SongsModel> songModels, {int startIndex = 0, bool autoPlay = true}) async {
    if (songModels.isEmpty) return;
    print('🎵 MusicPlayerService.setPlaylist called - startIndex: $startIndex, songCount: ${songModels.length}');
    print('🎵 Stack trace:');
    songs = songModels;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      await _setAndroidPlaylist(songModels, startIndex, autoPlay);
    } else if (Platform.isIOS) {
      await _setIOSPlaylist(songModels, startIndex, autoPlay);
    }
  }

  Future<void> _setAndroidPlaylist(List<SongsModel> songModels, int startIndex, bool autoPlay) async {
    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songModels.map((song) {
        Uri? artUri;
        try {
          if (song.artwork_path != null && song.artwork_path!.isNotEmpty) {
            artUri = Uri.file(song.artwork_path!);
          }
        } catch (e) {
          // log("Error loading artUri: ${e.toString()}");
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

    await _androidPlayer!.setAudioSource(playlist, initialIndex: startIndex);
    await _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

    if (_isShuffleEnabled) {
      await _androidPlayer!.shuffle();
    }

    // IMPORTANT: Wait for duration to load
    await _androidPlayer!.durationStream.firstWhere((d) => d != null);

    // ✅ NOW initialize equalizer after audio is loaded
    if (!equalizerService.isInitialized) {
      // log('Initializing Initializing equalizer after audio load...');
      await _initializeAndroidEqualizer();
    }

    if (autoPlay) {
      await _androidPlayer!.play();
    }
  }

  *//*  Future<void> _setAndroidPlaylist(
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
          print("Error loading artUri: ${e.toString()}");
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

    await _androidPlayer!.setAudioSource(playlist, initialIndex: startIndex);
    await _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);

    if (_isShuffleEnabled) {
      await _androidPlayer!.shuffle();
    }

    await _androidPlayer!.durationStream.firstWhere((d) => d != null);

    if (autoPlay) {
      await _androidPlayer!.play();
    }
  }*//*

  Future<void> _setIOSPlaylist(List<SongsModel> songModels, int startIndex, bool autoPlay) async {
    final filePaths = songModels.map((song) => song.filePath).toList();
    print('📀 Setting iOS playlist:');

    for (int i = 0; i < songModels.length; i++) {
      print('  [$i] ${songModels[i].title}');
    }
    print('  Starting at index: $startIndex, autoPlay: $autoPlay');

    await _iosPlayer!.setAudioSource(filePaths, initialIndex: startIndex, autoPlay: autoPlay);

    // Set loop mode
    String iosLoopMode = 'off';
    if (_loopMode == LoopMode.one) {
      iosLoopMode = 'one';
    } else if (_loopMode == LoopMode.all) {
      iosLoopMode = 'all';
    }
    await _iosPlayer!.setLoopMode(iosLoopMode);

    // Set shuffle
    await _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
  }

  Future<void> setShufflePlaylist(List<SongsModel> songModels, {int startIndex = 0, bool autoPlay = true}) async {
    // Same as setPlaylist but ensures shuffle is on
    _isShuffleEnabled = true;
    await setPlaylist(songModels, startIndex: startIndex, autoPlay: autoPlay);
  }

  Future<void> resetPlaylist(List<SongsModel> songModels) async {
    songs = songModels;
    _songsChangedController.add(songs);
    await stop();
  }

  Future<void> play() async {
    if (Platform.isAndroid) {
      if (_androidPlayer!.processingState == ProcessingState.completed) {
        await _androidPlayer!.seek(Duration.zero);
      }
      await _androidPlayer!.play();
    } else if (Platform.isIOS) {
      await _iosPlayer!.play();
    }
  }

  Future<void> pause() async {
    if (Platform.isAndroid) {
      await _androidPlayer!.pause();
    } else if (Platform.isIOS) {
      await _iosPlayer!.pause();
    }
  }

  Future<void> next() async {
    if (Platform.isAndroid) {
      final nextIndex = (currentIndex + 1) % songs.length;
      await _androidPlayer!.seek(Duration.zero, index: nextIndex);
      await _androidPlayer!.play();
    } else if (Platform.isIOS) {
      print('🎵 MusicPlayerService.next() called - current index: $currentIndex, total songs: ${songs.length}');
      // Just call native seekToNext - index will be updated via stream
      await _iosPlayer!.seekToNext();
    }
  }

  Future<void> stop() async {
    if (Platform.isAndroid) {
      await _androidPlayer!.stop();
    } else if (Platform.isIOS) {
      await _iosPlayer!.stop();
    }
  }

  Future<void> previous() async {
    if (Platform.isAndroid) {
      final prevIndex = currentIndex > 0 ? currentIndex - 1 : songs.length - 1;
      await _androidPlayer!.seek(Duration.zero, index: prevIndex);
      await _androidPlayer!.play();
    } else if (Platform.isIOS) {
      // Just call native seekToPrevious - index will be updated via stream
      await _iosPlayer!.seekToPrevious();
    }
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
        final total = songs.length;
        if (total > 0) {
          final randomIndex = (DateTime.now().millisecondsSinceEpoch % total);
          await _androidPlayer!.seek(Duration.zero, index: randomIndex);
        }
      }
    } else if (Platform.isIOS) {
      await _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
    }
  }

  Future<void> ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition() async {
    if (!_isShuffleEnabled) {
      _isShuffleEnabled = true;

      if (Platform.isAndroid) {
        await _androidPlayer!.setShuffleModeEnabled(true);
        await _androidPlayer!.shuffle();
        final total = songs.length;
        if (total > 0) {
          final randomIndex = Random().nextInt(total);
          await _androidPlayer!.seek(Duration.zero, index: randomIndex);
          await _androidPlayer!.currentIndexStream.firstWhere((idx) => idx == randomIndex);
        }
      } else if (Platform.isIOS) {
        await _iosPlayer!.setShuffleModeEnabled(true);
      }
    }
  }

  Future<void> ensureShuffleOnAndReshuffle() async {
    if (!_isShuffleEnabled) {
      _isShuffleEnabled = true;

      if (Platform.isAndroid) {
        await _androidPlayer!.setShuffleModeEnabled(true);
        await _androidPlayer!.shuffle();
        final total = songs.length;
        if (total > 0 && _androidPlayer!.currentIndex == null) {
          final randomIndex = (DateTime.now().millisecondsSinceEpoch % total);
          await _androidPlayer!.seek(Duration.zero, index: randomIndex);
        }
      } else if (Platform.isIOS) {
        await _iosPlayer!.setShuffleModeEnabled(true);
      }
    }
  }

  Future<void> ensureShuffleOff() async {
    if (_isShuffleEnabled) {
      _isShuffleEnabled = false;

      if (Platform.isAndroid) {
        await _androidPlayer!.setShuffleModeEnabled(false);
      } else if (Platform.isIOS) {
        await _iosPlayer!.setShuffleModeEnabled(false);
      }
    }
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
    } else if (Platform.isIOS) {
      String iosLoopMode = 'off';
      if (_loopMode == LoopMode.one) {
        iosLoopMode = 'one';
      } else if (_loopMode == LoopMode.all) {
        iosLoopMode = 'all';
      }
      await _iosPlayer!.setLoopMode(iosLoopMode);
    }
  }
}*/

/*
class MusicPlayerService {
  static final MusicPlayerService _instance = MusicPlayerService._internal();

  factory MusicPlayerService() => _instance;
  late AudioPlayer player;
  List<SongsModel> songs = [];

  // Emits events when library-affecting stats change (e.g., play_count/last_played)
  final StreamController<void> _libraryChangedController = StreamController<void>.broadcast();

  Stream<void> get libraryChanged => _libraryChangedController.stream;

  // Emits events when the songs list changes (e.g., when songs are added/removed/reordered)
  final StreamController<List<SongsModel>> _songsChangedController = StreamController<List<SongsModel>>.broadcast();

  Stream<List<SongsModel>> get songsChanged => _songsChangedController.stream;
  int? _lastUpdatedSongId;

  // Loop and Shuffle state variables
  LoopMode _loopMode = LoopMode.off;
  bool _isShuffleEnabled = false;

  double _playbackSpeed = 1.0;

  double get playbackSpeed => _playbackSpeed;

  Stream<double> get playbackSpeedStream => player.speedStream;

  bool get isShuffleEnabled => _isShuffleEnabled;

  LoopMode get loopMode => _loopMode;

  // expose current index
  int get currentIndex => player.currentIndex ?? -1;

  Stream<int?> get currentIndexStream => player.currentIndexStream;

  int? get currentSongId {
    final idx = currentIndex;
    if (idx >= 0 && idx < songs.length) return songs[idx].id;
    return null;
  }

  Stream<int?> get currentSongIdStream => player.currentIndexStream.map((i) {
    final idx = i ?? -1;
    if (idx >= 0 && idx < songs.length) return songs[idx].id;
    return null;
  });

  // expose play state
  bool get isPlaying => player.playing;

  Stream<bool> get isPlayingStream => player.playingStream;

  MusicPlayerService._internal() {
    player = AudioPlayer();
    player.setLoopMode(LoopMode.all);

    // Initialize player with default loop mode and shuffle disabled
    player.setLoopMode(_loopMode);
    player.setShuffleModeEnabled(_isShuffleEnabled);

    player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        // If last song finishes → reset instead of full stop
        if (currentIndex >= (songs.length - 1)) {
          if (_loopMode == LoopMode.off && currentIndex >= (songs.length - 1)) {
            player.stop();
          } else {
            await player.seek(Duration.zero);
            await player.play();
          }
          log('we are here ----- still $currentIndex ${songs.length}');
        } else {
          log('we are here ----- $currentIndex ${songs.length}');
          await player.seekToNext();
          await player.play();
        }
      }
    });

    // When playback starts for a song, update stats in DB
    player.playingStream.listen((isPlaying) async {
      if (isPlaying) {
        final idx = currentIndex;
        if (idx >= 0 && idx < songs.length) {
          final current = songs[idx];
          if (_lastUpdatedSongId == current.id) return;
          try {
            final db = await AppDatabase.instance();
            await db.rawUpdate("UPDATE songs SET play_count = play_count + 1, last_played = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW') WHERE id = ?", [current.id]);
            // Notify listeners (e.g., playlist counts for system playlists)
            _libraryChangedController.add(null);
            _lastUpdatedSongId = current.id;
          } catch (_) {}
        }
      }
    });

    player.currentIndexStream.listen((i) async {
      final idx = i ?? -1;
      if (!player.playing) return;
      if (idx < 0 || idx >= songs.length) return;
      final current = songs[idx];
      if (_lastUpdatedSongId == current.id) return;
      try {
        final db = await AppDatabase.instance();
        await db.rawUpdate("UPDATE songs SET play_count = play_count + 1, last_played = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW') WHERE id = ?", [current.id]);
        _libraryChangedController.add(null);
        _lastUpdatedSongId = current.id;
      } catch (_) {}
    });

    player.speedStream.listen((speed) {
      _playbackSpeed = speed;
    });
  }

  Future<void> setPlaylist(List<SongsModel> songModels, {int startIndex = 0, bool autoPlay = true}) async {
    if (songModels.isEmpty) return;
    songs = songModels;

    // Notify listeners that the songs list has changed
    _songsChangedController.add(songs);

    log('hereeee kl');
    // final playlist = ConcatenatingAudioSource(
    //   useLazyPreparation: true,
    //   children: songModels
    //       .map(
    //         (song) => AudioSource.uri(
    //           Uri.file(song.filePath),
    //           tag: MediaItem(
    //             // Optional: metadata for mini player / lock screen
    //             id: song.id?.toString() ?? '',
    //             title: song.title,
    //             artist: song.artist,
    //             album: song.album,
    //             duration: Duration(milliseconds: song.duration),
    //             artUri: song.artwork_path != null
    //                 ? Uri.file(song.artwork_path!)
    //                 : null,
    //           ),
    //         ),
    //       )
    //       .toList(),
    // );
    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songModels.map((song) {
        Uri? artUri;
        try {
          if (song.artwork_path != null && song.artwork_path!.isNotEmpty) {
            // Prevent invalid URIs
            artUri = Uri.file(song.artwork_path!);
          }
        } catch (e) {
          log("Error loading artUri: ${e.toString()}");
        }

        return AudioSource.uri(
          Uri.file(song.filePath),
          tag: MediaItem(
            id: song.id?.toString() ?? '',
            title: song.title,
            artist: song.artist,
            album: song.album,
            duration: Duration(milliseconds: song.duration),
            artUri: artUri, // ✅ only if valid
          ),
        );
      }).toList(),
    );
    await player.setAudioSource(playlist, initialIndex: startIndex);
    // Ensure shuffle mode stays applied on new source
    await player.setShuffleModeEnabled(_isShuffleEnabled);
    if (_isShuffleEnabled) {
      await player.shuffle();
    }

    // Wait for duration to be loaded before starting play
    await player.durationStream.firstWhere((d) => d != null);

    if (autoPlay) {
      await player.play();
    }
  }

  Future<void> resetPlaylist(List<SongsModel> songModels) async {
    songs = songModels;
    _songsChangedController.add(songs);
    player.stop();
  }

  Future<void> setShufflePlaylist(List<SongsModel> songModels, {int startIndex = 0, bool autoPlay = true}) async {
    if (songModels.isEmpty) return;
    songs = songModels;

    // Notify listeners that the songs list has changed
    _songsChangedController.add(songs);

    // final playlist = ConcatenatingAudioSource(
    //   useLazyPreparation: true,
    //   children: songModels
    //       .map(
    //         (song) => AudioSource.uri(
    //           Uri.file(song.filePath),
    //           tag: MediaItem(
    //             // Optional: metadata for mini player / lock screen
    //             id: song.id?.toString() ?? '',
    //             title: song.title,
    //             artist: song.artist,
    //             album: song.album,
    //             duration: Duration(milliseconds: song.duration),
    //             artUri: song.artwork_path != null
    //                 ? Uri.file(song.artwork_path!)
    //                 : null,
    //           ),
    //         ),
    //       )
    //       .toList(),
    // );
    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songModels.map((song) {
        Uri? artUri;
        try {
          if (song.artwork_path != null && song.artwork_path!.isNotEmpty) {
            // Prevent invalid URIs
            artUri = Uri.file(song.artwork_path!);
          }
        } catch (e) {
          log("Error loading artUri: ${e.toString()}");
        }

        return AudioSource.uri(
          Uri.file(song.filePath),
          tag: MediaItem(
            id: song.id?.toString() ?? '',
            title: song.title,
            artist: song.artist,
            album: song.album,
            duration: Duration(milliseconds: song.duration),
            artUri: artUri, // ✅ only if valid
          ),
        );
      }).toList(),
    );
    await player.setAudioSource(playlist, initialIndex: startIndex);
    // Ensure shuffle mode stays applied on new source
    await player.setShuffleModeEnabled(_isShuffleEnabled);
    if (_isShuffleEnabled) {
      await player.shuffle();
    }

    // Wait for duration to be loaded before starting play
    await player.durationStream.firstWhere((d) => d != null);

    if (autoPlay) {
      await player.play();
    }
  }

  Future<void> play() async {
    // if already at end, reset before play
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    await player.play();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> next() async {
    log('checks---> $currentIndex ${songs.length}');
    // Manually calculate next index to bypass LoopMode.one restriction
    final nextIndex = (currentIndex + 1) % songs.length;
    await player.seek(Duration.zero, index: nextIndex);
    await player.play();
  }

  Future<void> stop() => player.stop();

  Future<void> previous() async {
    // Manually calculate previous index to bypass LoopMode.one restriction
    final prevIndex = currentIndex > 0 ? currentIndex - 1 : songs.length - 1;
    await player.seek(Duration.zero, index: prevIndex);
    await player.play();
  }

  // Toggle Shuffle mode
  Future<void> toggleShuffle() async {
    _isShuffleEnabled = !_isShuffleEnabled;
    await player.setShuffleModeEnabled(_isShuffleEnabled);

    // If enabling shuffle, immediately shuffle the playlist order
    if (_isShuffleEnabled) {
      // shuffle indices and jump to a random index to start randomized playback
      await player.shuffle();
      final total = songs.length;
      if (total > 0) {
        final randomIndex = (DateTime.now().millisecondsSinceEpoch % total);
        await player.seek(Duration.zero, index: randomIndex);
      }
    }
  }

  Future<void> ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition() async {
    if (!_isShuffleEnabled) {
      _isShuffleEnabled = true;
      await player.setShuffleModeEnabled(true);
      log('Shuffle mode enabled');
    }

    await player.shuffle(); // shuffle with the default internal RNG
    log('Playlist shuffled');
    final total = songs.length;
    if (total > 0) {
      // Use a new Random to pick a random start index every time
      final randomIndex = Random().nextInt(total);
      log('Seeking to random index $randomIndex');
      await player.seek(Duration.zero, index: randomIndex);

      await player.currentIndexStream.firstWhere((idx) => idx == randomIndex);
      log('Seek to random index complete');
    }
  }

  Future<void> ensureShuffleOnAndReshuffle() async {
    if (!_isShuffleEnabled) {
      _isShuffleEnabled = true;
      await player.setShuffleModeEnabled(true);
      log('Shuffle mode enabled');
    }

    await player.shuffle();
    final total = songs.length;
    if (total > 0 && player.currentIndex == null) {
      final randomIndex = (DateTime.now().millisecondsSinceEpoch % total);
      await player.seek(Duration.zero, index: randomIndex);
    }
  }

  Future<void> ensureShuffleOff() async {
    if (_isShuffleEnabled) {
      _isShuffleEnabled = false;
      await player.setShuffleModeEnabled(false);
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final clampedSpeed = speed.clamp(0.5, 2.0);
    _playbackSpeed = clampedSpeed;
    await player.setSpeed(clampedSpeed);
  }

  // Cycle Loop mode Off → All → One → Off
  Future<void> toggleRepeat() async {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }
    await player.setLoopMode(_loopMode);
  }
}
*/
