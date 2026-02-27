import 'dart:async';
import 'dart:math';
import 'dart:developer' as developer;

import 'package:just_audio/just_audio.dart';

import 'package:music_app/core/db/app_database.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'unified_equalizer_service.dart';
import 'playlist_builder.dart';
import 'reorder_state_manager.dart';

class MusicPlayerService {
  static final MusicPlayerService _instance = MusicPlayerService._();
  factory MusicPlayerService() => _instance;

  // ---------------------------------------------------------------------------
  // Platform players & dependencies
  // ---------------------------------------------------------------------------

  AudioPlayer? _audioPlayer;
  final UnifiedEqualizerService equalizerService = UnifiedEqualizerService();
  final ReorderStateManager _reorderManager = ReorderStateManager();

  // ---------------------------------------------------------------------------
  // Queue & playback state
  // ---------------------------------------------------------------------------

  List<SongsModel> songs = [];
  List<int> _shuffleIndices = [];
  List<SongsModel>? _originalOrderBeforeShuffle;
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

  dynamic get player => _audioPlayer;

  Stream<Duration?> get durationStream {
    if (_audioPlayer != null) return _audioPlayer!.durationStream;
    return Stream.value(null);
  }

  Stream<Duration> get positionStream {
    if (_audioPlayer != null) return _audioPlayer!.positionStream;
    return Stream.value(Duration.zero);
  }

  Stream<PlayerState> get playerStateStream => _audioPlayer!.playerStateStream;

  Duration? get duration {
    if (_audioPlayer != null) return _audioPlayer?.duration;
    return null;
  }

  Duration get position => _audioPlayer?.position ?? Duration.zero;

  Stream<double> get playbackSpeedStream => _audioPlayer!.speedStream;

  double get playbackSpeed => _playbackSpeed;
  bool get isShuffleEnabled => _isShuffleEnabled;
  LoopMode get loopMode => _loopMode;

  int get currentIndex => _audioPlayer?.currentIndex ?? -1;

  Stream<int?> get currentIndexStream {
    if (_audioPlayer != null) return _audioPlayer!.currentIndexStream;
    return Stream.value(null);
  }

  int? get currentSongId => _reorderManager.getCurrentSongId(
    currentIndex: currentIndex,
    songs: songs,
  );

  SongsModel? get currentSong {
    final idx = currentIndex;
    if (idx >= 0 && idx < songs.length) return songs[idx];
    return null;
  }

  Stream<int?> get currentSongIdStream => currentIndexStream.map((i) {
    final idx = i ?? -1;
    if (idx >= 0 && idx < songs.length) return songs[idx].id;
    return null;
  });

  bool get isPlaying => _audioPlayer?.playing ?? false;

  Stream<bool> get isPlayingStream =>
      _audioPlayer != null ? _audioPlayer!.playingStream : Stream.value(false);

  // ---------------------------------------------------------------------------
  // Public API - Simple operations
  // ---------------------------------------------------------------------------

  void updateSongsList(List<SongsModel> newSongs) {
    songs = List<SongsModel>.from(newSongs);
    songsChangedController.add(List.from(songs));
    print('📝 Songs list updated: ${songs.length} songs');
  }

  /// Syncs the current playlist with updated song data (e.g. from SongsBloc after
  /// artwork or metadata change). Replaces matching songs by id so the UI updates.
  void syncCurrentPlaylistWithUpdatedSongs(List<SongsModel> updatedSongs) {
    if (songs.isEmpty || updatedSongs.isEmpty) return;
    final byId = {for (var s in updatedSongs) s.id: s};
    bool changed = false;
    final newList = <SongsModel>[];
    for (final s in songs) {
      if (s.id != null && byId.containsKey(s.id)) {
        newList.add(byId[s.id]!);
        changed = true;
      } else {
        newList.add(s);
      }
    }
    if (changed) {
      songs = newList;
      _songsChangedController.add(List.from(songs));
    }
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  MusicPlayerService._() {
    _initializePlayers();
  }

  Future<void> _initializePlayers() async {
    _audioPlayer = equalizerService.createAndroidPlayerWithEqualizer();
    _audioPlayer!.setLoopMode(_loopMode);
    _audioPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
    _setupAndroidListeners();
  }

  Future<void> _initializeAndroidEqualizer() async {
    try {
      await equalizerService.initialize(_audioPlayer!);
      print('Android Equalizer initialized successfully');
    } catch (e) {
      print('Error initializing Android equalizer: $e');
    }
  }

  void _setupAndroidListeners() {
    _audioPlayer!.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        if (currentIndex >= (songs.length - 1)) {
          if (_loopMode == LoopMode.off) {
            _audioPlayer!.stop();
          } else {
            await _audioPlayer!.seek(Duration.zero);
            await _audioPlayer!.play();
          }
        } else {
          await _audioPlayer!.seekToNext();
          await _audioPlayer!.play();
        }
      }
    });

    _audioPlayer!.playingStream.listen((isPlaying) async {
      if (isPlaying) await _updateSongStats();
    });

    _audioPlayer!.currentIndexStream.listen((i) async {
      final idx = i ?? -1;
      if (!_audioPlayer!.playing) return;
      if (idx < 0 || idx >= songs.length) return;
      await _updateSongStats();
    });

    _audioPlayer!.speedStream.listen((speed) {
      _playbackSpeed = speed;
    });
  }

  // void _setupIOSListeners() {
  //   _iosPlayer!.playingStream.listen((isPlaying) async {
  //     if (isPlaying) await _updateSongStats();
  //   });
  //
  //   _iosPlayer!.currentIndexStream.listen((i) async {
  //     final idx = i ?? -1;
  //     if (!_iosPlayer!.playing) return;
  //     if (idx < 0 || idx >= songs.length) return;
  //     await _updateSongStats();
  //   });
  // }

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

    // Drop songs whose files no longer exist (e.g. after backup restore) to avoid crashes.
    final filtered = await PlaylistBuilder.filterSongsWithExistingFiles(
      songModels,
      startIndex: startIndex,
    );
    songModels = filtered.list;
    startIndex = filtered.startIndex;

    if (songModels.isEmpty) {
      await stopAndClearQueue();
      return;
    }

    // Clamp startIndex to valid range to avoid RangeError in the platform player.
    if (startIndex < 0 || startIndex >= songModels.length) {
      startIndex = 0;
    }

    _reorderManager.clear();
    _originalOrderBeforeShuffle = null;
    print(
      '🎵 MusicPlayerService.setPlaylist - startIndex: $startIndex, songCount: ${songModels.length}',
    );
    await _setAndroidPlaylist(songModels, startIndex, autoPlay);
  }

  Future<void> _setAndroidPlaylist(
      List<SongsModel> songModels,
      int startIndex,
      bool autoPlay, {
        bool playlistOrderIsFinal = false,
        Duration? initialPosition,
      }) async {
    final playlist = PlaylistBuilder.createPlaylist(songModels);
    try {
      developer.log(
        'playlist ----> ${playlist.children.length}',
        name: 'MusicPlayerService._setAndroidPlaylist',
      );
      await _audioPlayer!.setAudioSource(
        playlist,
        initialIndex: startIndex,
        initialPosition: initialPosition,
      );
      if (!playlistOrderIsFinal) {
        await _audioPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
        if (_isShuffleEnabled) await _audioPlayer!.shuffle();
      } else {
        await _audioPlayer!.setShuffleModeEnabled(false);
      }
      await _audioPlayer!.durationStream.firstWhere((d) => d != null);

      if (!equalizerService.isInitialized) {
        await _initializeAndroidEqualizer();
      }

      songs = songModels;
      _songsChangedController.add(songs);

      if (autoPlay) {
        await _audioPlayer!.play();
        print('▶️ Android: Playing from index $startIndex');
      }
    } catch (e, st) {
      // "Loading interrupted" means the current load was cancelled, usually
      // because another load was started (e.g. user tapped a different song)
      // or the player was disposed. This is expected behaviour in just_audio
      // and should be treated as a benign cancellation.
      if (e.toString().contains('Loading interrupted')) {
        developer.log(
          'Android playlist load was interrupted by a new request; ignoring.',
          name: 'MusicPlayerService._setAndroidPlaylist',
          error: e,
          stackTrace: st,
        );
        // Do NOT reset or dispose the player here; another setAudioSource()
        // call is typically in progress and resetting would break the new
        // player instance and any UI listeners (miniplayer streams, etc).
        return;
      }

      // For any other error, still bubble up so it can be handled upstream.
      rethrow;
    }
  }

  Future<void> setShufflePlaylist(
      List<SongsModel> songModels, {
        int startIndex = 0,
        bool autoPlay = true,
      }) async {
    if (songModels.isEmpty) return;
    final filtered = await PlaylistBuilder.filterSongsWithExistingFiles(
      songModels,
      startIndex: 0,
    );
    songModels = filtered.list;
    if (songModels.isEmpty) return;

    _isShuffleEnabled = true;
    _generateShuffleIndices();
    final randomStartIndex = Random().nextInt(songModels.length);

    print('🔀 Shuffle Playlist - random start: $randomStartIndex');
    songs = songModels;
    _songsChangedController.add(songs);

    await _setAndroidPlaylist(songModels, randomStartIndex, autoPlay);
    await _audioPlayer!.setShuffleModeEnabled(true);
    await _audioPlayer!.shuffle();
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
    if (_audioPlayer!.processingState == ProcessingState.completed) {
      await _audioPlayer!.seek(Duration.zero);
    }
    await _audioPlayer!.play();
  }

  Future<void> pause() async {
    _audioPlayer!.pause();
  }

  Future<void> next() async {
    if (_isChangingTrack) return;
    _reorderManager.clear();
    _isChangingTrack = true;

    final nextIndex = (currentIndex + 1) % songs.length;
    await _audioPlayer!.seek(Duration.zero, index: nextIndex);

    Future.delayed(const Duration(milliseconds: 500), () {
      _isChangingTrack = false;
    });
  }

  Future<void> previous() async {
    if (_isChangingTrack) return;
    _reorderManager.clear();
    _isChangingTrack = true;

    final prevIndex = currentIndex > 0 ? currentIndex - 1 : songs.length - 1;
    await _audioPlayer!.seek(Duration.zero, index: prevIndex);
    await _audioPlayer!.play();

    Future.delayed(const Duration(milliseconds: 500), () {
      _isChangingTrack = false;
    });
  }

  Future<void> stop() async {
    try {
      await _audioPlayer!.stop();
    } catch (e) {
      print('❌ Stop error: $e');
    }
  }

  Future<void> stopAndClearQueue() async {
    try {
      await _audioPlayer!.stop();
      await _audioPlayer!.seek(Duration.zero);
    } catch (_) {}

    songs = [];
    _shuffleIndices.clear();
    _originalOrderBeforeShuffle = null;
    _lastUpdatedSongId = null;
    _reorderManager.clear();
    _isShuffleEnabled = false;
    _loopMode = LoopMode.off;
    _songsChangedController.add([]);
    print('✅ Queue cleared and playback stopped');
  }

  Future<void> seek(Duration position, {int? index}) async {
    await _audioPlayer!.seek(position, index: index);
  }

  // ---------------------------------------------------------------------------
  // Shuffle & loop
  // ---------------------------------------------------------------------------

  Future<void> toggleShuffle() async {
    if (songs.isEmpty) return;

    _isShuffleEnabled = !_isShuffleEnabled;

    if (_isShuffleEnabled) {
      _originalOrderBeforeShuffle ??= List<SongsModel>.from(songs);
      final currIdx = currentIndex.clamp(0, songs.length - 1);
      final currentSong = songs[currIdx];
      final rest = List<SongsModel>.from(songs)..removeAt(currIdx);
      rest.shuffle(Random());
      final targetOrder = [currentSong, ...rest];
      _reorderManager.setReorderCache(currIdx, 0, currIdx, songs);
      await _applyOrderUsingMoves(targetOrder);
      developer.log(
        '🔀 Android shuffle enabled (current at top, no rebuild)',
      );
    } else {
      if (_originalOrderBeforeShuffle != null) {
        final original = List<SongsModel>.from(_originalOrderBeforeShuffle!);
        _originalOrderBeforeShuffle = null;
        // Shuffle OFF: always use rebuild (one platform call). Move loop is
        // O(n) and slow even for ~10 songs.
        await _applyOrderUsingRebuild(original);
        developer.log('🔀 Android shuffle disabled, restored original order');
      }
    }
    _shuffleController.add(_isShuffleEnabled);
  }

  static const int _shuffleMoveThreshold = 50;

  /// Reorders the queue. For small playlists uses move() (no glitch). For large
  /// playlists uses rebuild (fast; O(1) vs O(n) platform calls).
  Future<void> _applyOrderUsingMoves(List<SongsModel> targetOrder) async {
    if (targetOrder.length > _shuffleMoveThreshold) {
      await _applyOrderUsingRebuild(targetOrder);
      return;
    }
    await _applyOrderUsingMovesInternal(targetOrder);
  }

  Future<void> _applyOrderUsingRebuild(List<SongsModel> targetOrder) async {
    final currSongId = currentSongId;
    int newIndex = 0;
    if (currSongId != null) {
      final idx = targetOrder.indexWhere((s) => s.id == currSongId);
      if (idx >= 0) newIndex = idx;
    }
    songs = List<SongsModel>.from(targetOrder);
    _songsChangedController.add(songs);
    await _rebuildPlaylist(targetOrder, newIndex, position, isPlaying);
    developer.log(
      '🔀 Large playlist (${targetOrder.length}): used rebuild for speed',
    );
  }

  /// Reorders using ConcatenatingAudioSource.move (like swapReorderSongInQueue).
  /// Keeps playback and progress uninterrupted. Use for small playlists only.
  Future<void> _applyOrderUsingMovesInternal(
      List<SongsModel> targetOrder,
      ) async {
    if (targetOrder.length != songs.length) {
      songs = List<SongsModel>.from(targetOrder);
      _songsChangedController.add(songs);
      await updateSongsInQueue(songs);
      return;
    }

    final source = _audioPlayer?.audioSource;
    if (source is! ConcatenatingAudioSource) {
      songs = List<SongsModel>.from(targetOrder);
      _songsChangedController.add(songs);
      await updateSongsInQueue(songs);
      return;
    }

    var currentOrder = List<SongsModel>.from(songs);

    for (int i = 0; i < targetOrder.length; i++) {
      if (currentOrder[i].id == targetOrder[i].id) continue;
      final from = currentOrder.indexWhere((s) => s.id == targetOrder[i].id);
      if (from == -1 || from == i) continue;
      final item = currentOrder.removeAt(from);
      currentOrder.insert(i, item);
      await source.move(from, i);
    }

    songs = currentOrder;
    _reorderManager.markListUpdated();
    _songsChangedController.add(songs);
  }

  Future<void> ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition() async {
    if (_isShuffleEnabled) return;
    _isShuffleEnabled = true;
    _generateShuffleIndices();
    await _audioPlayer!.setShuffleModeEnabled(true);
    await _audioPlayer!.shuffle();
  }

  Future<void> ensureShuffleOnAndReshuffle() async {
    if (_isShuffleEnabled) return;
    _isShuffleEnabled = true;
    await _audioPlayer!.setShuffleModeEnabled(true);
    await _audioPlayer!.shuffle();
  }

  Future<void> ensureShuffleOff() async {
    if (!_isShuffleEnabled) return;
    _isShuffleEnabled = false;
    await _audioPlayer!.setShuffleModeEnabled(false);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.5, 2.0);
    await _audioPlayer!.setSpeed(_playbackSpeed);
  }

  Future<void> toggleRepeat() async {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }

    await _audioPlayer!.setLoopMode(_loopMode);
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
      final foundIndex = mutableSongsList.indexWhere(
            (s) => s.id == currentPlayingSongId,
      );
      if (foundIndex >= 0) newCurrentIndex = foundIndex;
    }

    try {
      final source = _audioPlayer!.audioSource;
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
            await source.add(
              PlaylistBuilder.createAudioSource(mutableSongsList[i]),
            );
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
  }

  Future<void> _rebuildPlaylist(
      List<SongsModel> songsList,
      int newIndex,
      Duration currentPos,
      bool wasPlaying,
      ) async {
    final playlist = PlaylistBuilder.createPlaylist(songsList);
    await _audioPlayer!.setAudioSource(
      playlist,
      initialIndex: newIndex,
      initialPosition: currentPos,
      preload: false,
    );
    _audioPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
    if (wasPlaying) _audioPlayer!.play();
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

    try {
      final source = _audioPlayer!.audioSource;
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
  }

  Future<void> reorderSongInQueue(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final mutableSongs = List<SongsModel>.from(songs);
    final item = mutableSongs.removeAt(oldIndex);
    mutableSongs.insert(newIndex, item);
    songs = mutableSongs;
    _songsChangedController.add(songs);

    try {
      final source = _audioPlayer!.audioSource;
      if (source is ConcatenatingAudioSource) {
        await source.move(oldIndex, newIndex);
      } else {
        await updateSongsInQueue(songs);
      }
    } catch (e) {
      // Fallback handled by updateSongsInQueue if needed
    }
  }

  // ---------------------------------------------------------------------------
  // Play next / add to queue
  // ---------------------------------------------------------------------------

  Future<int> playNextMultipleSongs(List<SongsModel> nextSongs) async {
    if (nextSongs.isEmpty) return 0;
    if (currentIndex < 0 || currentIndex >= songs.length) return 0;

    final addingList = nextSongs
        .where((s) => !songs.any((q) => q.id == s.id))
        .toList();
    if (addingList.isEmpty) return 0;

    final mutableSongs = List<SongsModel>.from(songs);
    final insertIndex = (currentIndex + 1).clamp(0, mutableSongs.length);
    mutableSongs.insertAll(insertIndex, addingList);
    songs = mutableSongs;
    _songsChangedController.add(songs);

    try {
      final source = _audioPlayer!.audioSource;
      if (source is ConcatenatingAudioSource) {
        final idxBefore = _audioPlayer!.currentIndex;
        final posBefore = _audioPlayer!.position;
        final wasPlaying = _audioPlayer!.playing;
        int targetIndex = insertIndex;
        for (final song in addingList) {
          await source.insert(
            targetIndex,
            PlaylistBuilder.createAudioSource(song),
          );
          targetIndex++;
        }
        if (idxBefore != null && _audioPlayer!.currentIndex == idxBefore) {
          await _audioPlayer!.seek(posBefore, index: idxBefore);
          if (wasPlaying) await _audioPlayer!.play();
        }
      } else {
        await updateSongsInQueue(songs);
      }
    } catch (e) {
      developer.log('❌ Android Play Next error: $e');
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

    try {
      final source = _audioPlayer!.audioSource;
      if (source is ConcatenatingAudioSource) {
        final idxBefore = _audioPlayer!.currentIndex;
        final posBefore = _audioPlayer!.position;
        final wasPlaying = _audioPlayer!.playing;
        await source.insert(
          insertIndex,
          PlaylistBuilder.createAudioSource(song),
        );
        if (idxBefore != null && _audioPlayer!.currentIndex == idxBefore) {
          await _audioPlayer!.seek(posBefore, index: idxBefore);
          if (wasPlaying) await _audioPlayer!.play();
        }
      } else {
        await updateSongsInQueue(songs);
      }
    } catch (e) {
      print('❌ Android Play Next (single) error: $e');
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

    try {
      final source = _audioPlayer!.audioSource;
      if (source is ConcatenatingAudioSource) {
        final currentCount = source.children.length;
        final newCount = mutableList.length;
        if (currentCount > newCount) {
          for (int i = currentCount - 1; i >= newCount; i--) {
            if (i != safePreserveIndex) await source.removeAt(i);
          }
        } else if (newCount > currentCount) {
          for (int i = currentCount; i < newCount; i++) {
            await source.add(
              PlaylistBuilder.createAudioSource(mutableList[i]),
            );
          }
        }
        if (_audioPlayer!.currentIndex != safePreserveIndex) {
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
  }

  Future<void> _rebuildPlaylistNoSeek(
      List<SongsModel> songsList,
      int currentIdx,
      bool wasPlaying,
      ) async {
    final playlist = PlaylistBuilder.createPlaylist(songsList);
    await _audioPlayer!.setAudioSource(
      playlist,
      initialIndex: currentIdx,
      preload: false,
    );
    _audioPlayer!.setShuffleModeEnabled(_isShuffleEnabled);
    if (wasPlaying) _audioPlayer!.play();
  }

  Future<bool> addSingleSongToQueue(SongsModel song) async {
    if (songs.any((s) => s.id == song.id)) return false;

    final mutableSongs = List<SongsModel>.from(songs);
    mutableSongs.add(song);
    songs = mutableSongs;
    _songsChangedController.add(songs);

    try {
      final source = _audioPlayer!.audioSource;
      if (source is ConcatenatingAudioSource) {
        await source.add(PlaylistBuilder.createAudioSource(song));
      } else {
        await updateSongsInQueue(songs);
      }
    } catch (e) {
      print('❌ Android Add to Queue error: $e');
    }

    return true;
  }

  Future<int> addMultipleSongsToQueue(List<SongsModel> songsToAdd) async {
    if (songsToAdd.isEmpty) return 0;

    final addingList = songsToAdd
        .where((s) => !songs.any((q) => q.id == s.id))
        .toList();
    if (addingList.isEmpty) return 0;

    final mutableSongs = List<SongsModel>.from(songs)..addAll(addingList);
    songs = mutableSongs;
    _songsChangedController.add(songs);

    try {
      final source = _audioPlayer!.audioSource;
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

    try {
      final player = _audioPlayer!;
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
            final newIndex = removeIndex < mutableSongs.length
                ? removeIndex
                : mutableSongs.length - 1;
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
  }

  Future<void> _removeMultipleSongsFromQueueAtIndexes(
      List<int> removeIndexes,
      ) async {
    if (removeIndexes.isEmpty) return;

    removeIndexes.sort((a, b) => b.compareTo(a));
    final player = _audioPlayer;
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

    if (player != null && source is ConcatenatingAudioSource) {
      try {
        for (final index in removeIndexes) {
          if (index >= 0 && index < source.length) {
            await source.removeAt(index);
          }
        }
        if (idxBefore != null) {
          final removedBefore = removeIndexes
              .where((i) => i < idxBefore)
              .length;
          final isCurrentRemoved = removeIndexes.contains(idxBefore);
          if (!isCurrentRemoved) {
            await player.seek(posBefore, index: idxBefore - removedBefore);
          } else if (mutableSongs.isNotEmpty) {
            final newIndex = (idxBefore - removedBefore).clamp(
              0,
              mutableSongs.length - 1,
            );
            await player.seek(Duration.zero, index: newIndex);
            if (wasPlaying) await player.play();
          }
        }
      } catch (e) {
        await updateSongsInQueue(songs);
      }
    }
  }
}
