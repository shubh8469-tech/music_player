import 'package:music_app/features/songs/domain/entities/song.dart';
import '../entities/playback_loop_mode.dart';
import '../entities/playback_state.dart';

/// Domain contract for playback (queue, transport, loop, shuffle).
/// Implemented by data layer; used by use cases and Bloc.
abstract class PlaybackRepository {
  Stream<PlaybackState> get playbackStateStream;
  Stream<void> get libraryChangedStream;

  Future<void> setPlaylist(
    List<Song> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  });

  Future<void> setShufflePlaylist(
    List<Song> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  });

  Future<void> resetPlaylist(List<Song> songs);

  Future<void> play();
  Future<void> pause();
  Future<void> next();
  Future<void> previous();
  Future<void> stop();
  Future<void> stopAndClearQueue();

  Future<void> seek(Duration position, {int? index});

  Future<void> toggleShuffle();
  Future<void> setLoopMode(PlaybackLoopMode mode);
  Future<void> setPlaybackSpeed(double speed);

  void syncPlaylistWithUpdatedSongs(List<Song> updatedSongs);

  Future<int> playNextMultipleSongs(List<Song> nextSongs);
  Future<bool> playNextSingleSong(Song song);

  Future<void> updateSongsInQueue(List<Song> newSongsList);
  Future<void> updateSongsInQueueWithIndex(List<Song> newSongsList, int preserveIndex);

  void prepareReorderForCurrentSong(int oldIndex, int newIndex);
  Future<void> swapReorderSongInQueue(int oldIndex, int newIndex);
  Future<void> reorderSongInQueue(int oldIndex, int newIndex);

  Future<bool> addSingleSongToQueue(Song song);
  Future<int> addMultipleSongsToQueue(List<Song> songsToAdd);

  Future<void> removeDeletedSongFromQueue(int songId);
  Future<void> removeDeletedSongsFromQueue(Set<int> deletedSongIds);

  /// Replaces the current queue list (e.g. after reorder in UI).
  void updateSongsList(List<Song> newSongs);

  Future<void> ensureShuffleOnAndReshuffle();
  Future<void> ensureShuffleOff();
  Future<void> ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();
}
