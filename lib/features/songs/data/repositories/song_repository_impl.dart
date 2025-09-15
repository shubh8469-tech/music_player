// data/repositories/song_repository_impl.dart
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../dataSource/song_local_data_source.dart';
import '../models/song_model.dart';

class SongRepositoryImpl implements SongRepository {
  final SongLocalDataSource localDataSource;

  SongRepositoryImpl(this.localDataSource);

  @override
  Future<void> addSong(Song song) async {
    await localDataSource.insertSong(SongModel(
      title: song.title,
      artist: song.artist,
      album: song.album,
      genre: song.genre,
      duration: song.duration,
      filePath: song.filePath,
      artworkPath: song.artworkPath,
    ));
  }

  @override
  Future<List<Song>> fetchAllSongs() async {
    return await localDataSource.getAllSongs();
  }

  @override
  Future<void> removeSong(int id) async {
    await localDataSource.deleteSong(id);
  }
}
