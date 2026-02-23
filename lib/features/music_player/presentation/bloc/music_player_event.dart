import 'package:music_app/features/songs/domain/entities/song.dart';
import 'package:music_app/features/music_player/domain/entities/playback_loop_mode.dart';

/// Base type for all music player user actions.
sealed class MusicPlayerEvent {
  const MusicPlayerEvent();
}

// --- Playlist
final class SetPlaylistEvent extends MusicPlayerEvent {
  SetPlaylistEvent(this.songs, {this.startIndex = 0, this.autoPlay = true});
  final List<Song> songs;
  final int startIndex;
  final bool autoPlay;
}

final class SetShufflePlaylistEvent extends MusicPlayerEvent {
  SetShufflePlaylistEvent(this.songs, {this.startIndex = 0, this.autoPlay = true});
  final List<Song> songs;
  final int startIndex;
  final bool autoPlay;
}

final class ResetPlaylistEvent extends MusicPlayerEvent {
  ResetPlaylistEvent(this.songs);
  final List<Song> songs;
}

final class SyncPlaylistWithUpdatedSongsEvent extends MusicPlayerEvent {
  SyncPlaylistWithUpdatedSongsEvent(this.songs);
  final List<Song> songs;
}

final class UpdateSongsListEvent extends MusicPlayerEvent {
  UpdateSongsListEvent(this.songs);
  final List<Song> songs;
}

final class UpdateSongsInQueueWithIndexEvent extends MusicPlayerEvent {
  UpdateSongsInQueueWithIndexEvent(this.songs, this.preserveIndex);
  final List<Song> songs;
  final int preserveIndex;
}

// --- Transport
final class PlayEvent extends MusicPlayerEvent { const PlayEvent(); }
final class PauseEvent extends MusicPlayerEvent { const PauseEvent(); }
final class NextEvent extends MusicPlayerEvent { const NextEvent(); }
final class PreviousEvent extends MusicPlayerEvent { const PreviousEvent(); }
final class SeekEvent extends MusicPlayerEvent {
  SeekEvent(this.position, {this.index});
  final Duration position;
  final int? index;
}
final class StopAndClearQueueEvent extends MusicPlayerEvent { const StopAndClearQueueEvent(); }

// --- Shuffle / loop
final class ToggleShuffleEvent extends MusicPlayerEvent { const ToggleShuffleEvent(); }
final class SetLoopModeEvent extends MusicPlayerEvent {
  SetLoopModeEvent(this.mode);
  final PlaybackLoopMode mode;
}
final class SetPlaybackSpeedEvent extends MusicPlayerEvent {
  SetPlaybackSpeedEvent(this.speed);
  final double speed;
}
final class EnsureShuffleOnAndReshuffleEvent extends MusicPlayerEvent { const EnsureShuffleOnAndReshuffleEvent(); }
final class EnsureShuffleOffEvent extends MusicPlayerEvent { const EnsureShuffleOffEvent(); }
final class EnsureShuffleOnReshuffleIndexEvent extends MusicPlayerEvent { const EnsureShuffleOnReshuffleIndexEvent(); }
final class ToggleRepeatEvent extends MusicPlayerEvent { const ToggleRepeatEvent(); }

// --- Queue
final class PlayNextSingleSongEvent extends MusicPlayerEvent {
  PlayNextSingleSongEvent(this.song);
  final Song song;
}
final class PlayNextMultipleSongsEvent extends MusicPlayerEvent {
  PlayNextMultipleSongsEvent(this.songs);
  final List<Song> songs;
}
final class AddSingleSongToQueueEvent extends MusicPlayerEvent {
  AddSingleSongToQueueEvent(this.song);
  final Song song;
}
final class AddMultipleSongsToQueueEvent extends MusicPlayerEvent {
  AddMultipleSongsToQueueEvent(this.songs);
  final List<Song> songs;
}
final class RemoveFromQueueAtIndexEvent extends MusicPlayerEvent {
  RemoveFromQueueAtIndexEvent(this.removeIndex, this.newCurrentIndex);
  final int removeIndex;
  final int newCurrentIndex;
}
final class PrepareReorderForCurrentSongEvent extends MusicPlayerEvent {
  PrepareReorderForCurrentSongEvent(this.oldIndex, this.newIndex);
  final int oldIndex;
  final int newIndex;
}
final class SwapReorderSongInQueueEvent extends MusicPlayerEvent {
  SwapReorderSongInQueueEvent(this.oldIndex, this.newIndex);
  final int oldIndex;
  final int newIndex;
}
final class ReorderSongInQueueEvent extends MusicPlayerEvent {
  ReorderSongInQueueEvent(this.oldIndex, this.newIndex);
  final int oldIndex;
  final int newIndex;
}
final class RemoveDeletedSongFromQueueEvent extends MusicPlayerEvent {
  RemoveDeletedSongFromQueueEvent(this.songId);
  final int songId;
}
final class RemoveDeletedSongsFromQueueEvent extends MusicPlayerEvent {
  RemoveDeletedSongsFromQueueEvent(this.songIds);
  final Set<int> songIds;
}
