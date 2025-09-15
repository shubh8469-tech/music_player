// get_all_songs.dart
import '../entities/song.dart';
import '../repositories/song_repository.dart';

class GetAllSongs {
  final SongRepository repository;
  GetAllSongs(this.repository);

  Future<List<Song>> call() => repository.fetchAllSongs();
}
