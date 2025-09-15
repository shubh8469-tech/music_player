// add_song.dart
import '../entities/song.dart';
import '../repositories/song_repository.dart';

class AddSong {
  final SongRepository repository;
  AddSong(this.repository);

  Future<void> call(Song song) => repository.addSong(song);
}
