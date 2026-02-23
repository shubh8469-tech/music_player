part of 'folder_bloc.dart';

@freezed
class FolderState with _$FolderState {
  const factory FolderState.initial() = _Initial;
  const factory FolderState.loading() = _Loading;
  const factory FolderState.loaded(
    List<Folder> folders, {
    Map<int, List<Song>>? folderSongs,
  }) = _Loaded;
  const factory FolderState.error(String message) = _Error;
}
