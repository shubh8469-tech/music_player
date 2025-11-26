import '../repositories/album_repository.dart';

class UpdateAlbumCover {
  final AlbumRepository repository;

  UpdateAlbumCover(this.repository);

  Future<void> call(int albumId, String? coverPath) {
    return repository.updateAlbumCover(albumId, coverPath);
  }
}



