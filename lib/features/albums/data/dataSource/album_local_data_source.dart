import 'package:sqflite/sqflite.dart';
import '../../../songs/data/models/song_model.dart';
import '../models/album_model.dart';

abstract class AlbumLocalDataSource {
  Future<int> insertAlbum(AlbumModel album);
  Future<List<AlbumModel>> getAllAlbums();
  Future<AlbumModel?> getAlbumByNameAndArtist(String name, String? artist);
  Future<int> deleteAlbum(int id);
  Future<void> addSongToAlbum(int albumId, int songId);
  Future<List<SongsModel>> getSongsForAlbum(int albumId);
  Future<List<AlbumModel>> getAlbumsByArtist(String artistName);
  Future<void> clearAllAlbums();
}

class AlbumLocalDataSourceImpl implements AlbumLocalDataSource {
  final Database db;

  AlbumLocalDataSourceImpl(this.db);

  @override
  Future<int> insertAlbum(AlbumModel album) async {
    return await db.insert(
      'albums',
      album.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<AlbumModel>> getAllAlbums() async {
    final result = await db.query('albums', orderBy: 'name ASC');
    return result.map((map) => AlbumModel.fromMap(map)).toList();
  }

  @override
  Future<AlbumModel?> getAlbumByNameAndArtist(
    String name,
    String? artist,
  ) async {
    final result = await db.query(
      'albums',
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?)) AND LOWER(TRIM(artist)) = LOWER(TRIM(?))',
      whereArgs: [name, artist ?? ''],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return AlbumModel.fromMap(result.first);
  }

  @override
  Future<int> deleteAlbum(int id) async {
    await db.delete('album_songs', where: 'album_id = ?', whereArgs: [id]);
    return await db.delete('albums', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> addSongToAlbum(int albumId, int songId) async {
    await db.insert('album_songs', {
      'album_id': albumId,
      'song_id': songId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<List<SongsModel>> getSongsForAlbum(int albumId) async {
    final result = await db.rawQuery(
      '''
      SELECT s.* FROM songs s
      INNER JOIN album_songs als ON s.id = als.song_id
      WHERE als.album_id = ? AND s.is_hidden = 0
      ORDER BY s.title ASC
    ''',
      [albumId],
    );

    return result.map((row) => SongsModel.fromMap(row)).toList();
  }

  @override
  Future<List<AlbumModel>> getAlbumsByArtist(String artistName) async {
    final result = await db.query(
      'albums',
      where: 'LOWER(TRIM(artist)) = LOWER(TRIM(?))',
      whereArgs: [artistName],
      orderBy: 'year DESC, name ASC',
    );
    return result.map((map) => AlbumModel.fromMap(map)).toList();
  }

  @override
  Future<void> clearAllAlbums() async {
    await db.delete('album_songs');
    await db.delete('albums');
  }
}
