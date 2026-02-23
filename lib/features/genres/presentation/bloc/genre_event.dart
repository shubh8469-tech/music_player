part of 'genre_bloc.dart';

@freezed
class GenreEvent with _$GenreEvent {
  const factory GenreEvent.fetchAllGenres() = _FetchAllGenres;
  const factory GenreEvent.fetchSongsForGenre(int genreId) =
      _FetchSongsForGenre;
  const factory GenreEvent.sortGenres(int sortIndex, int order) = _SortGenres;
  const factory GenreEvent.updateGenreCover(int genreId, String coverPath) =
      _UpdateGenreCover;
  const factory GenreEvent.updateGenreName(int genreId, String newName) =
      _UpdateGenreName;
}

