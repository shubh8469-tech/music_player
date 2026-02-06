import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;

import 'package:just_audio/just_audio.dart';

import '../../core/db/app_database.dart';
import '../../features/songs/data/models/song_model.dart';
import '../ios_audio_player_service.dart';
import '../unified_equalizer_service.dart';
import 'playlist_builder.dart';
import 'reorder_state_manager.dart';

/// Singleton music player service handling playback across Android and iOS.
/// Delegates to platform-specific players and manages queue, shuffle, loop state.
class MusicPlayerService {
  static final MusicPlayerService _instance = MusicPlayerService._();
  factory MusicPlayerService() => _instance;

  // ---------------------------------------------------------------------------
  // Platform players & dependencies
  // ---------------------------------------------------------------------------

  AudioPlayer? _androidPlayer;
  IOSAudioPlayer? _iosPlayer;
  final UnifiedEqualizerService equalizerService = UnifiedEqualizerService();
  final ReorderStateManager _reorderManager = ReorderStateManager();

  // ---------------------------------------------------------------------------
  // Queue & playback state
  // ---------------------------------------------------------------------------

  List<SongsModel> songs = [];
  List<int> _shuffleIndices = [];
  int? _lastUpdatedSongId;
  bool _isChangingTrack = false;

  // ---------------------------------------------------------------------------
  // Loop, shuffle, speed
  // ---------------------------------------------------------------------------

  LoopMode _loopMode = LoopMode.off;
  bool _isShuffleEnabled = false;
  double _playbackSpeed = 1.0;

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  final StreamController<void> _libraryChangedController =
      StreamController<void>.broadcast();
  final StreamController<List<SongsModel>> _songsChangedController =
      StreamController<List<SongsModel>>.broadcast();
  final StreamController<LoopMode> _loopModeController =
      StreamController<LoopMode>.broadcast();
  final StreamController<bool> _shuffleController =
      StreamController<bool>.broadcast();

  Stream<void> get libraryChanged => _libraryChangedController.stream;
  Stream<List<SongsModel>> get songsChanged => _songsChangedController.stream;
  StreamController<List<SongsModel>> get songsChangedController =>
      _songsChangedController;
  Stream<LoopMode> get loopModeStream => _loopModeController.stream;
  Stream<bool> get shuffleStream => _shuffleController.stream;

  // ---------------------------------------------------------------------------
  // Public API - Player access & streams
  // ---------------------------------------------------------------------------

  dynamic get player {
    if (Platform.isAndroid) return _androidPlayer;
    if (Platform.isIOS) return _iosPlayer;
    return null;
  }

  Stream<Duration?> get durationStream {
    if (Platform.isAndroid && _androidPlayer != null) {
      return _androidPlayer!.durationStream;
    }
    if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer!.durationStream;
    }
    return Stream.value(null);
  }

  Stream<Duration> get positionStream {
    if (Platform.isAndroid && _androidPlayer != null) {
      return _androidPlayer!.positionStream;
    }
    if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer!.positionStream;
    }
    return Stream.value(Duration.zero);
  }

  Stream<PlayerState> get playerStateStream {
    if (Platform.isAndroid) {
      return _androidPlayer!.playerStateStream;
    }
    if (Platform.isIOS) {
      return _iosPlayer!.playingStream.map((isPlaying) => PlayerState(
            isPlaying,
            isPlaying ? ProcessingState.ready : ProcessingState.idle,
          ));
    }
    return Stream.value(PlayerState(false, ProcessingState.idle));
  }

  Duration? get duration {
    if (Platform.isAndroid && _androidPlayer != null) {
      return _androidPlayer?.duration;
    }
    if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer?.duration;
    }
    return null;
  }

  Duration get position {
    if (Platform.isAndroid) {
      return _androidPlayer?.position ?? Duration.zero;
    }
    if (Platform.isIOS) {
      return _iosPlayer?.position ?? Duration.zero;
    }
    return Duration.zero;
  }

  Stream<double> get playbackSpeedStream {
    if (Platform.isAndroid) {
      return _androidPlayer!.speedStream;
    }
    return Stream.value(_playbackSpeed);
  }

  double get playbackSpeed => _playbackSpeed;
  bool get isShuffleEnabled => _isShuffleEnabled;
  LoopMode get loopMode => _loopMode;

  int get currentIndex {
    if (Platform.isAndroid) return _androidPlayer?.currentIndex ?? -1;
    if (Platform.isIOS) return _iosPlayer?.currentIndex ?? -1;
    return -1;
  }

  Stream<int?> get currentIndexStream {
    if (Platform.isAndroid && _androidPlayer != null) {
      return _androidPlayer!.currentIndexStream;
    }
    if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer!.currentIndexStream;
    }
    return Stream.value(null);
  }

  int? get currentSongId => _reorderManager.getCurrentSongId(
        currentIndex: currentIndex,
        songs: songs,
      );

  Stream<int?> get currentSongIdStream => currentIndexStream.map((i) {
        final idx = i ?? -1;
        if (idx >= 0 && idx < songs.length) return songs[idx].id;
        return null;
      });

  bool get isPlaying {
    if (Platform.isAndroid && _androidPlayer != null) {
      return _androidPlayer?.playing ?? false;
    }
    if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer?.playing ?? false;
    }
    return false;
  }

  Stream<bool> get isPlayingStream {
    if (Platform.isAndroid && _androidPlayer != null) {
      return _androidPlayer!.playingStream;
    }
    if (Platform.isIOS && _iosPlayer != null) {
      return _iosPlayer!.playingStream;
    }
    return Stream.value(false);
  }

  // ---------------------------------------------------------------------------
  // Public API - Simple operations
  // ---------------------------------------------------------------------------

  void updateSongsList(List<SongsModel> newSongs) {
    songs = List<SongsModel>.from(newSongs);
    songsChangedController.add(List.from(songs));
    print('📝 Songs list updated: ${songs.length} songs');
  }

  Future<void> removeFromQueueAtIndex(int removeIndex, int newCurrentIndex) async {
    if (!Platform.isIOS) throw Exception('This method is only for iOS');
    try {
      print('📱 iOS: Removing song at index $removeIndex, new current: $newCurrentIndex');
      await _iosPlayer!.removeFromQueueAtIndex(removeIndex, newCurrentIndex);
      print('✅ iOS: Song removed seamlessly');
    } catch (e) {
      print('❌ iOS: Error removing song: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  MusicPlayerService._() {
    _initializePlayers();
  }

  Future<void> _initializePlayers() async {
    if (Platform.isAndroid) {
      _androidPlayer = equalizerService.createAndroidPlayerWithEqualizer();
      _androidPlayer!.setLoopMode(_loopMode);
      _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
      _setupAndroidListeners();
    } else if (Platform.isIOS) {
      _iosPlayer = await equalizerService.createIOSPlayer();
      _setupIOSListeners();
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
          if (_loopMode == LoopMode.off) {
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
      if (isPlaying) await _updateSongStats();
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
      if (isPlaying) await _updateSongStats();
    });

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

  void _generateShuffleIndices() {
    _shuffleIndices = List.generate(songs.length, (i) => i);
    _shuffleIndices.shuffle(Random());
    print('🔀 Shuffle indices generated: $_shuffleIndices');
  }

  // ---------------------------------------------------------------------------
  // Playlist management
  // ---------------------------------------------------------------------------

  Future<void> setPlaylist(
    List<SongsModel> songModels, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    if (songModels.isEmpty) {
      await stopAndClearQueue();
      return;
    }

    _reorderManager.clear();
    print('🎵 MusicPlayerService.setPlaylist - startIndex: $startIndex, songCount: ${songModels.length}');

    if (Platform.isAndroid) {
      await _setAndroidPlaylist(songModels, startIndex, autoPlay);
    } else if (Platform.isIOS) {
      await _setIOSPlaylist(songModels, startIndex, autoPlay);
    }
  }

  Future<void> _setAndroidPlaylist(
    List<SongsModel> songModels,
    int startIndex,
    bool autoPlay,
  ) async {
    final playlist = PlaylistBuilder.createPlaylist(songModels);
    try {
      await _androidPlayer!.setAudioSource(playlist, initialIndex: startIndex);
      await _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
      if (_isShuffleEnabled) await _androidPlayer!.shuffle();
      await _androidPlayer!.durationStream.firstWhere((d) => d != null);

      if (!equalizerService.isInitialized) {
        await _initializeAndroidEqualizer();
      }

      songs = songModels;
      _songsChangedController.add(songs);

      if (autoPlay) {
        await _androidPlayer!.play();
        print('▶️ Android: Playing from index $startIndex');
      }
    } catch (e) {
      print('❌ Android Playlist Error: $e');
      rethrow;
    }
  }

  Future<void> _setIOSPlaylist(
    List<SongsModel> songModels,
    int startIndex,
    bool autoPlay,
  ) async {
    final filePaths = songModels.map((song) => song.filePath).toList();
    try {
      await _iosPlayer!.setAudioSource(
        filePaths,
        initialIndex: startIndex,
        autoPlay: autoPlay,
      );

      final iosLoopMode = _loopMode == LoopMode.one
          ? 'one'
          : _loopMode == LoopMode.all
              ? 'all'
              : 'off';
      await _iosPlayer!.setLoopMode(iosLoopMode);
      await _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
      print('✅ iOS: Playlist set successfully');
    } catch (e) {
      print('❌ Error in _setIOSPlaylist: $e');
      rethrow;
    }
  }

  Future<void> setShufflePlaylist(
    List<SongsModel> songModels, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    _isShuffleEnabled = true;
    _generateShuffleIndices();
    final randomStartIndex = Random().nextInt(songModels.length);

    print('🔀 Shuffle Playlist - random start: $randomStartIndex');
    songs = songModels;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      await _setAndroidPlaylist(songModels, randomStartIndex, autoPlay);
      await _androidPlayer!.setShuffleModeEnabled(true);
      await _androidPlayer!.shuffle();
    } else if (Platform.isIOS) {
      await _iosPlayer!.setShuffleModeEnabled(true);
      await _setIOSPlaylist(songModels, randomStartIndex, autoPlay);
    }
  }

  Future<void> resetPlaylist(List<SongsModel> songModels) async {
    if (songModels.isEmpty) {
      await stopAndClearQueue();
    } else {
      await setPlaylist(songModels);
    }
  }

  // ---------------------------------------------------------------------------
  // Playback controls
  // ---------------------------------------------------------------------------

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
    if (Platform.isAndroid) await _androidPlayer!.pause();
    if (Platform.isIOS) await _iosPlayer!.pause();
  }

  Future<void> next() async {
    if (_isChangingTrack) return;
    _reorderManager.clear();
    _isChangingTrack = true;

    if (Platform.isAndroid) {
      final nextIndex = (currentIndex + 1) % songs.length;
      await _androidPlayer!.seek(Duration.zero, index: nextIndex);
    } else if (Platform.isIOS) {
      await _iosPlayer!.seekToNext();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      _isChangingTrack = false;
    });
  }

  Future<void> previous() async {
    if (_isChangingTrack) return;
    _reorderManager.clear();
    _isChangingTrack = true;

    if (Platform.isAndroid) {
      final prevIndex = currentIndex > 0 ? currentIndex - 1 : songs.length - 1;
      await _androidPlayer!.seek(Duration.zero, index: prevIndex);
      await _androidPlayer!.play();
    } else if (Platform.isIOS) {
      await _iosPlayer!.seekToPrevious();
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      _isChangingTrack = false;
    });
  }

  Future<void> stop() async {
    try {
      if (Platform.isAndroid) await _androidPlayer!.stop();
      if (Platform.isIOS) await _iosPlayer!.stop();
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

    songs = [];
    _shuffleIndices.clear();
    _lastUpdatedSongId = null;
    _reorderManager.clear();
    _isShuffleEnabled = false;
    _loopMode = LoopMode.off;
    _songsChangedController.add([]);
    print('✅ Queue cleared and playback stopped');
  }

  Future<void> seek(Duration position, {int? index}) async {
    if (Platform.isAndroid) await _androidPlayer!.seek(position, index: index);
    if (Platform.isIOS) await _iosPlayer!.seek(position, index: index);
  }

  // ---------------------------------------------------------------------------
  // Shuffle & loop
  // ---------------------------------------------------------------------------

  Future<void> toggleShuffle() async {
    _isShuffleEnabled = !_isShuffleEnabled;
    if (Platform.isAndroid) {
      await _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
      if (_isShuffleEnabled) await _androidPlayer!.shuffle();
    } else if (Platform.isIOS) {
      await _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
    }
    _shuffleController.add(_isShuffleEnabled);
  }

  Future<void> ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition() async {
    if (_isShuffleEnabled) return;
    _isShuffleEnabled = true;
    _generateShuffleIndices();
    if (Platform.isAndroid) {
      await _androidPlayer!.setShuffleModeEnabled(true);
      await _androidPlayer!.shuffle();
    } else if (Platform.isIOS) {
      await _iosPlayer!.setShuffleModeEnabled(true);
    }
  }

  Future<void> ensureShuffleOnAndReshuffle() async {
    if (_isShuffleEnabled) return;
    _isShuffleEnabled = true;
    if (Platform.isAndroid) {
      await _androidPlayer!.setShuffleModeEnabled(true);
      await _androidPlayer!.shuffle();
    } else if (Platform.isIOS) {
      await _iosPlayer!.setShuffleModeEnabled(true);
    }
  }

  Future<void> ensureShuffleOff() async {
    if (!_isShuffleEnabled) return;
    _isShuffleEnabled = false;
    if (Platform.isAndroid) {
      await _androidPlayer!.setShuffleModeEnabled(false);
    } else if (Platform.isIOS) {
      await _iosPlayer!.setShuffleModeEnabled(false);
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.5, 2.0);
    if (Platform.isAndroid) await _androidPlayer!.setSpeed(_playbackSpeed);
    if (Platform.isIOS) await _iosPlayer!.setSpeed(_playbackSpeed);
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
      final iosLoopMode = _loopMode == LoopMode.one
          ? 'one'
          : _loopMode == LoopMode.all
              ? 'all'
              : 'off';
      await _iosPlayer!.setLoopMode(iosLoopMode);
    }
    _loopModeController.add(_loopMode);
  }

  // ---------------------------------------------------------------------------
  // Queue updates & reorder
  // ---------------------------------------------------------------------------

  Future<void> updateSongsInQueue(List<SongsModel> newSongsList) async {
    final mutableSongsList = List<SongsModel>.from(newSongsList);
    final wasPlaying = isPlaying;
    final currentPlayingSongId = currentSongId;
    final currentPos = position;

    songs = mutableSongsList;
    _songsChangedController.add(songs);

    int newCurrentIndex = 0;
    if (currentPlayingSongId != null) {
      final foundIndex =
          mutableSongsList.indexWhere((s) => s.id == currentPlayingSongId);
      if (foundIndex >= 0) newCurrentIndex = foundIndex;
    }

    if (Platform.isAndroid) {
      try {
        final source = _androidPlayer!.audioSource;
        if (source is ConcatenatingAudioSource) {
          final currentCount = source.children.length;
          final newCount = mutableSongsList.length;
          bool needsIndexAdjustment = currentCount != newCount;

          if (currentCount > newCount) {
            for (int i = currentCount - 1; i >= newCount; i--) {
              await source.removeAt(i);
            }
          } else if (newCount > currentCount) {
            for (int i = currentCount; i < newCount; i++) {
              await source.add(PlaylistBuilder.createAudioSource(mutableSongsList[i]));
            }
          }

          if (needsIndexAdjustment && currentIndex != newCurrentIndex) {
            await _rebuildPlaylist(
              mutableSongsList,
              newCurrentIndex,
              currentPos,
              wasPlaying,
            );
          }
        } else {
          await _rebuildPlaylist(
            mutableSongsList,
            newCurrentIndex,
            currentPos,
            wasPlaying,
          );
        }
      } catch (e) {
        await _rebuildPlaylist(
          mutableSongsList,
          newCurrentIndex,
          currentPos,
          wasPlaying,
        );
      }
    } else if (Platform.isIOS) {
      await _rebuildIOSPlaylist(mutableSongsList, newCurrentIndex, wasPlaying);
    }
  }

  Future<void> _rebuildPlaylist(
    List<SongsModel> songsList,
    int newIndex,
    Duration currentPos,
    bool wasPlaying,
  ) async {
    final playlist = PlaylistBuilder.createPlaylist(songsList);
    await _androidPlayer!.setAudioSource(
      playlist,
      initialIndex: newIndex,
      initialPosition: currentPos,
      preload: false,
    );
    _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
    if (wasPlaying) _androidPlayer!.play();
  }

  Future<void> _rebuildIOSPlaylist(
    List<SongsModel> songsList,
    int startIndex,
    bool autoPlay,
  ) async {
    final filePaths = songsList.map((s) => s.filePath).toList();
    await _iosPlayer!.setAudioSource(
      filePaths,
      initialIndex: startIndex,
      autoPlay: autoPlay,
    );
    _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
    final iosLoopMode = _loopMode == LoopMode.one
        ? 'one'
        : _loopMode == LoopMode.all
            ? 'all'
            : 'off';
    _iosPlayer!.setLoopMode(iosLoopMode);
  }

  void prepareReorderForCurrentSong(int oldIndex, int newIndex) {
    _reorderManager.prepareReorderForCurrentSong(
      oldIndex,
      newIndex,
      currentIndex,
      songs,
    );
  }

  Future<void> swapReorderSongInQueue(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    _reorderManager.setReorderCache(oldIndex, newIndex, currentIndex, songs);
    final mutableSongs = List<SongsModel>.from(songs);
    final item = mutableSongs.removeAt(oldIndex);
    mutableSongs.insert(newIndex, item);

    if (Platform.isAndroid) {
      try {
        final source = _androidPlayer!.audioSource;
        if (source is ConcatenatingAudioSource) {
          // Emit new order immediately so UI doesn't snap back during await
          songs = mutableSongs;
          _reorderManager.markListUpdated();
          _songsChangedController.add(songs);
          await source.move(oldIndex, newIndex);
        } else {
          songs = mutableSongs;
          _reorderManager.markListUpdated();
          _songsChangedController.add(songs);
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        songs = mutableSongs;
        _reorderManager.markListUpdated();
        _songsChangedController.add(songs);
      }
    } else if (Platform.isIOS) {
      songs = mutableSongs;
      _reorderManager.markListUpdated();
      _songsChangedController.add(songs);
      if (!isPlaying && currentIndex < 0) {
        await updateSongsInQueue(songs);
      }
    }
  }

  Future<void> reorderSongInQueue(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final mutableSongs = List<SongsModel>.from(songs);
    final item = mutableSongs.removeAt(oldIndex);
    mutableSongs.insert(newIndex, item);
    songs = mutableSongs;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      try {
        final source = _androidPlayer!.audioSource;
        if (source is ConcatenatingAudioSource) {
          await source.move(oldIndex, newIndex);
        } else {
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        // Fallback handled by updateSongsInQueue if needed
      }
    } else if (Platform.isIOS) {
      if (!isPlaying && currentIndex < 0) {
        await updateSongsInQueue(songs);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Play next / add to queue
  // ---------------------------------------------------------------------------

  Future<int> playNextMultipleSongs(List<SongsModel> nextSongs) async {
    if (nextSongs.isEmpty) return 0;
    if (currentIndex < 0 || currentIndex >= songs.length) return 0;

    final addingList =
        nextSongs.where((s) => !songs.any((q) => q.id == s.id)).toList();
    if (addingList.isEmpty) return 0;

    final mutableSongs = List<SongsModel>.from(songs);
    final insertIndex = (currentIndex + 1).clamp(0, mutableSongs.length);
    mutableSongs.insertAll(insertIndex, addingList);
    songs = mutableSongs;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      try {
        final source = _androidPlayer!.audioSource;
        if (source is ConcatenatingAudioSource) {
          final idxBefore = _androidPlayer!.currentIndex;
          final posBefore = _androidPlayer!.position;
          final wasPlaying = _androidPlayer!.playing;
          int targetIndex = insertIndex;
          for (final song in addingList) {
            await source.insert(targetIndex, PlaylistBuilder.createAudioSource(song));
            targetIndex++;
          }
          if (idxBefore != null && _androidPlayer!.currentIndex == idxBefore) {
            await _androidPlayer!.seek(posBefore, index: idxBefore);
            if (wasPlaying) await _androidPlayer!.play();
          }
        } else {
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        developer.log('❌ Android Play Next error: $e');
      }
    } else if (Platform.isIOS && !isPlaying && currentIndex < 0) {
      await updateSongsInQueue(songs);
    }

    return addingList.length;
  }

  Future<bool> playNextSingleSong(SongsModel song) async {
    if (currentIndex < 0 || currentIndex >= songs.length) return false;

    final existingIndex = songs.indexWhere((s) => s.id == song.id);
    if (existingIndex != -1) {
      await reorderSongInQueue(existingIndex, currentIndex + 1);
      return true;
    }

    final mutableSongs = List<SongsModel>.from(songs);
    final insertIndex = (currentIndex + 1).clamp(0, mutableSongs.length);
    mutableSongs.insert(insertIndex, song);
    songs = mutableSongs;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      try {
        final source = _androidPlayer!.audioSource;
        if (source is ConcatenatingAudioSource) {
          final idxBefore = _androidPlayer!.currentIndex;
          final posBefore = _androidPlayer!.position;
          final wasPlaying = _androidPlayer!.playing;
          await source.insert(insertIndex, PlaylistBuilder.createAudioSource(song));
          if (idxBefore != null && _androidPlayer!.currentIndex == idxBefore) {
            await _androidPlayer!.seek(posBefore, index: idxBefore);
            if (wasPlaying) await _androidPlayer!.play();
          }
        } else {
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        print('❌ Android Play Next (single) error: $e');
      }
    } else if (Platform.isIOS && !isPlaying && currentIndex < 0) {
      await updateSongsInQueue(songs);
    }

    return true;
  }

  Future<void> updateSongsInQueueWithIndex(
    List<SongsModel> newSongsList,
    int preserveIndex,
  ) async {
    final mutableList = List<SongsModel>.from(newSongsList);
    final wasPlaying = isPlaying;
    final safePreserveIndex = preserveIndex.clamp(0, mutableList.length - 1);

    songs = mutableList;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      try {
        final source = _androidPlayer!.audioSource;
        if (source is ConcatenatingAudioSource) {
          final currentCount = source.children.length;
          final newCount = mutableList.length;
          if (currentCount > newCount) {
            for (int i = currentCount - 1; i >= newCount; i--) {
              if (i != safePreserveIndex) await source.removeAt(i);
            }
          } else if (newCount > currentCount) {
            for (int i = currentCount; i < newCount; i++) {
              await source.add(PlaylistBuilder.createAudioSource(mutableList[i]));
            }
          }
          if (_androidPlayer!.currentIndex != safePreserveIndex) {
            await _rebuildPlaylistNoSeek(
              mutableList,
              safePreserveIndex,
              wasPlaying,
            );
          }
        } else {
          await _rebuildPlaylistNoSeek(
            mutableList,
            safePreserveIndex,
            wasPlaying,
          );
        }
      } catch (e) {
        await _rebuildPlaylistNoSeek(
          mutableList,
          safePreserveIndex,
          wasPlaying,
        );
      }
    } else if (Platform.isIOS) {
      final filePaths = mutableList.map((s) => s.filePath).toList();
      await _iosPlayer!.setAudioSource(
        filePaths,
        initialIndex: safePreserveIndex,
        autoPlay: false,
      );
      _iosPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
      final iosLoopMode = _loopMode == LoopMode.one
          ? 'one'
          : _loopMode == LoopMode.all
              ? 'all'
              : 'off';
      _iosPlayer!.setLoopMode(iosLoopMode);
      if (wasPlaying) await _iosPlayer!.play();
    }
  }

  Future<void> _rebuildPlaylistNoSeek(
    List<SongsModel> songsList,
    int currentIdx,
    bool wasPlaying,
  ) async {
    final playlist = PlaylistBuilder.createPlaylist(songsList);
    await _androidPlayer!.setAudioSource(
      playlist,
      initialIndex: currentIdx,
      preload: false,
    );
    _androidPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
    if (wasPlaying) _androidPlayer!.play();
  }

  Future<bool> addSingleSongToQueue(SongsModel song) async {
    if (songs.any((s) => s.id == song.id)) return false;

    final mutableSongs = List<SongsModel>.from(songs);
    mutableSongs.add(song);
    songs = mutableSongs;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      try {
        final source = _androidPlayer!.audioSource;
        if (source is ConcatenatingAudioSource) {
          await source.add(PlaylistBuilder.createAudioSource(song));
        } else {
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        print('❌ Android Add to Queue error: $e');
      }
    } else if (Platform.isIOS && !isPlaying && currentIndex < 0) {
      await updateSongsInQueue(songs);
    }

    return true;
  }

  Future<int> addMultipleSongsToQueue(List<SongsModel> songsToAdd) async {
    if (songsToAdd.isEmpty) return 0;

    final addingList =
        songsToAdd.where((s) => !songs.any((q) => q.id == s.id)).toList();
    if (addingList.isEmpty) return 0;

    final mutableSongs = List<SongsModel>.from(songs)..addAll(addingList);
    songs = mutableSongs;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      try {
        final source = _androidPlayer!.audioSource;
        if (source is ConcatenatingAudioSource) {
          for (final song in addingList) {
            await source.add(PlaylistBuilder.createAudioSource(song));
          }
        } else {
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        print('❌ Android Add to Queue (multi) error: $e');
      }
    } else if (Platform.isIOS && !isPlaying && currentIndex < 0) {
      await updateSongsInQueue(songs);
    }

    return addingList.length;
  }

  // ---------------------------------------------------------------------------
  // Remove from queue
  // ---------------------------------------------------------------------------

  Future<void> removeDeletedSongFromQueue(int songId) async {
    final removeIndex = songs.indexWhere((s) => s.id == songId);
    if (removeIndex == -1) return;

    if (songs.length == 1) {
      final p = player;
      if (p != null) {
        final idx = p.currentIndex ?? 0;
        await p.seek(p.position, index: idx);
      }
    }
    await _removeSongFromQueueAtIndex(removeIndex);
  }

  Future<void> removeDeletedSongsFromQueue(Set<int> deletedSongIds) async {
    if (deletedSongIds.isEmpty) return;
    final indexesToRemove = <int>[];
    for (int i = 0; i < songs.length; i++) {
      if (deletedSongIds.contains(songs[i].id)) indexesToRemove.add(i);
    }
    if (indexesToRemove.isEmpty) return;
    await _removeMultipleSongsFromQueueAtIndexes(indexesToRemove);
  }

  Future<void> _removeSongFromQueueAtIndex(int removeIndex) async {
    if (removeIndex < 0 || removeIndex >= songs.length) return;

    final mutableSongs = List<SongsModel>.from(songs);
    mutableSongs.removeAt(removeIndex);
    songs = mutableSongs;
    _songsChangedController.add(songs);

    if (Platform.isAndroid) {
      try {
        final player = _androidPlayer!;
        final source = player.audioSource;
        if (source is ConcatenatingAudioSource) {
          final idxBefore = player.currentIndex;
          final posBefore = player.position;
          final wasPlaying = player.playing;
          await source.removeAt(removeIndex);
          if (idxBefore != null) {
            if (removeIndex < idxBefore) {
              await player.seek(posBefore, index: idxBefore - 1);
            } else if (idxBefore == removeIndex && mutableSongs.isNotEmpty) {
              final newIndex =
                  removeIndex < mutableSongs.length ? removeIndex : mutableSongs.length - 1;
              await player.seek(Duration.zero, index: newIndex);
              if (wasPlaying) await player.play();
            }
          }
        } else {
          await updateSongsInQueue(songs);
        }
      } catch (e) {
        await updateSongsInQueue(songs);
      }
    } else if (Platform.isIOS && !isPlaying && currentIndex < 0) {
      await updateSongsInQueue(songs);
    }
  }

  Future<void> _removeMultipleSongsFromQueueAtIndexes(
    List<int> removeIndexes,
  ) async {
    if (removeIndexes.isEmpty) return;

    removeIndexes.sort((a, b) => b.compareTo(a));
    final player = _androidPlayer;
    final source = player?.audioSource;
    final idxBefore = player?.currentIndex;
    final posBefore = player?.position ?? Duration.zero;
    final wasPlaying = player?.playing ?? false;

    final mutableSongs = List<SongsModel>.from(songs);
    for (final index in removeIndexes) {
      if (index >= 0 && index < mutableSongs.length) {
        mutableSongs.removeAt(index);
      }
    }
    songs = mutableSongs;
    _songsChangedController.add(songs);

    if (Platform.isAndroid &&
        player != null &&
        source is ConcatenatingAudioSource) {
      try {
        for (final index in removeIndexes) {
          if (index >= 0 && index < source.length) {
            await source.removeAt(index);
          }
        }
        if (idxBefore != null) {
          final removedBefore =
              removeIndexes.where((i) => i < idxBefore).length;
          final isCurrentRemoved = removeIndexes.contains(idxBefore);
          if (!isCurrentRemoved) {
            await player.seek(
              posBefore,
              index: idxBefore - removedBefore,
            );
          } else if (mutableSongs.isNotEmpty) {
            final newIndex =
                (idxBefore - removedBefore).clamp(0, mutableSongs.length - 1);
            await player.seek(Duration.zero, index: newIndex);
            if (wasPlaying) await player.play();
          }
        }
      } catch (e) {
        await updateSongsInQueue(songs);
      }
    } else if (Platform.isIOS && !isPlaying && currentIndex < 0) {
      await updateSongsInQueue(songs);
    }
  }
}
