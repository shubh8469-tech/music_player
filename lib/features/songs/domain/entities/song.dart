class Song {
  final int? id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final int duration;
  final String filePath;
  final String? artworkPath;

  Song({
    this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.duration,
    required this.filePath,
    this.artworkPath,
  });
}
