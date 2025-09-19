import '../repositories/playlist_repository.dart';

class AddPlaylist {
  final PlaylistRepository repository;
  AddPlaylist(this.repository);

  Future<void> call(String name) async {
    await repository.addPlaylist(name);
  }
}
