import '../../domain/entities/song.dart';

class SongsModel extends Song {
  final String createdTime;
  final String updatedTime;

  SongsModel({
    int? id,
    required String title,
    required String artist,
    required String album,
    required String genre,
    required String duration,
    required String filePath,
    String? folder,
    String? artwork_path,
    String? createdTime,
    String? updatedTime,
  })  : createdTime = createdTime ?? DateTime.now().toIso8601String(),
        updatedTime = updatedTime ?? DateTime.now().toIso8601String(),
        super(
        id: id,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        duration: duration,
        filePath: filePath,
        folder: folder,
        artwork_path: artwork_path,
      );

  factory SongsModel.fromMap(Map<String, dynamic> map) {
    return SongsModel(
      id: map['id'],
      title: map['title'],
      artist: map['artist'] ?? '',
      album: map['album'] ?? '',
      genre: map['genre'] ?? '',
      duration: map['duration'],
      filePath: map['file_path'],
      folder: map['folder'],
      artwork_path: map['artwork_path'],
      createdTime: map['created_time'],
      updatedTime: map['updated_time'],
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
      'folder': folder,
      'artwork_path': artwork_path,
      'created_time': createdTime,
      'updated_time': updatedTime,
    };
  }
}
