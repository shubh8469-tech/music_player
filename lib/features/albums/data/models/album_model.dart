import 'dart:convert';

import '../../domain/entities/album.dart';

class AlbumModel extends Album {
  AlbumModel({
    super.id,
    required super.name,
    super.artist,
    required super.songCount,
    super.year,
    super.artworkPath,
    required super.createdTime,
    required super.updatedTime,
    super.cachedArtistNames = const [],
  });

  factory AlbumModel.fromMap(Map<String, dynamic> map) {
    final cachedArtistValue = map['cached_artist_names'] as String?;
    final cachedArtists = (cachedArtistValue == null || cachedArtistValue.isEmpty)
        ? <String>[]
        : List<String>.from(jsonDecode(cachedArtistValue) as List);
    return AlbumModel(
      id: map['id'] as int,
      name: map['name'] as String,
      artist: map['artist'] as String?,
      songCount: map['song_count'] as int,
      year: map['year'] as int?,
      artworkPath: map['artwork_path'] as String?,
      createdTime: DateTime.parse(map['created_time']),
      updatedTime: DateTime.parse(map['updated_time']),
      cachedArtistNames: cachedArtists,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'song_count': songCount,
      'year': year,
      'artwork_path': artworkPath,
      'cached_artist_names':
          cachedArtistNames.isEmpty ? null : jsonEncode(cachedArtistNames),
      'created_time': createdTime.toIso8601String(),
      'updated_time': updatedTime.toIso8601String(),
    };
  }
}
