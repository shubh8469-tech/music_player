part of 'songs_bloc.dart';

@freezed
class SongsEvent with _$SongsEvent {
  const factory SongsEvent.addSong(SongsModel song) = _AddSong;
  const factory SongsEvent.getAllSongs() = _GetAllSongs;
  const factory SongsEvent.removeSong(int id) = _RemoveSong;
}
