import '../../domain/entities/song.dart';

class SongModel extends Song {
  SongModel({
    int? id,
    required String title,
    required String artist,
    required String album,
    required String genre,
    required int duration,
    required String filePath,
    String? artworkPath,
  }) : super(
    id: id,
    title: title,
    artist: artist,
    album: album,
    genre: genre,
    duration: duration,
    filePath: filePath,
    artworkPath: artworkPath,
  );

  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'],
      title: map['title'],
      artist: map['artist'] ?? '',
      album: map['album'] ?? '',
      genre: map['genre'] ?? '',
      duration: map['duration'],
      filePath: map['file_path'],
      artworkPath: map['artwork_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'duration': duration,
      'file_path': filePath,
      'artwork_path': artworkPath,
    };
  }
}
