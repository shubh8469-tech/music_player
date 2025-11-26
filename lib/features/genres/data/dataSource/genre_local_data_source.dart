import 'package:sqflite/sqflite.dart';
import '../../../songs/data/models/song_model.dart';
import '../models/genre_model.dart';

abstract class GenreLocalDataSource {
  Future<int> insertGenre(GenreModel genre);
  Future<List<GenreModel>> getAllGenres();
  Future<GenreModel?> getGenreByName(String name);
  Future<int> deleteGenre(int id);
  Future<void> addSongToGenre(int genreId, int songId);
  Future<List<SongsModel>> getSongsForGenre(int genreId);
  Future<void> updateGenreCover(int genreId, String? coverPath);
  Future<void> clearAllGenres();
}

class GenreLocalDataSourceImpl implements GenreLocalDataSource {
  final Database db;

  GenreLocalDataSourceImpl(this.db);

  @override
  Future<int> insertGenre(GenreModel genre) async {
    return await db.insert(
      'genres',
      genre.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<GenreModel>> getAllGenres() async {
    final result = await db.query('genres', orderBy: 'name ASC');
    return result.map((map) => GenreModel.fromMap(map)).toList();
  }

  @override
  Future<GenreModel?> getGenreByName(String name) async {
    final result = await db.query(
      'genres',
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
      whereArgs: [name],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return GenreModel.fromMap(result.first);
  }

  @override
  Future<int> deleteGenre(int id) async {
    await db.delete('genre_songs', where: 'genre_id = ?', whereArgs: [id]);
    return await db.delete('genres', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> addSongToGenre(int genreId, int songId) async {
    await db.insert('genre_songs', {
      'genre_id': genreId,
      'song_id': songId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<List<SongsModel>> getSongsForGenre(int genreId) async {
    final result = await db.rawQuery(
      '''
      SELECT s.* FROM songs s
      INNER JOIN genre_songs gs ON s.id = gs.song_id
      WHERE gs.genre_id = ? AND s.is_hidden = 0
      ORDER BY s.title ASC
    ''',
      [genreId],
    );

    return result.map((row) => SongsModel.fromMap(row)).toList();
  }

  @override
  Future<void> updateGenreCover(int genreId, String? coverPath) async {
    await db.update(
      'genres',
      {
        'artwork_path': coverPath,
        'updated_time': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [genreId],
    );
  }

  @override
  Future<void> clearAllGenres() async {
    await db.delete('genre_songs');
    await db.delete('genres');
  }
}

