import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../songs/domain/entities/song.dart';
import '../../domain/entities/artist.dart';
import '../../domain/usecases/get_all_artists.dart';
import '../../domain/usecases/get_artist_songs.dart';
import '../../domain/usecases/update_artist_cover.dart';
import '../../domain/usecases/update_artist_name.dart';

part 'artist_event.dart';
part 'artist_state.dart';
part 'artist_bloc.freezed.dart';

class ArtistBloc extends Bloc<ArtistEvent, ArtistState> {
  final GetAllArtists getAllArtists;
  final GetArtistSongs getArtistSongs;
  final UpdateArtistCover updateArtistCoverUseCase;
  final UpdateArtistName updateArtistNameUseCase;

  ArtistBloc({
    required this.getAllArtists,
    required this.getArtistSongs,
    required this.updateArtistCoverUseCase,
    required this.updateArtistNameUseCase,
  })
    : super(const ArtistState.initial()) {
    on<_FetchAllArtists>((event, emit) async {
      try {
        log('Fetching all artists');
        emit(const ArtistState.loading());
        final artists = await getAllArtists();
        emit(ArtistState.loaded(artists));
      } catch (e) {
        log('Error fetching artists: $e');
        emit(ArtistState.error(e.toString()));
      }
    });

    on<_FetchSongsForArtist>((event, emit) async {
      try {
        final currentState = state;
        if (currentState is _Loaded) {
          final songs = await getArtistSongs(event.artistId);
          final updatedSongsMap = Map<int, List<Song>>.from(
            currentState.artistSongs ?? {},
          );
          updatedSongsMap[event.artistId] = songs;
          emit(
            ArtistState.loaded(
              currentState.artists,
              artistSongs: updatedSongsMap,
            ),
          );
        }
      } catch (e) {
        log('Error fetching artist songs: $e');
        emit(ArtistState.error(e.toString()));
      }
    });

    on<_SortArtists>((event, emit) async {
      try {
        final currentState = state;
        if (currentState is _Loaded) {
          List<Artist> sortedArtists = List.from(currentState.artists);
          final isAscending = event.order == 0;

          switch (event.sortIndex) {
            case 0: // Artist Name
              sortedArtists.sort(
                (a, b) => isAscending
                    ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
                    : b.name.toLowerCase().compareTo(a.name.toLowerCase()),
              );
              break;
            case 1: // Song Count
              sortedArtists.sort(
                (a, b) => isAscending
                    ? a.songCount.compareTo(b.songCount)
                    : b.songCount.compareTo(a.songCount),
              );
              break;
            case 2: // Album Count
              sortedArtists.sort(
                (a, b) => isAscending
                    ? a.albumCount.compareTo(b.albumCount)
                    : b.albumCount.compareTo(a.albumCount),
              );
              break;
            case 3: // Random
              sortedArtists.shuffle();
              break;
          }

          emit(
            ArtistState.loaded(
              sortedArtists,
              artistSongs: currentState.artistSongs,
            ),
          );
        }
      } catch (e) {
        log('Error sorting artists: $e');
        emit(ArtistState.error(e.toString()));
      }
    });

    on<_UpdateArtistCover>((event, emit) async {
      try {
        await updateArtistCoverUseCase(event.artistId, event.coverPath);
        final currentState = state;
        if (currentState is _Loaded) {
          final updatedArtists = currentState.artists.map((artist) {
            if (artist.id == event.artistId) {
              return Artist(
                id: artist.id,
                name: artist.name,
                songCount: artist.songCount,
                albumCount: artist.albumCount,
                artworkPath: event.coverPath,
                createdTime: artist.createdTime,
                updatedTime: DateTime.now(),
              );
            }
            return artist;
          }).toList();

          emit(
            ArtistState.loaded(
              updatedArtists,
              artistSongs: currentState.artistSongs,
            ),
          );
        }
      } catch (e) {
        log('Error updating artist cover: $e');
      }
    });

    on<_UpdateArtistName>((event, emit) async {
      try {
        await updateArtistNameUseCase(event.artistId, event.newName);
        final currentState = state;
        if (currentState is _Loaded) {
          final updatedArtists = currentState.artists.map((artist) {
            if (artist.id == event.artistId) {
              return Artist(
                id: artist.id,
                name: event.newName,
                songCount: artist.songCount,
                albumCount: artist.albumCount,
                artworkPath: artist.artworkPath,
                createdTime: artist.createdTime,
                updatedTime: DateTime.now(),
              );
            }
            return artist;
          }).toList();

          emit(
            ArtistState.loaded(
              updatedArtists,
              artistSongs: currentState.artistSongs,
            ),
          );
        }
      } catch (e) {
        log('Error updating artist name: $e');
      }
    });
  }
}
