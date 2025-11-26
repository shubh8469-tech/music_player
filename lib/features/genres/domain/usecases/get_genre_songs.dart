import '../../../songs/domain/entities/song.dart';
import '../repositories/genre_repository.dart';

class GetGenreSongs {
  final GenreRepository repository;

  GetGenreSongs(this.repository);

  Future<List<Song>> call(int genreId) async {
    return await repository.getSongsForGenre(genreId);
  }
}

