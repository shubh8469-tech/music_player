part of 'artist_bloc.dart';

@freezed
class ArtistState with _$ArtistState {
  const factory ArtistState.initial() = _Initial;
  const factory ArtistState.loading() = _Loading;
  const factory ArtistState.loaded(
    List<Artist> artists, {
    Map<int, List<Song>>? artistSongs,
  }) = _Loaded;
  const factory ArtistState.error(String message) = _Error;
}
