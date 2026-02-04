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
  final VoidCallback? onLibraryRefresh;

  SongsBloc(
    this.localDataSource,
    this.playlistRepository, {
    this.onLibraryRefresh,
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
        log('hereeeeee---> ');
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

        // Recalculate related entity counts after deletion
        await localDataSource.refreshRelatedEntityCounts();

        // Trigger library refresh to update counts

        final songs = await localDataSource.getAllSongs();
        emit(SongsState.loaded(songs));

        onLibraryRefresh?.call();

      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

    on<_ShuffleSongs>((event, emit) async {
      try {
        emit(SongsState.loaded(event.songs));
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

    on<_UpdateSongFavorite>((event, emit) async {
      try {
        // Get current songs
        final allSongs = await localDataSource.getAllSongs(includeHidden: true);
        final songIndex = allSongs.indexWhere(
          (song) => song.id == event.songId,
        );

        if (songIndex != -1) {
          // Create updated song with new favorite status
          final updatedSong = SongsModel(
            id: allSongs[songIndex].id,
            title: allSongs[songIndex].title,
            artist: allSongs[songIndex].artist,
            album: allSongs[songIndex].album,
            genre: allSongs[songIndex].genre,
            year: allSongs[songIndex].year,
            duration: allSongs[songIndex].duration,
            filePath: allSongs[songIndex].filePath,
            folder: allSongs[songIndex].folder,
            artwork_path: allSongs[songIndex].artwork_path,
            createdTime: allSongs[songIndex].createdTime,
            updatedTime: DateTime.now().toIso8601String(),
            playCount: allSongs[songIndex].playCount,
            lastPlayed: allSongs[songIndex].lastPlayed,
            isFavorite: event.isFavorite,
            isHidden: allSongs[songIndex].isHidden,
          );

          // Update the song in database
          await localDataSource.updateSong(updatedSong);

          final visibleSongs = await localDataSource.getAllSongs();
          emit(SongsState.loaded(visibleSongs));
        }
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

    on<_UpdateSongArtwork>((event, emit) async {
      try {
        final allSongs = await localDataSource.getAllSongs(includeHidden: true);
        final songIndex = allSongs.indexWhere(
          (song) => song.id == event.songId,
        );

        if (songIndex == -1) {
          return;
        }

        final existingSong = allSongs[songIndex];
        final updatedSong = SongsModel(
          id: existingSong.id,
          title: existingSong.title,
          artist: existingSong.artist,
          album: existingSong.album,
          genre: existingSong.genre,
          year: existingSong.year,
          duration: existingSong.duration,
          filePath: existingSong.filePath,
          folder: existingSong.folder,
          artwork_path: event.artworkPath,
          createdTime: existingSong.createdTime,
          updatedTime: DateTime.now().toIso8601String(),
          playCount: existingSong.playCount,
          lastPlayed: existingSong.lastPlayed,
          isFavorite: existingSong.isFavorite,
          isHidden: existingSong.isHidden,
        );

        await localDataSource.updateSong(updatedSong);
        onLibraryRefresh?.call();
        final visibleSongs = await localDataSource.getAllSongs();
        emit(SongsState.loaded(visibleSongs));
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

    on<_UpdateSongDetails>((event, emit) async {
      try {
        emit(const SongsState.loading());

        await localDataSource.updateSongWithRelations(event.song);
        onLibraryRefresh?.call();

        final songs = await localDataSource.getAllSongs();
        emit(SongsState.loaded(songs));
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

    on<_HideSong>((event, emit) async {
      try {
        await localDataSource.updateSongHiddenStatus(event.songId, true);
        onLibraryRefresh?.call();
        final songs = await localDataSource.getAllSongs();
        emit(SongsState.loaded(songs));
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });

    on<_UnhideSong>((event, emit) async {
      try {
        await localDataSource.updateSongHiddenStatus(event.songId, false);
        onLibraryRefresh?.call();
        final songs = await localDataSource.getAllSongs();
        emit(SongsState.loaded(songs));
      } catch (e) {
        emit(SongsState.error(e.toString()));
      }
    });
  }
}
