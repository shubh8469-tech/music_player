part of 'album_bloc.dart';

@freezed
class AlbumEvent with _$AlbumEvent {
  const factory AlbumEvent.fetchAllAlbums() = _FetchAllAlbums;
  const factory AlbumEvent.fetchSongsForAlbum(int albumId) =
      _FetchSongsForAlbum;
  const factory AlbumEvent.fetchAlbumsByArtist(String artistName) =
      _FetchAlbumsByArtist;
  const factory AlbumEvent.sortAlbums(int sortIndex, int sortOrder) =
      _SortAlbums;
  const factory AlbumEvent.updateAlbumCover(int albumId, String coverPath) =
      _UpdateAlbumCover;
  const factory AlbumEvent.updateAlbumName(int albumId, String newName) =
      _UpdateAlbumName;
}
