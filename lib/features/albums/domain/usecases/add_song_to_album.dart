import '../repositories/album_repository.dart';

class AddSongToAlbum {
  final AlbumRepository repository;

  AddSongToAlbum(this.repository);

  Future<void> call(int albumId, int songId) async {
    return await repository.addSongToAlbum(albumId, songId);
  }
}
