import '../repositories/album_repository.dart';

class UpdateAlbumName {
  final AlbumRepository repository;

  UpdateAlbumName(this.repository);

  Future<void> call(int albumId, String newName) {
    return repository.updateAlbumName(albumId, newName);
  }
}

