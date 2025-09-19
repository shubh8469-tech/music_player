import 'package:music_app/features/songs/data/models/song_model.dart';

import '../entities/playlist.dart';

abstract class PlaylistRepository {
  Future<void> addPlaylist(String name);
  Future<List<Playlist>> fetchAllPlaylists();
  Future<void> deletePlaylist(int id);
  /// 🎵 Playlist songs
  Future<void> addSongToPlaylist(int playlistId, int songId, int position);
  Future<void> removeSongFromPlaylist(int playlistId, int songId);
  Future<List<SongsModel>> getSongsForPlaylist(int playlistId);
}