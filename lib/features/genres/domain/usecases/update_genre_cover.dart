import '../repositories/genre_repository.dart';

class UpdateGenreCover {
  final GenreRepository repository;

  UpdateGenreCover(this.repository);

  Future<void> call(int genreId, String? coverPath) async {
    return await repository.updateGenreCover(genreId, coverPath);
  }
}

