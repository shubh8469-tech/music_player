import '../repositories/playback_repository.dart';

class PausePlayback {
  PausePlayback(this._repository);
  final PlaybackRepository _repository;

  Future<void> call() => _repository.pause();
}
