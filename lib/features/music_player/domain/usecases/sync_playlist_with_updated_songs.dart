import 'package:music_app/features/songs/domain/entities/song.dart';
import '../repositories/playback_repository.dart';

class SyncPlaylistWithUpdatedSongs {
  SyncPlaylistWithUpdatedSongs(this._repository);
  final PlaybackRepository _repository;

  void call(List<Song> updatedSongs) =>
      _repository.syncPlaylistWithUpdatedSongs(updatedSongs);
}
