class Genre {
  final int? id;
  final String name;
  final int songCount;
  final String? artworkPath;
  final DateTime createdTime;
  final DateTime updatedTime;

  Genre({
    required this.id,
    required this.name,
    required this.songCount,
    this.artworkPath,
    required this.createdTime,
    required this.updatedTime,
  });
}

