import '../repositories/playback_repository.dart';

class NextPlayback {
  NextPlayback(this._repository);
  final PlaybackRepository _repository;

  Future<void> call() => _repository.next();
}
