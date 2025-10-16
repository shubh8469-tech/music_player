import '../entities/artist.dart';
import '../repositories/artist_repository.dart';

class AddArtist {
  final ArtistRepository repository;

  AddArtist(this.repository);

  Future<int> call(Artist artist) async {
    return await repository.addArtist(artist);
  }
}
