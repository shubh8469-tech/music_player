import '../repositories/artist_repository.dart';

class UpdateArtistCover {
  final ArtistRepository repository;

  UpdateArtistCover(this.repository);

  Future<void> call(int artistId, String? coverPath) {
    return repository.updateArtistCover(artistId, coverPath);
  }
}




