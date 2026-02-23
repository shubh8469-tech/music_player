import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../songs/domain/entities/song.dart';
import '../../domain/entities/genre.dart';
import '../../domain/usecases/get_all_genres.dart';
import '../../domain/usecases/get_genre_songs.dart';
import '../../domain/usecases/update_genre_cover.dart';
import '../../domain/usecases/update_genre_name.dart';

part 'genre_event.dart';
part 'genre_state.dart';
part 'genre_bloc.freezed.dart';

class GenreBloc extends Bloc<GenreEvent, GenreState> {
  final GetAllGenres getAllGenres;
  final GetGenreSongs getGenreSongs;
  final UpdateGenreCover updateGenreCoverUseCase;
  final UpdateGenreName updateGenreNameUseCase;

  GenreBloc({
    required this.getAllGenres,
    required this.getGenreSongs,
    required this.updateGenreCoverUseCase,
    required this.updateGenreNameUseCase,
  }) : super(const GenreState.initial()) {
    on<_FetchAllGenres>((event, emit) async {
      try {
        log('Fetching all genres');
        emit(const GenreState.loading());
        final genres = await getAllGenres();

        // Filter out genres that have no songs, so the UI only shows
        // genres with at least one song (matching albums/artists behavior).
        final nonEmptyGenres =
            genres.where((genre) => genre.songCount > 0).toList();

        emit(GenreState.loaded(nonEmptyGenres));
      } catch (e) {
        log('Error fetching genres: $e');
        emit(GenreState.error(e.toString()));
      }
    });

    on<_FetchSongsForGenre>((event, emit) async {
      try {
        final currentState = state;
        if (currentState is _Loaded) {
          final songs = await getGenreSongs(event.genreId);
          final updatedSongsMap = Map<int, List<Song>>.from(
            currentState.genreSongs ?? {},
          );
          updatedSongsMap[event.genreId] = songs;
          emit(
            GenreState.loaded(
              currentState.genres,
              genreSongs: updatedSongsMap,
            ),
          );
        }
      } catch (e) {
        log('Error fetching genre songs: $e');
        emit(GenreState.error(e.toString()));
      }
    });

    on<_SortGenres>((event, emit) async {
      try {
        final currentState = state;
        if (currentState is _Loaded) {
          List<Genre> sortedGenres = List.from(currentState.genres);
          final isAscending = event.order == 0;

          switch (event.sortIndex) {
            case 0: // Genre Name
              sortedGenres.sort(
                (a, b) => isAscending
                    ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
                    : b.name.toLowerCase().compareTo(a.name.toLowerCase()),
              );
              break;
            case 1: // Song Count
              sortedGenres.sort(
                (a, b) => isAscending
                    ? a.songCount.compareTo(b.songCount)
                    : b.songCount.compareTo(a.songCount),
              );
              break;
            case 2: // Random
              sortedGenres.shuffle();
              break;
          }

          emit(
            GenreState.loaded(
              sortedGenres,
              genreSongs: currentState.genreSongs,
            ),
          );
        }
      } catch (e) {
        log('Error sorting genres: $e');
        emit(GenreState.error(e.toString()));
      }
    });

    on<_UpdateGenreCover>((event, emit) async {
      try {
        await updateGenreCoverUseCase(event.genreId, event.coverPath);
        final currentState = state;
        if (currentState is _Loaded) {
          final updatedGenres = currentState.genres.map((genre) {
            if (genre.id == event.genreId) {
              return Genre(
                id: genre.id,
                name: genre.name,
                songCount: genre.songCount,
                artworkPath: event.coverPath,
                createdTime: genre.createdTime,
                updatedTime: DateTime.now(),
              );
            }
            return genre;
          }).toList();

          emit(
            GenreState.loaded(
              updatedGenres,
              genreSongs: currentState.genreSongs,
            ),
          );
        }
      } catch (e) {
        log('Error updating genre cover: $e');
      }
    });

    on<_UpdateGenreName>((event, emit) async {
      try {
        await updateGenreNameUseCase(event.genreId, event.newName);
        final currentState = state;
        if (currentState is _Loaded) {
          final updatedGenres = currentState.genres.map((genre) {
            if (genre.id == event.genreId) {
              return Genre(
                id: genre.id,
                name: event.newName,
                songCount: genre.songCount,
                artworkPath: genre.artworkPath,
                createdTime: genre.createdTime,
                updatedTime: DateTime.now(),
              );
            }
            return genre;
          }).toList();

          emit(
            GenreState.loaded(
              updatedGenres,
              genreSongs: currentState.genreSongs,
            ),
          );
        }
      } catch (e) {
        log('Error updating genre name: $e');
      }
    });
  }
}

