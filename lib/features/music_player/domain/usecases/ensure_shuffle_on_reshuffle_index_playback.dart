import '../repositories/playback_repository.dart';

class EnsureShuffleOnReshuffleIndexPlayback {
  EnsureShuffleOnReshuffleIndexPlayback(this._repository);
  final PlaybackRepository _repository;

  Future<void> call() =>
      _repository.ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();
}
