part of 'home_bloc.dart';

@freezed
class HomeState with _$HomeState {
  const factory HomeState.initial() = _Initial;
  const factory HomeState.loading() = _Loading;
  const factory HomeState.loaded({
    required List<SongsModel> recentlyPlayedSongs,
    required List<Playlist> userPlaylists,
    required List<Playlist> systemPlaylists,
  }) = _Loaded;
  const factory HomeState.error(String message) = _Error;
}
