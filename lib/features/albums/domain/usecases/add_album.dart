import '../entities/album.dart';
import '../repositories/album_repository.dart';

class AddAlbum {
  final AlbumRepository repository;

  AddAlbum(this.repository);

  Future<int> call(Album album) async {
    return await repository.addAlbum(album);
  }
}
