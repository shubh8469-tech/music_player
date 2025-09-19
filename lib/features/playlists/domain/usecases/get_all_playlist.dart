import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';

class FetchAllPlaylists {
  final PlaylistRepository repository;
  FetchAllPlaylists(this.repository);

  Future<List<Playlist>> call() async {
    return await repository.fetchAllPlaylists();
  }
}
