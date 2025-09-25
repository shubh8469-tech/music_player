import 'dart:developer';

import 'package:music_app/features/songs/data/models/song_model.dart';

import '../../domain/entities/playlist.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../dataSource/playlist_local_data_source.dart';
import '../models/playlist_model.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final PlaylistLocalDataSource localDataSource;

  PlaylistRepositoryImpl(this.localDataSource);

  @override
  Future<void> addPlaylist(String name) async {
    final playlist = PlaylistModel(
      name: name,
      createdTime: DateTime.now(),
      updatedTime: DateTime.now(),
      songCount: 0,
    );
    await localDataSource.insertPlaylist(playlist);
  }

  @override
  Future<List<Playlist>> fetchAllPlaylists() async {
    final userPlaylists = await localDataSource.getAllPlaylists();
    final systemPlaylists = await localDataSource
        .getSystemPlaylistsWithCounts();
    return [...systemPlaylists, ...userPlaylists];
  }

  @override
  Future<void> deletePlaylist(int id) async {
    await localDataSource.deletePlaylist(id);
  }

  /// 🎵 Playlist songs handling
  @override
  Future<void> addSongToPlaylist(int playlistId, int songId, int position) {
    log('Adding song $songId to playlist $playlistId at position $position');
    return localDataSource.addSongToPlaylist(playlistId, songId, position);
  }

  @override
  Future<void> removeSongFromPlaylist(int playlistId, int songId) {
    return localDataSource.removeSongFromPlaylist(playlistId, songId);
  }

  @override
  Future<List<SongsModel>> getSongsForPlaylist(int playlistId) {
    return localDataSource.getSongsForPlaylist(playlistId);
  }

  @override
  Future<List<SongsModel>> getSongsForSystemPlaylist(String systemKey) {
    return localDataSource.getSongsForSystemPlaylist(systemKey);
  }

  @override
  Future<void> reorderPlaylistSongs(int playlistId, List<int> songIdsInOrder) {
    return localDataSource.reorderPlaylistSongs(playlistId, songIdsInOrder);
  }
}
