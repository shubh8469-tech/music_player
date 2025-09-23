import '../../domain/entities/song.dart';

class SongsModel extends Song {
  final String createdTime;
  final String updatedTime;
  final int playCount;
  final String? lastPlayed;
  final bool isFavorite;

  SongsModel({
    int? id,
    required String title,
    required String artist,
    required String album,
    required String genre,
    required int duration,
    required String filePath,
    String? folder,
    String? artwork_path,
    String? createdTime,
    String? updatedTime,
    int? playCount,
    String? lastPlayed,
    bool? isFavorite,
  }) : createdTime = createdTime ?? DateTime.now().toIso8601String(),
       updatedTime = updatedTime ?? DateTime.now().toIso8601String(),
       playCount = playCount ?? 0,
       lastPlayed = lastPlayed,
       isFavorite = isFavorite ?? false,
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
      playCount: map['play_count'] ?? 0,
      lastPlayed: map['last_played'],
      isFavorite: (map['is_favorite'] ?? 0) == 1,
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
      'play_count': playCount,
      'last_played': lastPlayed,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }
}
