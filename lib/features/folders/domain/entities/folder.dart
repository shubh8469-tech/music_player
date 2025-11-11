class Folder {
  final int? id;
  final String name;
  final String path;
  final int songCount;
  final String? artworkPath;
  final bool isHidden;
  final DateTime createdTime;
  final DateTime updatedTime;

  Folder({
    required this.id,
    required this.name,
    required this.path,
    required this.songCount,
    this.artworkPath,
    this.isHidden = false,
    required this.createdTime,
    required this.updatedTime,
  });
}
