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
      where: 'name = ?',
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
      WHERE ars.artist_id = ?
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
  Future<void> clearAllArtists() async {
    await db.delete('artist_songs');
    await db.delete('artists');
  }
}
