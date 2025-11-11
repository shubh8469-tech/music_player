import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

class GetHiddenFolders {
  final FolderRepository repository;

  GetHiddenFolders(this.repository);

  Future<List<Folder>> call() async {
    return await repository.getHiddenFolders();
  }
}


