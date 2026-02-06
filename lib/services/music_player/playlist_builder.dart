import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/songs/data/models/song_model.dart';

/// Helper for creating AudioSource instances from song models.
class PlaylistBuilder {
  PlaylistBuilder._();

  /// Creates a single AudioSource from a song.
  static AudioSource createAudioSource(SongsModel song) {
    Uri? artUri;
    try {
      if (song.artwork_path != null && song.artwork_path!.isNotEmpty) {
        artUri = Uri.file(song.artwork_path!);
      }
    } catch (_) {}

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

  /// Creates a ConcatenatingAudioSource from a list of songs.
  static ConcatenatingAudioSource createPlaylist(List<SongsModel> songs) {
    return ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songs.map(createAudioSource).toList(),
    );
  }
}
