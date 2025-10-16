import '../../../songs/domain/entities/song.dart';
import '../repositories/folder_repository.dart';

class GetFolderSongs {
  final FolderRepository repository;

  GetFolderSongs(this.repository);

  Future<List<Song>> call(int folderId) async {
    return await repository.getSongsForFolder(folderId);
  }
}
