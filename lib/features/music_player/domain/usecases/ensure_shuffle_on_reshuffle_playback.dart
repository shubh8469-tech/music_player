import '../repositories/playback_repository.dart';

class EnsureShuffleOnAndReshufflePlayback {
  EnsureShuffleOnAndReshufflePlayback(this._repository);
  final PlaybackRepository _repository;

  Future<void> call() => _repository.ensureShuffleOnAndReshuffle();
}
