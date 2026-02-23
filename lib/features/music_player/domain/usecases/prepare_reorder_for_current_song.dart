import '../repositories/playback_repository.dart';

class PrepareReorderForCurrentSong {
  PrepareReorderForCurrentSong(this._repository);
  final PlaybackRepository _repository;

  void call(int oldIndex, int newIndex) =>
      _repository.prepareReorderForCurrentSong(oldIndex, newIndex);
}
