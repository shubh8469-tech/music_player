import 'package:music_app/features/songs/domain/entities/song.dart';
import '../repositories/playback_repository.dart';

class PlayNextMultipleSongs {
  PlayNextMultipleSongs(this._repository);
  final PlaybackRepository _repository;

  Future<int> call(List<Song> nextSongs) =>
      _repository.playNextMultipleSongs(nextSongs);
}
