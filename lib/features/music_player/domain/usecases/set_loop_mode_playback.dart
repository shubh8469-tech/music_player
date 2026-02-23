import '../entities/playback_loop_mode.dart';
import '../repositories/playback_repository.dart';

class SetLoopModePlayback {
  SetLoopModePlayback(this._repository);
  final PlaybackRepository _repository;

  Future<void> call(PlaybackLoopMode mode) => _repository.setLoopMode(mode);
}
