import '../../../songs/domain/entities/song.dart';
import '../repositories/album_repository.dart';

class GetAlbumSongs {
  final AlbumRepository repository;

  GetAlbumSongs(this.repository);

  Future<List<Song>> call(int albumId) async {
    return await repository.getSongsForAlbum(albumId);
  }
}
