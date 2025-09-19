import '../../domain/entities/playlist.dart';

class PlaylistModel extends Playlist {
  PlaylistModel({
    super.id,
    required super.name,
    required super.songCount,
    required super.createdTime,
    required super.updatedTime,
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] as int,
      name: map['name'] as String,
      songCount: map['song_count'],
      createdTime: DateTime.parse(map['created_time']),
      updatedTime: DateTime.parse(map['updated_time']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'song_count': songCount,
      'created_time': createdTime.toIso8601String(),
      'updated_time': updatedTime.toIso8601String(),
    };
  }
}
