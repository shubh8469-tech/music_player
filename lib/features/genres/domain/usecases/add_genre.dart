import '../entities/genre.dart';
import '../repositories/genre_repository.dart';

class AddGenre {
  final GenreRepository repository;

  AddGenre(this.repository);

  Future<int> call(Genre genre) async {
    return await repository.addGenre(genre);
  }
}

