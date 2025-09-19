import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/songs/data/models/song_model.dart';

class MusicPlayerService {
  static final MusicPlayerService _instance = MusicPlayerService._internal();

  factory MusicPlayerService() => _instance;
  late AudioPlayer player;
  List<SongsModel> songs = [];

  // Loop and Shuffle state variables
  LoopMode _loopMode = LoopMode.off;
  bool _isShuffleEnabled = false;
  bool get isShuffleEnabled => _isShuffleEnabled;
  LoopMode get loopMode => _loopMode;

  // expose current index
  int get currentIndex => player.currentIndex ?? -1;
  Stream<int?> get currentIndexStream => player.currentIndexStream;

  // expose play state
  bool get isPlaying => player.playing;
  Stream<bool> get isPlayingStream => player.playingStream;

  MusicPlayerService._internal() {
    player = AudioPlayer();
    player.setLoopMode(LoopMode.all);

    // Initialize player with default loop mode and shuffle disabled
    player.setLoopMode(_loopMode);
    player.setShuffleModeEnabled(_isShuffleEnabled);

    player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        // If last song finishes → reset instead of full stop
        if (currentIndex >= (songs.length - 1)) {
          await player.seek(Duration.zero);
          await player.play();
        }else{
          await player.seekToNext();
          await player.play();
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
    }else{
      // Loop to the first song
      await player.seek(Duration.zero, index: 0);
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
      // await player.seek(Duration.zero);
      // await player.play();
      //Loop to last song instead of staying on first
      await player.seek(Duration.zero, index: songs.length - 1);
      await player.play();
    }
  }

  // Toggle Shuffle mode
  Future<void> toggleShuffle() async {
    _isShuffleEnabled = !_isShuffleEnabled;
    await player.setShuffleModeEnabled(_isShuffleEnabled);

    // If enabling shuffle, immediately shuffle the playlist order
    if (_isShuffleEnabled) {
      await player.shuffle();
    }
  }

  // Cycle Loop mode Off → All → One → Off
  Future<void> toggleRepeat() async {
    if (_loopMode == LoopMode.off) {
      _loopMode = LoopMode.one;
    } else if (_loopMode == LoopMode.one) {
      _loopMode = LoopMode.all;
    } else {
      _loopMode = LoopMode.off;
    }
    await player.setLoopMode(_loopMode);
  }

}
