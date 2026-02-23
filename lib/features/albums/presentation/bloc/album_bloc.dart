import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../songs/domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../../domain/usecases/get_all_albums.dart';
import '../../domain/usecases/get_album_songs.dart';
import '../../domain/usecases/get_albums_by_artist.dart';
import '../../domain/usecases/update_album_cover.dart';
import '../../domain/usecases/update_album_name.dart';

part 'album_event.dart';
part 'album_state.dart';
part 'album_bloc.freezed.dart';

class AlbumBloc extends Bloc<AlbumEvent, AlbumState> {
  final GetAllAlbums getAllAlbums;
  final GetAlbumSongs getAlbumSongs;
  final GetAlbumsByArtist getAlbumsByArtist;
  final UpdateAlbumCover updateAlbumCoverUseCase;
  final UpdateAlbumName updateAlbumNameUseCase;

  AlbumBloc({
    required this.getAllAlbums,
    required this.getAlbumSongs,
    required this.getAlbumsByArtist,
    required this.updateAlbumCoverUseCase,
    required this.updateAlbumNameUseCase,
  }) : super(const AlbumState.initial()) {
    on<_FetchAllAlbums>((event, emit) async {
      try {
        log('Fetching all albums');
        emit(const AlbumState.loading());
        final albums = await getAllAlbums();
        emit(AlbumState.loaded(albums));
      } catch (e) {
        log('Error fetching albums: $e');
        emit(AlbumState.error(e.toString()));
      }
    });

    on<_FetchSongsForAlbum>((event, emit) async {
      try {
        final currentState = state;
        if (currentState is _Loaded) {
          final songs = await getAlbumSongs(event.albumId);
          final updatedSongsMap = Map<int, List<Song>>.from(
            currentState.albumSongs ?? {},
          );
          updatedSongsMap[event.albumId] = songs;
          emit(
            AlbumState.loaded(currentState.albums, albumSongs: updatedSongsMap),
          );
        }
      } catch (e) {
        log('Error fetching album songs: $e');
        emit(AlbumState.error(e.toString()));
      }
    });

    on<_FetchAlbumsByArtist>((event, emit) async {
      try {
        log('Fetching albums for artist: ${event.artistName}');
        emit(const AlbumState.loading());
        final albums = await getAlbumsByArtist(event.artistName);
        emit(AlbumState.loaded(albums));
      } catch (e) {
        log('Error fetching albums by artist: $e');
        emit(AlbumState.error(e.toString()));
      }
    });

    on<_SortAlbums>((event, emit) async {
      try {
        final currentState = state;
        if (currentState is _Loaded) {
          List<Album> sortedAlbums = List.from(currentState.albums);
          final isAscending = event.sortOrder == 0;

          switch (event.sortIndex) {
            case 0: // Album Name
              sortedAlbums.sort(
                (a, b) => isAscending
                    ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
                    : b.name.toLowerCase().compareTo(a.name.toLowerCase()),
              );
              break;
            case 1: // Song Count
              sortedAlbums.sort(
                (a, b) => isAscending
                    ? a.songCount.compareTo(b.songCount)
                    : b.songCount.compareTo(a.songCount),
              );
              break;
            case 2: // Year
              sortedAlbums.sort((a, b) {
                final aYear = a.year ?? 0;
                final bYear = b.year ?? 0;
                return isAscending
                    ? aYear.compareTo(bYear)
                    : bYear.compareTo(aYear);
              });
              break;
            case 3: // Random
              sortedAlbums.shuffle();
              break;
          }

          emit(
            AlbumState.loaded(
              sortedAlbums,
              albumSongs: currentState.albumSongs,
            ),
          );
        }
      } catch (e) {
        log('Error sorting albums: $e');
        emit(AlbumState.error(e.toString()));
      }
    });

    on<_UpdateAlbumCover>((event, emit) async {
      try {
        await updateAlbumCoverUseCase(event.albumId, event.coverPath);
        final currentState = state;
        if (currentState is _Loaded) {
          final updatedAlbums = currentState.albums.map((album) {
            if (album.id == event.albumId) {
              return Album(
                id: album.id,
                name: album.name,
                artist: album.artist,
                songCount: album.songCount,
                year: album.year,
                artworkPath: event.coverPath,
                createdTime: album.createdTime,
                updatedTime: DateTime.now(),
                cachedArtistNames: album.cachedArtistNames,
              );
            }
            return album;
          }).toList();

          emit(
            AlbumState.loaded(
              updatedAlbums,
              albumSongs: currentState.albumSongs,
            ),
          );
        }
      } catch (e) {
        log('Error updating album cover: $e');
      }
    });

    on<_UpdateAlbumName>((event, emit) async {
      try {
        await updateAlbumNameUseCase(event.albumId, event.newName);
        final currentState = state;
        if (currentState is _Loaded) {
          final updatedAlbums = currentState.albums.map((album) {
            if (album.id == event.albumId) {
              return Album(
                id: album.id,
                name: event.newName,
                artist: album.artist,
                songCount: album.songCount,
                year: album.year,
                artworkPath: album.artworkPath,
                createdTime: album.createdTime,
                updatedTime: DateTime.now(),
                cachedArtistNames: album.cachedArtistNames,
              );
            }
            return album;
          }).toList();

          emit(
            AlbumState.loaded(
              updatedAlbums,
              albumSongs: currentState.albumSongs,
            ),
          );
        }
      } catch (e) {
        log('Error updating album name: $e');
      }
    });
  }
}
