import '../repositories/playback_repository.dart';

class PreviousPlayback {
  PreviousPlayback(this._repository);
  final PlaybackRepository _repository;

  Future<void> call() => _repository.previous();
}
