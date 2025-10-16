import '../entities/folder.dart';
import '../repositories/folder_repository.dart';

class GetAllFolders {
  final FolderRepository repository;

  GetAllFolders(this.repository);

  Future<List<Folder>> call() async {
    return await repository.getAllFolders();
  }
}
