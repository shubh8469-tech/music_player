import '../../../songs/domain/entities/song.dart';
import '../entities/artist.dart';

abstract class ArtistRepository {
  Future<int> addArtist(Artist artist);
  Future<List<Artist>> getAllArtists();
  Future<Artist?> getArtistByName(String name);
  Future<int> removeArtist(int id);
  Future<void> addSongToArtist(int artistId, int songId);
  Future<List<Song>> getSongsForArtist(int artistId);
  Future<void> updateArtistAlbumCount(int artistId, int albumCount);
  Future<void> clearAllArtists();
}
