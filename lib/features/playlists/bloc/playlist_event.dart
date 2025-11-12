part of 'playlist_bloc.dart';

@freezed
class PlaylistEvent with _$PlaylistEvent {
  const factory PlaylistEvent.addPlaylist(String name) = _AddPlaylist;
  const factory PlaylistEvent.addSongToPlaylist(
    int playlistId,
    int songId,
    int position,
  ) = _AddSongToPlaylist;
  const factory PlaylistEvent.addMultipleSongsToPlaylist(
    int playlistId,
    List<int> songIds,
  ) = _AddMultipleSongsToPlaylist;
  const factory PlaylistEvent.removeSongFromPlaylist(
    int playlistId,
    int songId,
  ) = _RemoveSongFromPlaylist;
  const factory PlaylistEvent.removeMultipleSongsFromPlaylist(
    int playlistId,
    List<int> songIds,
  ) = _RemoveMultipleSongsFromPlaylist;
  const factory PlaylistEvent.fetchAllPlaylists() = _FetchAllPlaylists;
  const factory PlaylistEvent.refreshPlaylists() = _RefreshPlaylists;
  const factory PlaylistEvent.deletePlaylist(int id) = _DeletePlaylist;
  const factory PlaylistEvent.renamePlaylist(int id, String newName) =
      _RenamePlaylist;
  const factory PlaylistEvent.fetchSongsForSystemPlaylist(String systemKey) =
      _FetchSongsForSystemPlaylist;
  const factory PlaylistEvent.getFavoritesPlaylistId() =
      _GetFavoritesPlaylistId;
}
