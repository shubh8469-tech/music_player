import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../songs/domain/entities/song.dart';
import '../domain/entities/folder.dart';
import '../domain/usecases/get_all_folders.dart';
import '../domain/usecases/get_folder_songs.dart';
import '../domain/usecases/delete_folder.dart';

part 'folder_event.dart';
part 'folder_state.dart';
part 'folder_bloc.freezed.dart';

class FolderBloc extends Bloc<FolderEvent, FolderState> {
  final GetAllFolders getAllFolders;
  final GetFolderSongs getFolderSongs;
  final DeleteFolder deleteFolder;

  FolderBloc({
    required this.getAllFolders,
    required this.getFolderSongs,
    required this.deleteFolder,
  }) : super(const FolderState.initial()) {
    on<_FetchAllFolders>((event, emit) async {
      try {
        log('Fetching all folders');
        emit(const FolderState.loading());
        final folders = await getAllFolders();
        emit(FolderState.loaded(folders));
      } catch (e) {
        log('Error fetching folders: $e');
        emit(FolderState.error(e.toString()));
      }
    });

    on<_FetchSongsForFolder>((event, emit) async {
      try {
        final currentState = state;
        if (currentState is _Loaded) {
          final songs = await getFolderSongs(event.folderId);
          final updatedSongsMap = Map<int, List<Song>>.from(
            currentState.folderSongs ?? {},
          );
          updatedSongsMap[event.folderId] = songs;
          emit(
            FolderState.loaded(
              currentState.folders,
              folderSongs: updatedSongsMap,
            ),
          );
        }
      } catch (e) {
        log('Error fetching folder songs: $e');
        emit(FolderState.error(e.toString()));
      }
    });

    on<_DeleteFolder>((event, emit) async {
      try {
        final currentState = state;
        if (currentState is _Loaded) {
          await deleteFolder(event.folderId);
          // Remove the deleted folder from the current list
          final updatedFolders = currentState.folders
              .where((folder) => folder.id != event.folderId)
              .toList();
          emit(
            FolderState.loaded(
              updatedFolders,
              folderSongs: currentState.folderSongs,
            ),
          );
        }
      } catch (e) {
        log('Error deleting folder: $e');
        emit(FolderState.error(e.toString()));
      }
    });
  }
}
