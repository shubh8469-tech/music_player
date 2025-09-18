class Song {
  final int? id;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final String duration;
  final String filePath;
  final String? folder;
  final String? artwork_path;

  Song({
    this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.duration,
    required this.filePath,
    this.folder,
    this.artwork_path,
  });
}
