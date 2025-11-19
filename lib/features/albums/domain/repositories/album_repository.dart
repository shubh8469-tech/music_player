import '../../../songs/domain/entities/song.dart';
import '../entities/album.dart';

abstract class AlbumRepository {
  Future<int> addAlbum(Album album);
  Future<List<Album>> getAllAlbums();
  Future<Album?> getAlbumByNameAndArtist(String name, String? artist);
  Future<int> removeAlbum(int id);
  Future<void> addSongToAlbum(int albumId, int songId);
  Future<List<Song>> getSongsForAlbum(int albumId);
  Future<List<Album>> getAlbumsByArtist(String artistName);
  Future<void> refreshAlbumCachedArtists(int albumId);
  Future<void> clearAllAlbums();
}
