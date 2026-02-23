import 'package:just_audio/just_audio.dart';

import '../../../songs/data/models/song_model.dart';

/// Unified state for the music player, replacing multiple StreamBuilders.
class MusicPlayerState {
  const MusicPlayerState({
    this.songs = const [],
    this.currentIndex,
    this.currentSongId,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration,
    this.loopMode = LoopMode.off,
    this.shuffleEnabled = false,
  });

  final List<SongsModel> songs;
  final int? currentIndex;
  final int? currentSongId;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;
  final LoopMode loopMode;
  final bool shuffleEnabled;

  bool get hasSongs => songs.isNotEmpty;
  bool get isEmpty => songs.isEmpty;

  /// Current song based on currentSongId (respects reorder cache) or index.
  SongsModel? get currentSong {
    if (songs.isEmpty) return null;
    if (currentSongId != null) {
      for (final s in songs) {
        if (s.id == currentSongId) return s;
      }
    }
    final idx = currentIndex ?? -1;
    if (idx >= 0 && idx < songs.length) return songs[idx];
    return songs.first;
  }

  /// Progress for progress bar (0.0 to 1.0).
  double get progress {
    final dur = duration;
    if (dur == null || dur.inMilliseconds <= 0) return 0.0;
    return (position.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicPlayerState &&
          runtimeType == other.runtimeType &&
          identical(songs, other.songs) &&
          currentIndex == other.currentIndex &&
          currentSongId == other.currentSongId &&
          isPlaying == other.isPlaying &&
          position.inMilliseconds == other.position.inMilliseconds &&
          duration?.inMilliseconds == other.duration?.inMilliseconds &&
          loopMode == other.loopMode &&
          shuffleEnabled == other.shuffleEnabled;

  @override
  int get hashCode => Object.hash(
        identityHashCode(songs),
        currentIndex,
        currentSongId,
        isPlaying,
        position.inMilliseconds,
        duration?.inMilliseconds,
        loopMode,
        shuffleEnabled,
      );
}
