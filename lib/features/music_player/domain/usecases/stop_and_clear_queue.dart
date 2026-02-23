import '../repositories/playback_repository.dart';

class StopAndClearQueue {
  StopAndClearQueue(this._repository);
  final PlaybackRepository _repository;

  Future<void> call() => _repository.stopAndClearQueue();
}
