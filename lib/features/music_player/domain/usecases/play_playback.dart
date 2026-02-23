import '../repositories/playback_repository.dart';

class PlayPlayback {
  PlayPlayback(this._repository);
  final PlaybackRepository _repository;

  Future<void> call() => _repository.play();
}
