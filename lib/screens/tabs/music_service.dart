import 'package:just_audio/just_audio.dart';

class MusicPlayerService {
  static final MusicPlayerService _instance = MusicPlayerService._internal();
  factory MusicPlayerService() => _instance;

  late AudioPlayer player;
  int currentIndex = 0;
  List<String> songs = []; // device file paths
  bool isPlaying = false; // track play state

  MusicPlayerService._internal() {
    player = AudioPlayer();

    player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
        await player.pause(); //  stop auto replay
        isPlaying = false;
        // You could also auto-play next track if you want
        // next();
      } else if (state.playing) {
        isPlaying = true;
      } else {
        isPlaying = false;
      }
    });
  }

  Future<void> setPlaylist(List<String> songPaths, {int startIndex = 0}) async {
    songs = songPaths;
    currentIndex = startIndex;
    await player.setFilePath(songs[currentIndex]);
    await player.play();
    isPlaying = true;
  }

  Future<void> setFile(String filePath) async {
    songs = [filePath];
    currentIndex = 0;
    await player.setFilePath(filePath);
    await player.play();
    isPlaying = true;
  }

  Future<void> play() async {
    // if already at end, reset before play
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    await player.play();
    isPlaying = true;
  }

  Future<void> pause() async {
    await player.pause();
    isPlaying = false;
  }
  Future<void> next() async {
    if (currentIndex < songs.length - 1) {
      currentIndex++;
      await player.setFilePath(songs[currentIndex]);
      await player.play();
      isPlaying = true;
    }
  }

  Future<void> previous() async {
    if (currentIndex > 0) {
      currentIndex--;
      await player.setFilePath(songs[currentIndex]);
      await player.play();
      isPlaying = true;
    }
  }
}
