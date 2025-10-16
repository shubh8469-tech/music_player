import '../../../songs/domain/entities/song.dart';
import '../repositories/artist_repository.dart';

class GetArtistSongs {
  final ArtistRepository repository;

  GetArtistSongs(this.repository);

  Future<List<Song>> call(int artistId) async {
    return await repository.getSongsForArtist(artistId);
  }
}
