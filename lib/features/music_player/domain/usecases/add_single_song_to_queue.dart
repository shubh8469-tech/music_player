import 'package:music_app/features/songs/domain/entities/song.dart';
import '../repositories/playback_repository.dart';

class AddSingleSongToQueue {
  AddSingleSongToQueue(this._repository);
  final PlaybackRepository _repository;

  Future<bool> call(Song song) => _repository.addSingleSongToQueue(song);
}
