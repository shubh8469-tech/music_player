import 'package:sqflite/sqflite.dart';
import '../../../songs/data/models/song_model.dart';
import '../models/folder_model.dart';

abstract class FolderLocalDataSource {
  Future<int> insertFolder(FolderModel folder);
  Future<List<FolderModel>> getAllFolders();
  Future<FolderModel?> getFolderByName(String name);
  Future<int> deleteFolder(int id);
  Future<void> addSongToFolder(int folderId, int songId);
  Future<List<SongsModel>> getSongsForFolder(int folderId);
  Future<void> clearAllFolders();
}

class FolderLocalDataSourceImpl implements FolderLocalDataSource {
  final Database db;

  FolderLocalDataSourceImpl(this.db);

  @override
  Future<int> insertFolder(FolderModel folder) async {
    return await db.insert(
      'folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<FolderModel>> getAllFolders() async {
    final result = await db.query('folders', orderBy: 'name ASC');
    return result.map((map) => FolderModel.fromMap(map)).toList();
  }

  @override
  Future<FolderModel?> getFolderByName(String name) async {
    final result = await db.query(
      'folders',
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
      whereArgs: [name],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return FolderModel.fromMap(result.first);
  }

  @override
  Future<int> deleteFolder(int id) async {
    await db.delete('folder_songs', where: 'folder_id = ?', whereArgs: [id]);
    return await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> addSongToFolder(int folderId, int songId) async {
    await db.insert('folder_songs', {
      'folder_id': folderId,
      'song_id': songId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<List<SongsModel>> getSongsForFolder(int folderId) async {
    final result = await db.rawQuery(
      '''
      SELECT s.* FROM songs s
      INNER JOIN folder_songs fs ON s.id = fs.song_id
      WHERE fs.folder_id = ?
      ORDER BY s.title ASC
    ''',
      [folderId],
    );

    return result.map((row) => SongsModel.fromMap(row)).toList();
  }

  @override
  Future<void> clearAllFolders() async {
    await db.delete('folder_songs');
    await db.delete('folders');
  }
}
