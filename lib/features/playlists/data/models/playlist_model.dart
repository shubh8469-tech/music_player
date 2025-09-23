import '../../domain/entities/playlist.dart';

class PlaylistModel extends Playlist {
  PlaylistModel({
    super.id,
    required super.name,
    required super.songCount,
    required super.createdTime,
    required super.updatedTime,
    super.isSystem,
    super.systemKey,
  });

  factory PlaylistModel.fromMap(Map<String, dynamic> map) {
    return PlaylistModel(
      id: map['id'] as int,
      name: map['name'] as String,
      songCount: map['song_count'],
      createdTime: DateTime.parse(map['created_time']),
      updatedTime: DateTime.parse(map['updated_time']),
      isSystem: (map['is_system'] ?? 0) == 1,
      systemKey: map['system_key'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'song_count': songCount,
      'created_time': createdTime.toIso8601String(),
      'updated_time': updatedTime.toIso8601String(),
      'is_system': (isSystem ?? false) ? 1 : 0,
      'system_key': systemKey,
    };
  }
}
