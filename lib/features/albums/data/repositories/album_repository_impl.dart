import '../../../songs/domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/repositories/album_repository.dart';
import '../datasources/album_local_data_source.dart';
import '../models/album_model.dart';

class AlbumRepositoryImpl implements AlbumRepository {
  final AlbumLocalDataSource localDataSource;

  AlbumRepositoryImpl(this.localDataSource);

  @override
  Future<int> addAlbum(Album album) async {
    final albumModel = AlbumModel(
      id: album.id,
      name: album.name,
      artist: album.artist,
      songCount: album.songCount,
      year: album.year,
      artworkPath: album.artworkPath,
      createdTime: album.createdTime,
      updatedTime: album.updatedTime,
      cachedArtistNames: album.cachedArtistNames,
    );
    return await localDataSource.insertAlbum(albumModel);
  }

  @override
  Future<List<Album>> getAllAlbums() async {
    return await localDataSource.getAllAlbums();
  }

  @override
  Future<Album?> getAlbumByNameAndArtist(String name, String? artist) async {
    return await localDataSource.getAlbumByNameAndArtist(name, artist);
  }

  @override
  Future<int> removeAlbum(int id) async {
    return await localDataSource.deleteAlbum(id);
  }

  @override
  Future<void> addSongToAlbum(int albumId, int songId) async {
    return await localDataSource.addSongToAlbum(albumId, songId);
  }

  @override
  Future<List<Song>> getSongsForAlbum(int albumId) async {
    return await localDataSource.getSongsForAlbum(albumId);
  }

  @override
  Future<List<Album>> getAlbumsByArtist(String artistName) async {
    return await localDataSource.getAlbumsByArtist(artistName);
  }

  @override
  Future<void> refreshAlbumCachedArtists(int albumId) async {
    return await localDataSource.refreshAlbumCachedArtists(albumId);
  }

  @override
  Future<void> updateAlbumCover(int albumId, String? coverPath) async {
    return await localDataSource.updateAlbumCover(albumId, coverPath);
  }

  @override
  Future<void> updateAlbumName(int albumId, String newName) async {
    return await localDataSource.updateAlbumName(albumId, newName);
  }

  @override
  Future<void> clearAllAlbums() async {
    return await localDataSource.clearAllAlbums();
  }
}
