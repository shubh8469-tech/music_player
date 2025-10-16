import '../../../songs/domain/entities/song.dart';
import '../../domain/entities/folder.dart';
import '../../domain/repositories/folder_repository.dart';
import '../dataSource/folder_local_data_source.dart';
import '../models/folder_model.dart';

class FolderRepositoryImpl implements FolderRepository {
  final FolderLocalDataSource localDataSource;

  FolderRepositoryImpl(this.localDataSource);

  @override
  Future<int> addFolder(Folder folder) async {
    final folderModel = FolderModel(
      id: folder.id,
      name: folder.name,
      path: folder.path,
      songCount: folder.songCount,
      artworkPath: folder.artworkPath,
      createdTime: folder.createdTime,
      updatedTime: folder.updatedTime,
    );
    return await localDataSource.insertFolder(folderModel);
  }

  @override
  Future<List<Folder>> getAllFolders() async {
    return await localDataSource.getAllFolders();
  }

  @override
  Future<Folder?> getFolderByName(String name) async {
    return await localDataSource.getFolderByName(name);
  }

  @override
  Future<int> removeFolder(int id) async {
    return await localDataSource.deleteFolder(id);
  }

  @override
  Future<void> addSongToFolder(int folderId, int songId) async {
    return await localDataSource.addSongToFolder(folderId, songId);
  }

  @override
  Future<List<Song>> getSongsForFolder(int folderId) async {
    return await localDataSource.getSongsForFolder(folderId);
  }

  @override
  Future<void> clearAllFolders() async {
    return await localDataSource.clearAllFolders();
  }
}
