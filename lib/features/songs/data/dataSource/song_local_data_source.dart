import 'package:sqflite/sqflite.dart';
import '../../../../core/db/app_database.dart';
import '../models/song_model.dart';

abstract class SongLocalDataSource {
  Future<int> insertSong(SongModel song);
  Future<List<SongModel>> getAllSongs();
  Future<int> deleteSong(int id);
}

class SongLocalDataSourceImpl implements SongLocalDataSource {
  final Database db;

  SongLocalDataSourceImpl(this.db);

  @override
  Future<int> insertSong(SongModel song) async {
    final db = await AppDatabase.instance();
    return await db.insert('songs', song.toMap());
  }

  @override
  Future<List<SongModel>> getAllSongs() async {
    final db = await AppDatabase.instance();
    final result = await db.query('songs');
    return result.map((map) => SongModel.fromMap(map)).toList();
  }

  @override
  Future<int> deleteSong(int id) async {
    final db = await AppDatabase.instance();
    return await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }
}
