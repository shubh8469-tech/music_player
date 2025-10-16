import '../../domain/entities/folder.dart';

class FolderModel extends Folder {
  FolderModel({
    super.id,
    required super.name,
    required super.path,
    required super.songCount,
    super.artworkPath,
    required super.createdTime,
    required super.updatedTime,
  });

  factory FolderModel.fromMap(Map<String, dynamic> map) {
    return FolderModel(
      id: map['id'] as int,
      name: map['name'] as String,
      path: map['path'] as String,
      songCount: map['song_count'] as int,
      artworkPath: map['artwork_path'] as String?,
      createdTime: DateTime.parse(map['created_time']),
      updatedTime: DateTime.parse(map['updated_time']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'song_count': songCount,
      'artwork_path': artworkPath,
      'created_time': createdTime.toIso8601String(),
      'updated_time': updatedTime.toIso8601String(),
    };
  }
}
