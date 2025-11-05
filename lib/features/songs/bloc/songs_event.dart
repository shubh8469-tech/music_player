part of 'songs_bloc.dart';

@freezed
class SongsEvent with _$SongsEvent {
  const factory SongsEvent.addSong(SongsModel song) = _AddSong;
  const factory SongsEvent.getAllSongs() = _GetAllSongs;
  const factory SongsEvent.removeSong(int id) = _RemoveSong;
  const factory SongsEvent.shuffleSongs(List<SongsModel> songs) = _ShuffleSongs;
  const factory SongsEvent.updateSongFavorite(int songId, bool isFavorite) =
      _UpdateSongFavorite;
  const factory SongsEvent.sortSongs(
    int sortIndex, [
    @Default(0) int sortOrder,
  ]) = _SortSongs;
}
