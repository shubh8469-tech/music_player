part of 'artist_bloc.dart';

@freezed
class ArtistEvent with _$ArtistEvent {
  const factory ArtistEvent.fetchAllArtists() = _FetchAllArtists;
  const factory ArtistEvent.fetchSongsForArtist(int artistId) =
      _FetchSongsForArtist;
  const factory ArtistEvent.sortArtists(int sortIndex, int order) = _SortArtists;
  const factory ArtistEvent.updateArtistCover(int artistId, String coverPath) =
      _UpdateArtistCover;
  const factory ArtistEvent.updateArtistName(int artistId, String newName) =
      _UpdateArtistName;
}
