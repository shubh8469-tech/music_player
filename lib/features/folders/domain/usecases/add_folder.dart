import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

class AddFolder {
  final FolderRepository repository;

  AddFolder(this.repository);

  Future<int> call(Folder folder) async {
    return await repository.addFolder(folder);
  }
}
