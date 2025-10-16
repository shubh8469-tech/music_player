import '../../domain/entities/artist.dart';

class ArtistModel extends Artist {
  ArtistModel({
    super.id,
    required super.name,
    required super.songCount,
    required super.albumCount,
    super.artworkPath,
    required super.createdTime,
    required super.updatedTime,
  });

  factory ArtistModel.fromMap(Map<String, dynamic> map) {
    return ArtistModel(
      id: map['id'] as int,
      name: map['name'] as String,
      songCount: map['song_count'] as int,
      albumCount: map['album_count'] as int,
      artworkPath: map['artwork_path'] as String?,
      createdTime: DateTime.parse(map['created_time']),
      updatedTime: DateTime.parse(map['updated_time']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'song_count': songCount,
      'album_count': albumCount,
      'artwork_path': artworkPath,
      'created_time': createdTime.toIso8601String(),
      'updated_time': updatedTime.toIso8601String(),
    };
  }
}
