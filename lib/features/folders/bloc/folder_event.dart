part of 'folder_bloc.dart';

@freezed
class FolderEvent with _$FolderEvent {
  const factory FolderEvent.fetchAllFolders() = _FetchAllFolders;
  const factory FolderEvent.fetchSongsForFolder(int folderId) =
      _FetchSongsForFolder;
}
