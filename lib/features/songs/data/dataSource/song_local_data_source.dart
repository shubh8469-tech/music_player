import 'package:sqflite/sqflite.dart';
import '../models/song_model.dart';

abstract class SongLocalDataSource {
  Future<int> insertSong(SongsModel song);
  Future<List<SongsModel>> getAllSongs({bool includeHidden = false});
  Future<List<SongsModel>> getHiddenSongs();
  Future<int> updateSongHiddenStatus(int id, bool isHidden);
  Future<void> refreshRelatedEntityCounts();
  Future<int> deleteSong(int id);
  Future<int> updateSong(SongsModel song);
}

class SongLocalDataSourceImpl implements SongLocalDataSource {
  final Database db;

  SongLocalDataSourceImpl(this.db);

  @override
  Future<int> insertSong(SongsModel song) async {
    return await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore, // or replace
    );
  }

  @override
  Future<List<SongsModel>> getAllSongs({bool includeHidden = false}) async {
    final result = await db.query(
      'songs',
      where: includeHidden ? null : 'is_hidden = ?',
      whereArgs: includeHidden ? null : [0],
    );
    return result.map((map) => SongsModel.fromMap(map)).toList();
  }

  @override
  Future<List<SongsModel>> getHiddenSongs() async {
    final result = await db.query(
      'songs',
      where: 'is_hidden = ?',
      whereArgs: [1],
    );
    return result.map((map) => SongsModel.fromMap(map)).toList();
  }

  @override
  Future<int> updateSongHiddenStatus(int id, bool isHidden) async {
    final result = await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final updatedRows = await txn.update(
        'songs',
        {'is_hidden': isHidden ? 1 : 0, 'updated_time': now},
        where: 'id = ?',
        whereArgs: [id],
      );

      final folderRows = await txn.query(
        'folder_songs',
        columns: ['folder_id'],
        where: 'song_id = ?',
        whereArgs: [id],
      );

      if (folderRows.isNotEmpty) {
        final folderIds = folderRows
            .map((row) => row['folder_id'] as int)
            .toSet()
            .toList();

        if (isHidden) {
          for (final folderId in folderIds) {
            final visibleCountResult = await txn.rawQuery(
              '''
              SELECT COUNT(*) as visible_count
              FROM folder_songs fs
              INNER JOIN songs s ON s.id = fs.song_id
              WHERE fs.folder_id = ? AND s.is_hidden = 0
              ''',
              [folderId],
            );
            final visibleCount = Sqflite.firstIntValue(visibleCountResult) ?? 0;
            if (visibleCount == 0) {
              await txn.update(
                'folders',
                {'is_hidden': 1, 'updated_time': now},
                where: 'id = ?',
                whereArgs: [folderId],
              );
            }
          }
        } else {
          final placeholders = List.filled(folderIds.length, '?').join(', ');
          await txn.rawUpdate(
            '''
            UPDATE folders
            SET is_hidden = 0,
                updated_time = ?
            WHERE id IN ($placeholders)
            ''',
            [now, ...folderIds],
          );
        }
      }

      return updatedRows;
    });

    await refreshRelatedEntityCounts();
    return result;
  }

  @override
  Future<void> refreshRelatedEntityCounts() async {
    await db.transaction((txn) async {
      await txn.rawUpdate('''
        UPDATE playlists
        SET song_count = (
          SELECT COUNT(*)
          FROM playlist_songs ps
          INNER JOIN songs s ON s.id = ps.song_id
          WHERE ps.playlist_id = playlists.id AND s.is_hidden = 0
        )
      ''');

      await txn.rawUpdate('''
        UPDATE folders
        SET song_count = (
          SELECT COUNT(*)
          FROM folder_songs fs
          INNER JOIN songs s ON s.id = fs.song_id
          WHERE fs.folder_id = folders.id AND s.is_hidden = 0
        )
      ''');

      await txn.rawUpdate('''
        UPDATE albums
        SET song_count = (
          SELECT COUNT(*)
          FROM album_songs als
          INNER JOIN songs s ON s.id = als.song_id
          WHERE als.album_id = albums.id AND s.is_hidden = 0
        )
      ''');

      await txn.rawUpdate('''
        UPDATE artists
        SET song_count = (
          SELECT COUNT(*)
          FROM artist_songs ars
          INNER JOIN songs s ON s.id = ars.song_id
          WHERE ars.artist_id = artists.id AND s.is_hidden = 0
        )
      ''');
    });
  }

  @override
  Future<int> deleteSong(int id) async {
    return await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> updateSong(SongsModel song) async {
    return await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }
}
