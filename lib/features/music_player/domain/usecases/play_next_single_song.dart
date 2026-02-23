import 'package:music_app/features/songs/domain/entities/song.dart';
import '../repositories/playback_repository.dart';

class PlayNextSingleSong {
  PlayNextSingleSong(this._repository);
  final PlaybackRepository _repository;

  Future<bool> call(Song song) => _repository.playNextSingleSong(song);
}
