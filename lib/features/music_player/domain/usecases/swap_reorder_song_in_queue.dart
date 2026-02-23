import '../repositories/playback_repository.dart';

class SwapReorderSongInQueue {
  SwapReorderSongInQueue(this._repository);
  final PlaybackRepository _repository;

  Future<void> call(int oldIndex, int newIndex) =>
      _repository.swapReorderSongInQueue(oldIndex, newIndex);
}
