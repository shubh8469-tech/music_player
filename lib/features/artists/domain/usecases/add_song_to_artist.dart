import '../repositories/artist_repository.dart';

class AddSongToArtist {
  final ArtistRepository repository;

  AddSongToArtist(this.repository);

  Future<void> call(int artistId, int songId) async {
    return await repository.addSongToArtist(artistId, songId);
  }
}
