import '../repositories/playback_repository.dart';

class RemoveFromQueueAtIndex {
  RemoveFromQueueAtIndex(this._repository);
  final PlaybackRepository _repository;

  Future<void> call(int removeIndex, int newCurrentIndex) =>
      _repository.removeFromQueueAtIndex(removeIndex, newCurrentIndex);
}
