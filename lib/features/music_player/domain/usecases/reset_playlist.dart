import 'package:music_app/features/songs/domain/entities/song.dart';
import '../repositories/playback_repository.dart';

class ResetPlaylist {
  ResetPlaylist(this._repository);
  final PlaybackRepository _repository;

  Future<void> call(List<Song> songs) => _repository.resetPlaylist(songs);
}
