import '../repositories/playback_repository.dart';

class EnsureShuffleOffPlayback {
  EnsureShuffleOffPlayback(this._repository);
  final PlaybackRepository _repository;

  Future<void> call() => _repository.ensureShuffleOff();
}
