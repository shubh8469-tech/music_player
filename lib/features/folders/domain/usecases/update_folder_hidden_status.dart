import '../repositories/folder_repository.dart';

class UpdateFolderHiddenStatus {
  final FolderRepository repository;

  UpdateFolderHiddenStatus(this.repository);

  Future<int> call(int folderId, bool isHidden) async {
    return await repository.updateFolderHiddenStatus(folderId, isHidden);
  }
}


