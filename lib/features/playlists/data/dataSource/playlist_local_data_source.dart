import 'package:sqflite/sqflite.dart';

import '../../../songs/data/models/song_model.dart';
import '../models/playlist_model.dart';

abstract class PlaylistLocalDataSource {
  Future<int> insertPlaylist(PlaylistModel playlist);
  Future<List<PlaylistModel>> getAllPlaylists();
  Future<int> deletePlaylist(int id);
  Future<void> addSongToPlaylist(int playlistId, int songId, int position);
  Future<void> addMultipleSongsToPlaylist(int playlistId, List<int> songIds);
  Future<void> removeSongFromPlaylist(int playlistId, int songId);
  Future<void> removeMultipleSongsFromPlaylist(
    int playlistId,
    List<int> songIds,
  );
  Future<List<SongsModel>> getSongsForPlaylist(int playlistId);
  Future<List<PlaylistModel>> getSystemPlaylistsWithCounts();
  Future<List<SongsModel>> getSongsForSystemPlaylist(String systemKey);
  Future<void> reorderPlaylistSongs(int playlistId, List<int> songIdsInOrder);
}

class PlaylistLocalDataSourceImpl implements PlaylistLocalDataSource {
  final Database db;

  PlaylistLocalDataSourceImpl(this.db);

  @override
  Future<int> insertPlaylist(PlaylistModel playlist) async {
    return await db.insert(
      'playlists',
      playlist.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // overwrite if same id
    );
  }

  @override
  Future<List<PlaylistModel>> getAllPlaylists() async {
    final result = await db.query(
      'playlists',
      where: 'is_system = 0',
      orderBy: 'created_time DESC',
    );
    return result.map((map) => PlaylistModel.fromMap(map)).toList();
  }

  @override
  Future<int> deletePlaylist(int id) async {
    return await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  /// --------------------------
  /// 🎵 Playlist Songs Methods
  /// --------------------------

  @override
  Future<void> addSongToPlaylist(
    int playlistId,
    int songId,
    int position,
  ) async {
    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': songId,
      'position': position,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> addMultipleSongsToPlaylist(
    int playlistId,
    List<int> songIds,
  ) async {
    // Get current song count for position calculation
    final currentSongs = await db.query(
      'playlist_songs',
      columns: ['song_id'],
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );

    int startPosition = currentSongs.length;

    // Use batch insert for better performance and atomicity
    final batch = db.batch();
    for (int i = 0; i < songIds.length; i++) {
      batch.insert('playlist_songs', {
        'playlist_id': playlistId,
        'song_id': songIds[i],
        'position': startPosition + i,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  @override
  Future<void> removeMultipleSongsFromPlaylist(
    int playlistId,
    List<int> songIds,
  ) async {
    // Use batch delete for better performance
    final batch = db.batch();
    for (final songId in songIds) {
      batch.delete(
        'playlist_songs',
        where: 'playlist_id = ? AND song_id = ?',
        whereArgs: [playlistId, songId],
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<SongsModel>> getSongsForPlaylist(int playlistId) async {
    final result = await db.rawQuery(
      '''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.song_id
      WHERE ps.playlist_id = ?
      ORDER BY ps.position ASC
    ''',
      [playlistId],
    );

    return result.map((row) => SongsModel.fromMap(row)).toList();
  }

  @override
  Future<List<PlaylistModel>> getSystemPlaylistsWithCounts() async {
    // We calculate counts dynamically per system_key
    final List<PlaylistModel> systemPlaylists = [];

    final maps = await db.query('playlists', where: 'is_system = 1');

    // Calculate for each system playlist key
    for (final row in maps) {
      final String key = (row['system_key'] as String?) ?? '';
      int count = 0;

      if (key == 'most_played') {
        final res = await db.rawQuery(
          "SELECT COUNT(*) as c FROM songs WHERE play_count > 0",
        );
        count = Sqflite.firstIntValue(res) ?? 0;
      } else if (key == 'recently_added') {
        final res = await db.rawQuery(
          "SELECT COUNT(*) as c FROM songs WHERE datetime(created_time) >= datetime('now','-3 days')",
        );
        count = Sqflite.firstIntValue(res) ?? 0;
      } else if (key == 'recently_played') {
        final res = await db.rawQuery(
          "SELECT COUNT(*) as c FROM songs WHERE last_played IS NOT NULL",
        );
        count = Sqflite.firstIntValue(res) ?? 0;
      } else if (key == 'favorites') {
        final res = await db.rawQuery(
          "SELECT COUNT(*) as c FROM songs WHERE is_favorite = 1",
        );
        count = Sqflite.firstIntValue(res) ?? 0;
      }

      final playlist = PlaylistModel(
        id: row['id'] as int,
        name: row['name'] as String,
        songCount: count,
        createdTime: DateTime.parse(row['created_time'] as String),
        updatedTime: DateTime.parse(row['updated_time'] as String),
        isSystem: (row['is_system'] as int? ?? 0) == 1,
        systemKey: row['system_key'] as String?,
      );
      systemPlaylists.add(playlist);
    }

    return systemPlaylists;
  }

  @override
  Future<List<SongsModel>> getSongsForSystemPlaylist(String systemKey) async {
    if (systemKey == 'most_played') {
      final res = await db.rawQuery('''
        SELECT * FROM songs
        WHERE play_count > 0
        ORDER BY play_count DESC, last_played DESC NULLS LAST
        ''');
      return res.map((row) => SongsModel.fromMap(row)).toList();
    }

    if (systemKey == 'recently_added') {
      final res = await db.rawQuery('''
        SELECT * FROM songs
        WHERE datetime(created_time) >= datetime('now','-3 days')
        ORDER BY datetime(created_time) DESC
        ''');
      return res.map((row) => SongsModel.fromMap(row)).toList();
    }

    if (systemKey == 'recently_played') {
      final res = await db.rawQuery('''
        SELECT * FROM songs
        WHERE last_played IS NOT NULL
        ORDER BY datetime(last_played) DESC
        ''');
      return res.map((row) => SongsModel.fromMap(row)).toList();
    }

    if (systemKey == 'favorites') {
      final res = await db.rawQuery('''
        SELECT * FROM songs
        WHERE is_favorite = 1
        ORDER BY datetime(updated_time) DESC
        ''');
      return res.map((row) => SongsModel.fromMap(row)).toList();
    }

    return [];
  }

  @override
  Future<void> reorderPlaylistSongs(
    int playlistId,
    List<int> songIdsInOrder,
  ) async {
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (int i = 0; i < songIdsInOrder.length; i++) {
        batch.update(
          'playlist_songs',
          {'position': i},
          where: 'playlist_id = ? AND song_id = ?',
          whereArgs: [playlistId, songIdsInOrder[i]],
        );
      }
      await batch.commit(noResult: true);
    });
  }
}
