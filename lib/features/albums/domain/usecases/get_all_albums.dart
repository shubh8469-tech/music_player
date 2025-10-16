import '../entities/album.dart';
import '../repositories/album_repository.dart';

class GetAllAlbums {
  final AlbumRepository repository;

  GetAllAlbums(this.repository);

  Future<List<Album>> call() async {
    return await repository.getAllAlbums();
  }
}
