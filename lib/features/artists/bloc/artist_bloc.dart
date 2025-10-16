import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../songs/domain/entities/song.dart';
import '../domain/entities/artist.dart';
import '../domain/usecases/get_all_artists.dart';
import '../domain/usecases/get_artist_songs.dart';

part 'artist_event.dart';
part 'artist_state.dart';
part 'artist_bloc.freezed.dart';

class ArtistBloc extends Bloc<ArtistEvent, ArtistState> {
  final GetAllArtists getAllArtists;
  final GetArtistSongs getArtistSongs;

  ArtistBloc({required this.getAllArtists, required this.getArtistSongs})
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
  }
}
