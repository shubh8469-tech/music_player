import '../repositories/folder_repository.dart';

class DeleteFolder {
  final FolderRepository repository;

  DeleteFolder(this.repository);

  Future<int> call(int folderId) async {
    return await repository.removeFolder(folderId);
  }
}
