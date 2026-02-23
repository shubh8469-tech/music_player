import 'package:music_app/features/songs/domain/entities/song.dart';
import 'playback_loop_mode.dart';

/// Domain state for the music player (queue, position, loop, shuffle).
class PlaybackState {
  const PlaybackState({
    this.songs = const [],
    this.currentIndex,
    this.currentSongId,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration,
    this.loopMode = PlaybackLoopMode.off,
    this.shuffleEnabled = false,
  });

  final List<Song> songs;
  final int? currentIndex;
  final int? currentSongId;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;
  final PlaybackLoopMode loopMode;
  final bool shuffleEnabled;

  bool get hasSongs => songs.isNotEmpty;
  bool get isEmpty => songs.isEmpty;

  Song? get currentSong {
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

  double get progress {
    final dur = duration;
    if (dur == null || dur.inMilliseconds <= 0) return 0.0;
    return (position.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
  }
}
