import 'package:music_app/features/songs/domain/entities/song.dart';
import '../repositories/playback_repository.dart';

class SetPlaylist {
  SetPlaylist(this._repository);
  final PlaybackRepository _repository;

  Future<void> call(
    List<Song> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  }) =>
      _repository.setPlaylist(songs, startIndex: startIndex, autoPlay: autoPlay);
}
