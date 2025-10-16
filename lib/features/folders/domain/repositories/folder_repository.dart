import '../../../songs/domain/entities/song.dart';
import '../entities/folder.dart';

abstract class FolderRepository {
  Future<int> addFolder(Folder folder);
  Future<List<Folder>> getAllFolders();
  Future<Folder?> getFolderByName(String name);
  Future<int> removeFolder(int id);
  Future<void> addSongToFolder(int folderId, int songId);
  Future<List<Song>> getSongsForFolder(int folderId);
  Future<void> clearAllFolders();
}
