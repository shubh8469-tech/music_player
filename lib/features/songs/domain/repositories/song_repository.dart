// domain/repositories/song_repository.dart
import '../entities/song.dart';

abstract class SongRepository {
  Future<void> addSong(Song song);
  Future<List<Song>> fetchAllSongs();
  Future<void> removeSong(int id);
}
