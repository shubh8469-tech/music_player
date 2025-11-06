part of 'artist_bloc.dart';

@freezed
class ArtistEvent with _$ArtistEvent {
  const factory ArtistEvent.fetchAllArtists() = _FetchAllArtists;
  const factory ArtistEvent.fetchSongsForArtist(int artistId) =
      _FetchSongsForArtist;
  const factory ArtistEvent.sortArtists(int sortIndex, int order) = _SortArtists;
}
