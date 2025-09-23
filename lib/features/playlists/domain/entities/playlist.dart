class Playlist {
  final int? id;
  final String name;
  final int songCount;
  final DateTime createdTime;
  final DateTime updatedTime;
  final bool? isSystem;
  final String? systemKey;

  Playlist({
    required this.id,
    required this.name,
    required this.songCount,
    required this.createdTime,
    required this.updatedTime,
    this.isSystem,
    this.systemKey,
  });
}
