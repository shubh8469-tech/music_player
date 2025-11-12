import 'package:music_app/features/songs/data/models/song_model.dart';

import '../entities/playlist.dart';

abstract class PlaylistRepository {
  Future<void> addPlaylist(String name);
  Future<List<Playlist>> fetchAllPlaylists();
  Future<void> deletePlaylist(int id);
  Future<void> renamePlaylist(int id, String newName);

  /// 🎵 Playlist songs
  Future<void> addSongToPlaylist(int playlistId, int songId, int position);
  Future<void> addMultipleSongsToPlaylist(int playlistId, List<int> songIds);
  Future<void> removeSongFromPlaylist(int playlistId, int songId);
  Future<void> removeMultipleSongsFromPlaylist(
    int playlistId,
    List<int> songIds,
  );
  Future<void> removeSongFromAllPlaylists(int songId);
  Future<List<SongsModel>> getSongsForPlaylist(int playlistId);
  Future<List<SongsModel>> getSongsForSystemPlaylist(String systemKey);
  Future<void> reorderPlaylistSongs(int playlistId, List<int> songIdsInOrder);
}
