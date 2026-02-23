import '../repositories/playback_repository.dart';

class ReorderSongInQueue {
  ReorderSongInQueue(this._repository);
  final PlaybackRepository _repository;

  Future<void> call(int oldIndex, int newIndex) =>
      _repository.reorderSongInQueue(oldIndex, newIndex);
}
