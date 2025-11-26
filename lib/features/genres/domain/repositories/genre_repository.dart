import '../../../songs/domain/entities/song.dart';
import '../entities/genre.dart';

abstract class GenreRepository {
  Future<int> addGenre(Genre genre);
  Future<List<Genre>> getAllGenres();
  Future<Genre?> getGenreByName(String name);
  Future<int> removeGenre(int id);
  Future<void> addSongToGenre(int genreId, int songId);
  Future<List<Song>> getSongsForGenre(int genreId);
  Future<void> updateGenreCover(int genreId, String? coverPath);
  Future<void> clearAllGenres();
}

