import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../songs/domain/entities/song.dart';
import '../domain/entities/folder.dart';
import '../domain/usecases/get_all_folders.dart';
import '../domain/usecases/get_folder_songs.dart';

part 'folder_event.dart';
part 'folder_state.dart';
part 'folder_bloc.freezed.dart';

class FolderBloc extends Bloc<FolderEvent, FolderState> {
  final GetAllFolders getAllFolders;
  final GetFolderSongs getFolderSongs;

  FolderBloc({required this.getAllFolders, required this.getFolderSongs})
    : super(const FolderState.initial()) {
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
  }
}
