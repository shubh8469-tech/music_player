class Folder {
  final int? id;
  final String name;
  final String path;
  final int songCount;
  final String? artworkPath;
  final DateTime createdTime;
  final DateTime updatedTime;

  Folder({
    required this.id,
    required this.name,
    required this.path,
    required this.songCount,
    this.artworkPath,
    required this.createdTime,
    required this.updatedTime,
  });
}
