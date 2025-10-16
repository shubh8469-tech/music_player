import '../entities/artist.dart';
import '../repositories/artist_repository.dart';

class GetAllArtists {
  final ArtistRepository repository;

  GetAllArtists(this.repository);

  Future<List<Artist>> call() async {
    return await repository.getAllArtists();
  }
}
