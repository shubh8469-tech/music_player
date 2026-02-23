import '../repositories/playback_repository.dart';

class SetPlaybackSpeed {
  SetPlaybackSpeed(this._repository);
  final PlaybackRepository _repository;

  Future<void> call(double speed) => _repository.setPlaybackSpeed(speed);
}
