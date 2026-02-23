import '../entities/playback_state.dart';
import '../repositories/playback_repository.dart';

class GetPlaybackStateStream {
  GetPlaybackStateStream(this._repository);
  final PlaybackRepository _repository;

  Stream<PlaybackState> call() => _repository.playbackStateStream;
}
