import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:music_app/features/songs/domain/entities/song.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/features/music_player/domain/entities/playback_loop_mode.dart';
import 'package:music_app/features/music_player/domain/entities/playback_state.dart';
import 'package:music_app/features/music_player/domain/repositories/playback_repository.dart';
import 'package:music_app/features/music_player/data/services/music_player_service.dart';

/// Converts domain [PlaybackLoopMode] to just_audio [LoopMode].
// ignore: unused_element - used when implementing setLoopMode with direct platform API
LoopMode _toLoopMode(PlaybackLoopMode mode) {
  switch (mode) {
    case PlaybackLoopMode.off:
      return LoopMode.off;
    case PlaybackLoopMode.one:
      return LoopMode.one;
    case PlaybackLoopMode.all:
      return LoopMode.all;
  }
}

/// Converts just_audio [LoopMode] to domain [PlaybackLoopMode].
PlaybackLoopMode _fromLoopMode(LoopMode mode) {
  switch (mode) {
    case LoopMode.off:
      return PlaybackLoopMode.off;
    case LoopMode.one:
      return PlaybackLoopMode.one;
    case LoopMode.all:
      return PlaybackLoopMode.all;
  }
}

/// Converts [SongsModel] list to domain [Song] list.
List<Song> _songsToDomain(List<SongsModel> list) =>
    list.map((m) => m.toDomain()).toList();

/// Converts domain [Song] list to [SongsModel] list.
List<SongsModel> _songsToModel(List<Song> list) =>
    list.map((s) => SongsModel.fromDomain(s)).toList();

/// Data-layer implementation of [PlaybackRepository]. Wraps [MusicPlayerService]
/// and maps domain types at the boundary.
class PlaybackRepositoryImpl implements PlaybackRepository {
  PlaybackRepositoryImpl(this._service);

  final MusicPlayerService _service;

  Future<PlaybackState> _buildState() async {
    return PlaybackState(
      songs: _songsToDomain(_service.songs),
      currentIndex: _service.currentIndex >= 0 ? _service.currentIndex : null,
      currentSongId: _service.currentSongId,
      isPlaying: _service.isPlaying,
      position: _service.position,
      duration: _service.duration,
      loopMode: _fromLoopMode(_service.loopMode),
      shuffleEnabled: _service.isShuffleEnabled,
    );
  }

  @override
  Stream<PlaybackState> get playbackStateStream {
    final c = StreamController<PlaybackState>.broadcast();
    void onEvent(void _) {
      _buildState().then((s) {
        if (!c.isClosed) c.add(s);
      });
    }

    _buildState().then((s) {
      if (!c.isClosed) c.add(s);
    });

    final subs = <StreamSubscription<dynamic>>[
      _service.songsChanged.listen(onEvent),
      _service.currentIndexStream.listen(onEvent),
      _service.isPlayingStream.listen(onEvent),
      _service.positionStream.listen(onEvent),
      _service.durationStream.listen(onEvent),
      _service.loopModeStream.listen(onEvent),
      _service.shuffleStream.listen(onEvent),
      _service.libraryChanged.listen(onEvent),
    ];

    c.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };

    return c.stream;
  }

  @override
  Stream<void> get libraryChangedStream => _service.libraryChanged;

  @override
  Future<void> setPlaylist(
    List<Song> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  }) =>
      _service.setPlaylist(_songsToModel(songs), startIndex: startIndex, autoPlay: autoPlay);

  @override
  Future<void> setShufflePlaylist(
    List<Song> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  }) =>
      _service.setShufflePlaylist(_songsToModel(songs), startIndex: startIndex, autoPlay: autoPlay);

  @override
  Future<void> resetPlaylist(List<Song> songs) =>
      _service.resetPlaylist(_songsToModel(songs));

  @override
  Future<void> play() => _service.play();

  @override
  Future<void> pause() => _service.pause();

  @override
  Future<void> next() => _service.next();

  @override
  Future<void> previous() => _service.previous();

  @override
  Future<void> stop() => _service.stop();

  @override
  Future<void> stopAndClearQueue() => _service.stopAndClearQueue();

  @override
  Future<void> seek(Duration position, {int? index}) =>
      _service.seek(position, index: index);

  @override
  Future<void> toggleShuffle() => _service.toggleShuffle();

  @override
  Future<void> setLoopMode(PlaybackLoopMode mode) async {
    final current = _service.loopMode;
    if (_fromLoopMode(current) == mode) return;
    while (_fromLoopMode(_service.loopMode) != mode) {
      await _service.toggleRepeat();
    }
  }

  @override
  Future<void> setPlaybackSpeed(double speed) => _service.setPlaybackSpeed(speed);

  @override
  void syncPlaylistWithUpdatedSongs(List<Song> updatedSongs) {
    _service.syncCurrentPlaylistWithUpdatedSongs(_songsToModel(updatedSongs));
  }

  @override
  Future<int> playNextMultipleSongs(List<Song> nextSongs) =>
      _service.playNextMultipleSongs(_songsToModel(nextSongs));

  @override
  Future<bool> playNextSingleSong(Song song) =>
      _service.playNextSingleSong(SongsModel.fromDomain(song));

  @override
  Future<void> updateSongsInQueue(List<Song> newSongsList) =>
      _service.updateSongsInQueue(_songsToModel(newSongsList));

  @override
  Future<void> updateSongsInQueueWithIndex(List<Song> newSongsList, int preserveIndex) =>
      _service.updateSongsInQueueWithIndex(_songsToModel(newSongsList), preserveIndex);

  @override
  void prepareReorderForCurrentSong(int oldIndex, int newIndex) =>
      _service.prepareReorderForCurrentSong(oldIndex, newIndex);

  @override
  Future<void> swapReorderSongInQueue(int oldIndex, int newIndex) =>
      _service.swapReorderSongInQueue(oldIndex, newIndex);

  @override
  Future<void> reorderSongInQueue(int oldIndex, int newIndex) =>
      _service.reorderSongInQueue(oldIndex, newIndex);

  @override
  Future<bool> addSingleSongToQueue(Song song) =>
      _service.addSingleSongToQueue(SongsModel.fromDomain(song));

  @override
  Future<int> addMultipleSongsToQueue(List<Song> songsToAdd) =>
      _service.addMultipleSongsToQueue(_songsToModel(songsToAdd));

  @override
  Future<void> removeDeletedSongFromQueue(int songId) =>
      _service.removeDeletedSongFromQueue(songId);

  @override
  Future<void> removeDeletedSongsFromQueue(Set<int> deletedSongIds) =>
      _service.removeDeletedSongsFromQueue(deletedSongIds);

  @override
  void updateSongsList(List<Song> newSongs) =>
      _service.updateSongsList(_songsToModel(newSongs));

  @override
  Future<void> ensureShuffleOnAndReshuffle() =>
      _service.ensureShuffleOnAndReshuffle();

  @override
  Future<void> ensureShuffleOff() => _service.ensureShuffleOff();

  @override
  Future<void> ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition() =>
      _service.ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();
}
