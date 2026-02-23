import 'package:music_app/features/songs/domain/entities/song.dart';
import '../repositories/playback_repository.dart';

class UpdateSongsListPlayback {
  UpdateSongsListPlayback(this._repository);
  final PlaybackRepository _repository;

  void call(List<Song> newSongs) => _repository.updateSongsList(newSongs);
}
