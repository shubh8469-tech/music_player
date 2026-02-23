import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../datasources/song_local_data_source.dart';
import '../models/song_model.dart';

class SongRepositoryImpl implements SongRepository {
  final SongLocalDataSource localDataSource;

  SongRepositoryImpl(this.localDataSource);

  @override
  Future<void> addSong(Song song) async {
    final songModel = SongsModel(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      genre: song.genre,
      year: song.year,
      duration: song.duration,
      filePath: song.filePath,
      folder: song.folder,
      artwork_path: song.artwork_path,
      createdTime: DateTime.now().toIso8601String(),
      updatedTime: DateTime.now().toIso8601String(),
      isHidden: song.isHidden,
    );

    await localDataSource.insertSong(songModel);
  }

  @override
  Future<List<Song>> fetchAllSongs() async {
    return await localDataSource.getAllSongs();
  }

  @override
  Future<void> removeSong(int id) async {
    await localDataSource.deleteSong(id);
  }

  @override
  Future<void> updateSong(Song song) async {
    final songModel = SongsModel(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      genre: song.genre,
      year: song.year,
      duration: song.duration,
      filePath: song.filePath,
      folder: song.folder,
      artwork_path: song.artwork_path,
      createdTime: DateTime.now().toIso8601String(),
      updatedTime: DateTime.now().toIso8601String(),
      isHidden: song.isHidden,
    );

    await localDataSource.updateSong(songModel);
  }
}
