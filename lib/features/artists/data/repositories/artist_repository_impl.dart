import '../../../songs/domain/entities/song.dart';
import '../../domain/entities/artist.dart';
import '../../domain/repositories/artist_repository.dart';
import '../datasources/artist_local_data_source.dart';
import '../models/artist_model.dart';

class ArtistRepositoryImpl implements ArtistRepository {
  final ArtistLocalDataSource localDataSource;

  ArtistRepositoryImpl(this.localDataSource);

  @override
  Future<int> addArtist(Artist artist) async {
    final artistModel = ArtistModel(
      id: artist.id,
      name: artist.name,
      songCount: artist.songCount,
      albumCount: artist.albumCount,
      artworkPath: artist.artworkPath,
      createdTime: artist.createdTime,
      updatedTime: artist.updatedTime,
    );
    return await localDataSource.insertArtist(artistModel);
  }

  @override
  Future<List<Artist>> getAllArtists() async {
    return await localDataSource.getAllArtists();
  }

  @override
  Future<Artist?> getArtistByName(String name) async {
    return await localDataSource.getArtistByName(name);
  }

  @override
  Future<int> removeArtist(int id) async {
    return await localDataSource.deleteArtist(id);
  }

  @override
  Future<void> addSongToArtist(int artistId, int songId) async {
    return await localDataSource.addSongToArtist(artistId, songId);
  }

  @override
  Future<List<Song>> getSongsForArtist(int artistId) async {
    return await localDataSource.getSongsForArtist(artistId);
  }

  @override
  Future<void> updateArtistAlbumCount(int artistId, int albumCount) async {
    return await localDataSource.updateArtistAlbumCount(artistId, albumCount);
  }

  @override
  Future<void> updateArtistCover(int artistId, String? coverPath) async {
    return await localDataSource.updateArtistCover(artistId, coverPath);
  }

  @override
  Future<void> updateArtistName(int artistId, String newName) async {
    return await localDataSource.updateArtistName(artistId, newName);
  }

  @override
  Future<void> clearAllArtists() async {
    return await localDataSource.clearAllArtists();
  }
}
