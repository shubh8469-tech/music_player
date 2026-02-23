import 'package:sqflite/sqflite.dart';
import '../../../songs/data/models/song_model.dart';
import '../models/artist_model.dart';

abstract class ArtistLocalDataSource {
  Future<int> insertArtist(ArtistModel artist);
  Future<List<ArtistModel>> getAllArtists();
  Future<ArtistModel?> getArtistByName(String name);
  Future<int> deleteArtist(int id);
  Future<void> addSongToArtist(int artistId, int songId);
  Future<List<SongsModel>> getSongsForArtist(int artistId);
  Future<void> updateArtistAlbumCount(int artistId, int albumCount);
  Future<void> updateArtistCover(int artistId, String? coverPath);
  Future<void> updateArtistName(int artistId, String newName);
  Future<void> clearAllArtists();
}

class ArtistLocalDataSourceImpl implements ArtistLocalDataSource {
  final Database db;

  ArtistLocalDataSourceImpl(this.db);

  @override
  Future<int> insertArtist(ArtistModel artist) async {
    return await db.insert(
      'artists',
      artist.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ArtistModel>> getAllArtists() async {
    final result = await db.query('artists', orderBy: 'name ASC');
    return result.map((map) => ArtistModel.fromMap(map)).toList();
  }

  @override
  Future<ArtistModel?> getArtistByName(String name) async {
    final result = await db.query(
      'artists',
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
      whereArgs: [name],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return ArtistModel.fromMap(result.first);
  }

  @override
  Future<int> deleteArtist(int id) async {
    await db.delete('artist_songs', where: 'artist_id = ?', whereArgs: [id]);
    return await db.delete('artists', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> addSongToArtist(int artistId, int songId) async {
    await db.insert('artist_songs', {
      'artist_id': artistId,
      'song_id': songId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<List<SongsModel>> getSongsForArtist(int artistId) async {
    final result = await db.rawQuery(
      '''
      SELECT s.* FROM songs s
      INNER JOIN artist_songs ars ON s.id = ars.song_id
      WHERE ars.artist_id = ? AND s.is_hidden = 0
      ORDER BY s.title ASC
    ''',
      [artistId],
    );

    return result.map((row) => SongsModel.fromMap(row)).toList();
  }

  @override
  Future<void> updateArtistAlbumCount(int artistId, int albumCount) async {
    await db.update(
      'artists',
      {'album_count': albumCount},
      where: 'id = ?',
      whereArgs: [artistId],
    );
  }

  @override
  Future<void> updateArtistCover(int artistId, String? coverPath) async {
    await db.update(
      'artists',
      {
        'artwork_path': coverPath,
        'updated_time': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [artistId],
    );
  }

  @override
  Future<void> updateArtistName(int artistId, String newName) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Artist name cannot be empty');
    }

    // Update artist name
    await db.update(
      'artists',
      {
        'name': trimmedName,
        'updated_time': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [artistId],
    );

    // Update all songs with this artist to have the new artist name
    await db.update(
      'songs',
      {
        'artist': trimmedName,
        'updated_time': DateTime.now().toIso8601String(),
      },
      where: 'id IN (SELECT song_id FROM artist_songs WHERE artist_id = ?)',
      whereArgs: [artistId],
    );
  }

  @override
  Future<void> clearAllArtists() async {
    await db.delete('artist_songs');
    await db.delete('artists');
  }
}
