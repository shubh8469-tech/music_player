import '../repositories/playback_repository.dart';

class ToggleShufflePlayback {
  ToggleShufflePlayback(this._repository);
  final PlaybackRepository _repository;

  Future<void> call() => _repository.toggleShuffle();
}
