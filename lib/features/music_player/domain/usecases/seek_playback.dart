import '../repositories/playback_repository.dart';

class SeekPlayback {
  SeekPlayback(this._repository);
  final PlaybackRepository _repository;

  Future<void> call(Duration position, {int? index}) =>
      _repository.seek(position, index: index);
}
