import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';

import '../data/dataSource/song_local_data_source.dart';

part 'songs_event.dart';
part 'songs_state.dart';
part 'songs_bloc.freezed.dart';

class SongsBloc extends Bloc<SongsEvent, SongsState> {

  final SongLocalDataSource localDataSource;

  SongsBloc(this.localDataSource) : super(const SongsState.initial()) {

    on<_AddSong>((event, emit) async {
      try {
        emit(const SongsState.loading());
        await localDataSource.insertSong(event.song);
        final songs = await localDataSource.getAllSongs();
        emit(SongsState.loaded(songs));
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

    on<_GetAllSongs>((event, emit) async {
      try {
        emit(const SongsState.loading());
        final songs = await localDataSource.getAllSongs();
        emit(SongsState.loaded(songs));
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

    on<_RemoveSong>((event, emit) async {
      try {
        emit(const SongsState.loading());
        await localDataSource.deleteSong(event.id);
        final songs = await localDataSource.getAllSongs();
        emit(SongsState.loaded(songs));
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

  }
}
