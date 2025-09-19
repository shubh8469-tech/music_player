part of 'playlist_bloc.dart';

@freezed
class PlaylistEvent with _$PlaylistEvent {
  const factory PlaylistEvent.addPlaylist(String name) = _AddPlaylist;
  const factory PlaylistEvent.addSongToPlaylist(int playlistId, int songId, int position) = _AddSongToPlaylist;
  const factory PlaylistEvent.fetchAllPlaylists() = _FetchAllPlaylists;
  const factory PlaylistEvent.deletePlaylist(int id) = _DeletePlaylist;
}
