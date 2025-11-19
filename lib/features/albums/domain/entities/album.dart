class Album {
  final int? id;
  final String name;
  final String? artist;
  final int songCount;
  final int? year;
  final String? artworkPath;
  final DateTime createdTime;
  final DateTime updatedTime;
  final List<String> cachedArtistNames;

  Album({
    required this.id,
    required this.name,
    this.artist,
    required this.songCount,
    this.year,
    this.artworkPath,
    required this.createdTime,
    required this.updatedTime,
    this.cachedArtistNames = const [],
  });
}
