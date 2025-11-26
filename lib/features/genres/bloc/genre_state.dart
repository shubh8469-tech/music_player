part of 'genre_bloc.dart';

@freezed
class GenreState with _$GenreState {
  const factory GenreState.initial() = _Initial;
  const factory GenreState.loading() = _Loading;
  const factory GenreState.loaded(
    List<Genre> genres, {
    Map<int, List<Song>>? genreSongs,
  }) = _Loaded;
  const factory GenreState.error(String message) = _Error;
}

