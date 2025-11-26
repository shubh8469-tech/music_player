import '../entities/genre.dart';
import '../repositories/genre_repository.dart';

class GetAllGenres {
  final GenreRepository repository;

  GetAllGenres(this.repository);

  Future<List<Genre>> call() async {
    return await repository.getAllGenres();
  }
}

