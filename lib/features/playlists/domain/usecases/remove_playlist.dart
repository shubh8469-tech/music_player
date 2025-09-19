import '../repositories/playlist_repository.dart';

class DeletePlaylist {
  final PlaylistRepository repository;
  DeletePlaylist(this.repository);

  Future<void> call(int id) async {
    await repository.deletePlaylist(id);
  }
}
