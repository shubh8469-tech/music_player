import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';

import '../data/dataSource/song_local_data_source.dart';
import '../../playlists/domain/repositories/playlist_repository.dart';

part 'songs_event.dart';

part 'songs_state.dart';

part 'songs_bloc.freezed.dart';

class SongsBloc extends Bloc<SongsEvent, SongsState> {
  final SongLocalDataSource localDataSource;
  final PlaylistRepository playlistRepository;
  final VoidCallback? onPlaylistRefresh;

  SongsBloc(
    this.localDataSource,
    this.playlistRepository, {
    this.onPlaylistRefresh,
  }) : super(const SongsState.initial()) {
    on<_AddSong>((event, emit) async {
      try {
        emit(const SongsState.loading());
        await localDataSource.insertSong(event.song);
        final songs = await localDataSource.getAllSongs();
        emit(SongsState.loaded(songs));
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

    on<_GetAllSongs>((event, emit) async {
      try {
        emit(const SongsState.loading());
        final songs = await localDataSource.getAllSongs();
        emit(SongsState.loaded(songs));
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

    on<_RemoveSong>((event, emit) async {
      try {
        emit(const SongsState.loading());

        // Remove song from all playlists first
        await playlistRepository.removeSongFromAllPlaylists(event.id);

        // Then remove song from songs table
        await localDataSource.deleteSong(event.id);

        // Trigger playlist refresh to update counts
        onPlaylistRefresh?.call();

        final songs = await localDataSource.getAllSongs();
        emit(SongsState.loaded(songs));
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

    on<_UpdateSongFavorite>((event, emit) async {
      try {
        // Get current songs
        final songs = await localDataSource.getAllSongs();
        final songIndex = songs.indexWhere((song) => song.id == event.songId);

        if (songIndex != -1) {
          // Create updated song with new favorite status
          final updatedSong = SongsModel(
            id: songs[songIndex].id,
            title: songs[songIndex].title,
            artist: songs[songIndex].artist,
            album: songs[songIndex].album,
            genre: songs[songIndex].genre,
            year: songs[songIndex].year,
            duration: songs[songIndex].duration,
            filePath: songs[songIndex].filePath,
            folder: songs[songIndex].folder,
            artwork_path: songs[songIndex].artwork_path,
            createdTime: songs[songIndex].createdTime,
            updatedTime: DateTime.now().toIso8601String(),
            playCount: songs[songIndex].playCount,
            lastPlayed: songs[songIndex].lastPlayed,
            isFavorite: event.isFavorite,
          );

          // Update the song in database
          await localDataSource.updateSong(updatedSong);

          // Update the song in the list
          songs[songIndex] = updatedSong;
          emit(SongsState.loaded(songs));
        }
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

    on<_SortSongs>((event, emit) async {
      try {
        emit(const SongsState.loading());
        final songs = await localDataSource.getAllSongs();

        List<SongsModel> sortedSongs = List.from(songs);
        final isAscending = event.sortOrder == 0;

        switch (event.sortIndex) {
          case 0: // Song Name
            sortedSongs.sort(
              (a, b) => isAscending
                  ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
                  : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
            );
            break;
          case 1: // Artist
            sortedSongs = List.from(songs)
              ..sort((a, b) {
                final aArtist = a.artist == '<unknown>'
                    ? 'zzz'
                    : a.artist.toLowerCase();
                final bArtist = b.artist == '<unknown>'
                    ? 'zzz'
                    : b.artist.toLowerCase();
                return isAscending
                    ? aArtist.toLowerCase().compareTo(bArtist.toLowerCase())
                    : bArtist.toLowerCase().compareTo(aArtist.toLowerCase());
              });
            break;
          case 2: // Album
            sortedSongs.sort(
              (a, b) => isAscending
                  ? a.album.toLowerCase().compareTo(b.album.toLowerCase())
                  : b.album.toLowerCase().compareTo(a.album.toLowerCase()),
            );
            break;
          case 3: // Folder
            sortedSongs.sort(
              (a, b) => isAscending
                  ? a.folder!.toLowerCase().compareTo(b.folder!.toLowerCase())
                  : b.folder!.toLowerCase().compareTo(a.folder!.toLowerCase()),
            );
            break;
          case 4: // Added Time
            sortedSongs.sort(
              (a, b) => isAscending
                  ? a.createdTime.compareTo(b.createdTime)
                  : b.createdTime.compareTo(a.createdTime),
            );
            break;
          case 5: // Play Count
            sortedSongs.sort(
              (a, b) => isAscending
                  ? a.playCount.compareTo(b.playCount)
                  : b.playCount.compareTo(a.playCount),
            );
            break;
          case 6: // Year
            sortedSongs.sort((a, b) {
              final aYear = a.year ?? 0;
              final bYear = b.year ?? 0;
              // Songs without year go to the end
              if (aYear == 0 && bYear == 0) return 0;
              if (aYear == 0) return 1;
              if (bYear == 0) return -1;
              return isAscending
                  ? aYear.compareTo(bYear)
                  : bYear.compareTo(aYear);
            });
            break;
          default:
            break;
        }

        emit(SongsState.loaded(sortedSongs));

        // Optional: log to verify
        log(
          "Songs sorted by ${event.sortIndex} (${isAscending ? 'Ascending' : 'Descending'}):",
        );
        for (var s in sortedSongs) {
          log("----------------------------------");
          log("${s.title} - ${s.artist} - ${s.album}");
          log("${s.folder} - ${s.createdTime} - ${s.playCount}");
          log("Year: ${s.year}");
          log("----------------------------------");
        }
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });
  }
}
