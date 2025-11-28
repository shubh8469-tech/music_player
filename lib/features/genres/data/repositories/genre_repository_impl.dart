import '../../../songs/domain/entities/song.dart';
import '../../domain/entities/genre.dart';
import '../../domain/repositories/genre_repository.dart';
import '../dataSource/genre_local_data_source.dart';
import '../models/genre_model.dart';

class GenreRepositoryImpl implements GenreRepository {
  final GenreLocalDataSource localDataSource;

  GenreRepositoryImpl(this.localDataSource);

  @override
  Future<int> addGenre(Genre genre) async {
    final genreModel = GenreModel(
      id: genre.id,
      name: genre.name,
      songCount: genre.songCount,
      artworkPath: genre.artworkPath,
      createdTime: genre.createdTime,
      updatedTime: genre.updatedTime,
    );
    return await localDataSource.insertGenre(genreModel);
  }

  @override
  Future<List<Genre>> getAllGenres() async {
    return await localDataSource.getAllGenres();
  }

  @override
  Future<Genre?> getGenreByName(String name) async {
    return await localDataSource.getGenreByName(name);
  }

  @override
  Future<int> removeGenre(int id) async {
    return await localDataSource.deleteGenre(id);
  }

  @override
  Future<void> addSongToGenre(int genreId, int songId) async {
    return await localDataSource.addSongToGenre(genreId, songId);
  }

  @override
  Future<List<Song>> getSongsForGenre(int genreId) async {
    return await localDataSource.getSongsForGenre(genreId);
  }

  @override
  Future<void> updateGenreCover(int genreId, String? coverPath) async {
    return await localDataSource.updateGenreCover(genreId, coverPath);
  }

  @override
  Future<void> updateGenreName(int genreId, String newName) async {
    return await localDataSource.updateGenreName(genreId, newName);
  }

  @override
  Future<void> clearAllGenres() async {
    return await localDataSource.clearAllGenres();
  }
}

