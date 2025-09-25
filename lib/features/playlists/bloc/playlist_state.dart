part of 'playlist_bloc.dart';

@freezed
class PlaylistState with _$PlaylistState {
  const factory PlaylistState.initial() = _Initial;
  const factory PlaylistState.loading() = _Loading;
  const factory PlaylistState.loaded(
    List<Playlist> playlists, {
    Map<String, List<SongsModel>>? systemPlaylistSongs,
  }) = _Loaded;
  const factory PlaylistState.error(String message) = _Error;
}
