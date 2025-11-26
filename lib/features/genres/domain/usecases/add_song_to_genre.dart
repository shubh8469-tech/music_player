import '../repositories/genre_repository.dart';

class AddSongToGenre {
  final GenreRepository repository;

  AddSongToGenre(this.repository);

  Future<void> call(int genreId, int songId) async {
    return await repository.addSongToGenre(genreId, songId);
  }
}

