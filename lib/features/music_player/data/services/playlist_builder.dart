import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_app/features/songs/data/models/song_model.dart';

/// Helper for creating AudioSource instances from song models.
class PlaylistBuilder {
  PlaylistBuilder._();

  /// Filters out songs whose file no longer exists (e.g. after backup restore).
  /// content:// URIs are kept since we cannot check existence. Returns the
  /// filtered list and the new start index (by original song id, or 0).
  static Future<({List<SongsModel> list, int startIndex})> filterSongsWithExistingFiles(
    List<SongsModel> songs, {
    int startIndex = 0,
  }) async {
    if (songs.isEmpty) return (list: <SongsModel>[], startIndex: 0);
    final int? startId = startIndex >= 0 && startIndex < songs.length
        ? songs[startIndex].id
        : null;
    final List<SongsModel> out = <SongsModel>[];
    for (final s in songs) {
      if (s.filePath.startsWith('content://')) {
        out.add(s);
        continue;
      }
      try {
        if (await File(s.filePath).exists()) out.add(s);
      } catch (_) {}
    }
    int newStart = 0;
    if (startId != null) {
      final idx = out.indexWhere((s) => s.id == startId);
      if (idx >= 0) newStart = idx;
    }
    return (list: List<SongsModel>.from(out), startIndex: newStart);
  }

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
