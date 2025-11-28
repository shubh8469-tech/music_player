import '../repositories/genre_repository.dart';

class UpdateGenreName {
  final GenreRepository repository;

  UpdateGenreName(this.repository);

  Future<void> call(int genreId, String newName) {
    return repository.updateGenreName(genreId, newName);
  }
}

