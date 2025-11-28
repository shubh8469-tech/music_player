import '../repositories/artist_repository.dart';

class UpdateArtistName {
  final ArtistRepository repository;

  UpdateArtistName(this.repository);

  Future<void> call(int artistId, String newName) {
    return repository.updateArtistName(artistId, newName);
  }
}

