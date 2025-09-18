import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/songs/data/models/song_model.dart';

class MusicPlayerService {
  static final MusicPlayerService _instance = MusicPlayerService._internal();

  factory MusicPlayerService() => _instance;
  late AudioPlayer player;
  List<SongsModel> songs = []; // device file paths

  // expose current index
  int get currentIndex => player.currentIndex ?? -1;

  Stream<int?> get currentIndexStream => player.currentIndexStream;

  // expose play state
  bool get isPlaying => player.playing;

  Stream<bool> get isPlayingStream => player.playingStream;

  MusicPlayerService._internal() {
    player = AudioPlayer();

    player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        // If last song finishes → reset instead of full stop
        if (currentIndex >= (songs.length - 1)) {
          await player.seek(Duration.zero);
          await player.pause();
        }
      }
    });
  }

  Future<void> setPlaylist(List<SongsModel> songModels, {int startIndex = 0}) async {
    if (songModels.isEmpty) return;
    songs = songModels;

    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: songModels
          .map(
            (song) => AudioSource.uri(
              Uri.file(song.filePath),
              tag: MediaItem(
                // Optional: metadata for mini player / lock screen
                id: song.id?.toString() ?? '',
                title: song.title,
                artist: song.artist,
                album: song.album,
                duration: Duration(milliseconds: song.duration),
                artUri: song.artwork_path != null ? Uri.file(song.artwork_path!) : null,
              ),
            ),
          )
          .toList(),
    );

    await player.setAudioSource(playlist, initialIndex: startIndex);

    // Wait for duration to be loaded before starting play
    await player.durationStream.firstWhere((d) => d != null);

    await player.play();
  }

  Future<void> play() async {
    // if already at end, reset before play
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero);
    }
    await player.play();
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> next() async {
    if (currentIndex < songs.length - 1) {
      await player.seekToNext();
      await player.play();
    }
  }

  Future<void> stop() => player.stop();

  Future<void> previous() async {
    if (currentIndex > 0) {
      await player.seekToPrevious();
      await player.play();
    } else {
      // restart current if already at first song
      await player.seek(Duration.zero);
      await player.play();
    }
  }
}

/*class MusicPlayerService {
  static final MusicPlayerService _instance = MusicPlayerService._internal();
  factory MusicPlayerService() => _instance;
  final _currentIndexController = StreamController<int>.broadcast();
  Stream<int> get currentIndexStream => _currentIndexController.stream;


  late AudioPlayer player;
  int currentIndex = 0;
  List<String> songs = []; // device file paths
  bool isPlaying = false; // track play state



  MusicPlayerService._internal() {
    player = AudioPlayer();

    player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        // When song finishes, play next automatically
        await _playNext();
      } else {
        // Update play state
        isPlaying = state.playing;
      }
    });

    */ /*player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
        await player.pause(); //  stop auto replay
        isPlaying = false;

        await _playNext(); // Auto-play next song
      } else if (state.playing) {
        isPlaying = true;
      } else {
        isPlaying = false;
      }
    });*/ /*
  }

  Future<void> setPlaylist(List<String> songPaths, {int startIndex = 0}) async {
    if (songPaths.isEmpty) return;
    songs = songPaths;
    currentIndex = startIndex.clamp(0, songs.length - 1);
    await player.setFilePath(songs[currentIndex]);

    // Wait for duration to be loaded before starting play
    await player.durationStream.firstWhere((d) => d != null);

    await player.play();
    isPlaying = true;
  }

  Future<void> setFile(String filePath) async {
    songs = [filePath];
    currentIndex = 0;
    await player.setFilePath(filePath);
    await player.durationStream.firstWhere((d) => d != null);
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
    await _playNext();
  }

  Future<void> previous() async {
    if (currentIndex > 0) {
      currentIndex--;
      await player.setFilePath(songs[currentIndex]);
      await player.durationStream.firstWhere((d) => d != null);
      await player.play();
      isPlaying = true;
    }
  }

  Future<void> _playNext() async {
    if (currentIndex < songs.length - 1) {
      currentIndex++;
      _currentIndexController.add(currentIndex); // notify listeners
      await player.setFilePath(songs[currentIndex]);
      await player.durationStream.firstWhere((d) => d != null);
      await player.play();
      isPlaying = true;
    } else {
      // End of playlist
      await player.pause();
      isPlaying = false;
      await player.seek(Duration.zero); // optional: reset to start
    }
  }
}*/
