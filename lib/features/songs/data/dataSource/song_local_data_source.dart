import 'package:sqflite/sqflite.dart';
import '../../../../core/db/app_database.dart';
import '../models/song_model.dart';

abstract class SongLocalDataSource {
  Future<int> insertSong(SongsModel song);
  Future<List<SongsModel>> getAllSongs();
  Future<int> deleteSong(int id);
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
  Future<List<SongsModel>> getAllSongs() async {
    final result = await db.query('songs');
    return result.map((map) => SongsModel.fromMap(map)).toList();
  }

  @override
  Future<int> deleteSong(int id) async {
    return await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }
}
