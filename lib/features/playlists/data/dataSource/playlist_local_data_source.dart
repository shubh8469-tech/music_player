import 'package:sqflite/sqflite.dart';

import '../../../songs/data/models/song_model.dart';
import '../models/playlist_model.dart';

abstract class PlaylistLocalDataSource {
  Future<int> insertPlaylist(PlaylistModel playlist);
  Future<List<PlaylistModel>> getAllPlaylists();
  Future<int> deletePlaylist(int id);
  Future<void> addSongToPlaylist(int playlistId, int songId, int position);
  Future<void> removeSongFromPlaylist(int playlistId, int songId);
  Future<List<SongsModel>> getSongsForPlaylist(int playlistId);
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
    final result = await db.query('playlists', orderBy: 'created_time DESC');
    return result.map((map) => PlaylistModel.fromMap(map)).toList();
  }

  @override
  Future<int> deletePlaylist(int id) async {
    return await db.delete(
      'playlists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

/// --------------------------
/// 🎵 Playlist Songs Methods
/// --------------------------

  Future<void> addSongToPlaylist(int playlistId, int songId, int position) async {
    await db.insert(
      'playlist_songs',
      {
        'playlist_id': playlistId,
        'song_id': songId,
        'position': position,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
    await db.delete(
      'playlist_songs',
      where: 'playlist_id = ? AND song_id = ?',
      whereArgs: [playlistId, songId],
    );
  }

  Future<List<SongsModel>> getSongsForPlaylist(int playlistId) async {
    final result = await db.rawQuery('''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.song_id
      WHERE ps.playlist_id = ?
      ORDER BY ps.position ASC
    ''', [playlistId]);

    return result.map((row) => SongsModel.fromMap(row)).toList();
  }
}

