import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../songs/domain/entities/song.dart';
import '../domain/entities/album.dart';
import '../domain/usecases/get_all_albums.dart';
import '../domain/usecases/get_album_songs.dart';
import '../domain/usecases/get_albums_by_artist.dart';

part 'album_event.dart';
part 'album_state.dart';
part 'album_bloc.freezed.dart';

class AlbumBloc extends Bloc<AlbumEvent, AlbumState> {
  final GetAllAlbums getAllAlbums;
  final GetAlbumSongs getAlbumSongs;
  final GetAlbumsByArtist getAlbumsByArtist;

  AlbumBloc({
    required this.getAllAlbums,
    required this.getAlbumSongs,
    required this.getAlbumsByArtist,
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
  }
}
