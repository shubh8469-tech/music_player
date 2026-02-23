import 'package:sqflite/sqflite.dart';
import '../../../songs/data/datasources/song_local_data_source.dart';
import '../../../songs/data/models/song_model.dart';
import '../models/folder_model.dart';

abstract class FolderLocalDataSource {
  Future<int> insertFolder(FolderModel folder);
  Future<List<FolderModel>> getAllFolders({bool includeHidden = false});
  Future<List<FolderModel>> getHiddenFolders();
  Future<FolderModel?> getFolderByName(String name);
  Future<int> updateFolderHiddenStatus(int id, bool isHidden);
  Future<int> deleteFolder(int id);
  Future<void> addSongToFolder(int folderId, int songId);
  Future<List<SongsModel>> getSongsForFolder(int folderId);
  Future<void> clearAllFolders();
}

class FolderLocalDataSourceImpl implements FolderLocalDataSource {
  final Database db;
  final SongLocalDataSource songLocalDataSource;

  FolderLocalDataSourceImpl(this.db, this.songLocalDataSource);

  @override
  Future<int> insertFolder(FolderModel folder) async {
    return await db.insert(
      'folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<FolderModel>> getAllFolders({bool includeHidden = false}) async {
    final result = await db.query(
      'folders',
      where: includeHidden ? null : 'is_hidden = ?',
      whereArgs: includeHidden ? null : [0],
      orderBy: 'name ASC',
    );
    return result.map((map) => FolderModel.fromMap(map)).toList();
  }

  @override
  Future<List<FolderModel>> getHiddenFolders() async {
    final result = await db.query(
      'folders',
      where: 'is_hidden = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
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
  Future<int> updateFolderHiddenStatus(int id, bool isHidden) async {
    final result = await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final updatedRows = await txn.update(
        'folders',
        {
          'is_hidden': isHidden ? 1 : 0,
          'updated_time': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      final songRows = await txn.query(
        'folder_songs',
        columns: ['song_id'],
        where: 'folder_id = ?',
        whereArgs: [id],
      );

      if (songRows.isNotEmpty) {
        final songIds = songRows
            .map((row) => row['song_id'] as int)
            .toSet()
            .toList();
        final placeholders = List.filled(songIds.length, '?').join(', ');
        final params = [
          isHidden ? 1 : 0,
          now,
          ...songIds,
        ];

        await txn.rawUpdate(
          '''
          UPDATE songs
          SET is_hidden = ?, updated_time = ?
          WHERE id IN ($placeholders)
          ''',
          params,
        );
      }

      return updatedRows;
    });

    await songLocalDataSource.refreshRelatedEntityCounts();
    return result;
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
      WHERE fs.folder_id = ? AND s.is_hidden = 0
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
