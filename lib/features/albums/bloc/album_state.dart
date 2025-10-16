part of 'album_bloc.dart';

@freezed
class AlbumState with _$AlbumState {
  const factory AlbumState.initial() = _Initial;
  const factory AlbumState.loading() = _Loading;
  const factory AlbumState.loaded(
    List<Album> albums, {
    Map<int, List<Song>>? albumSongs,
  }) = _Loaded;
  const factory AlbumState.error(String message) = _Error;
}
