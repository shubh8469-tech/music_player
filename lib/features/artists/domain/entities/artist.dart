class Artist {
  final int? id;
  final String name;
  final int songCount;
  final int albumCount;
  final String? artworkPath;
  final DateTime createdTime;
  final DateTime updatedTime;

  Artist({
    required this.id,
    required this.name,
    required this.songCount,
    required this.albumCount,
    this.artworkPath,
    required this.createdTime,
    required this.updatedTime,
  });
}
