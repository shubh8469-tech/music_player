import '../repositories/folder_repository.dart';

class AddSongToFolder {
  final FolderRepository repository;

  AddSongToFolder(this.repository);

  Future<void> call(int folderId, int songId) async {
    return await repository.addSongToFolder(folderId, songId);
  }
}
