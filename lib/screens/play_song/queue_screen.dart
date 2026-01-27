import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/screens/play_song/playing_song_screen.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/utills/snack_bar.dart';

import '../../commonWidgets/MusicListTile.dart';
import '../../commonWidgets/common_functions.dart';
import '../../commonWidgets/song_menu_screen.dart';
import '../../utills/globals.dart';
import '../tabs/library/widgets/mini_player_bar.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  late MusicPlayerService musicService;
  List<SongsModel> queueSongs = [];
  Set<int> selectedSongs = {};
  bool isShuffleEnabled = false;
  bool isRepeatEnabled = false;
  String repeatMode = 'off';
  StreamSubscription<int?>? _indexSubscription;
  StreamSubscription<bool>? _shuffleSubscription;
  StreamSubscription<List<SongsModel>>? _songsSubscription;
  Timer? _updateDebounceTimer;
  bool _isReordering = false;
  bool _isClosing = false;


  @override
  void initState() {
    super.initState();

    musicService = MusicPlayerService();
    _isClosing = false;
    _loadQueueSongs();

    // Sync shuffle state with music service
    isShuffleEnabled = musicService.isShuffleEnabled;
    _syncRepeatMode();
    print('🎵 QueueScreen initialized - Shuffle: $isShuffleEnabled, Repeat: $repeatMode');

    // Listen to current index changes to update UI
    _indexSubscription = musicService.currentIndexStream.listen((index) {
      if (mounted) {
        setState(() {});
      }
    });

    // Listen to shuffle state changes
    _shuffleSubscription = musicService.isPlayingStream.map((_) => musicService.isShuffleEnabled).listen((shuffleEnabled) {
      if (mounted) {
        setState(() {
          isShuffleEnabled = shuffleEnabled;
        });
      }
    });

    // Listen to songs list changes - this will automatically update when actions are performed in select_song_screen
    _songsSubscription = musicService.songsChanged.listen((newSongs) {
      if (_isClosing) {
        print('🚫 Ignoring song update - screen is closing');
        return;
      }

      if (mounted) {
        final wasEmpty = queueSongs.isEmpty;
        final nowEmpty = newSongs.isEmpty;

        setState(() {
          queueSongs = List.from(newSongs);
        });

        // ✅ Detect transition from non-empty to empty
        if (!wasEmpty && nowEmpty) {
          print('🔙 Queue became empty via external action');
          _handleEmptyQueue();
        }
      }
    });
  }

  void _handleEmptyQueue() async {
    if (_isClosing) return;

    print('🔙 Handling empty queue - closing screen');
    _isClosing = true;

    // Cancel subscriptions
    _songsSubscription?.cancel();
    _indexSubscription?.cancel();
    _shuffleSubscription?.cancel();

    // Small delay
    await Future.delayed(Duration(milliseconds: 100));

    // Close using go_router
    if (mounted && context.mounted) {
      print('✅ Closing queue screen with context.pop()');
      try {
        if (context.canPop()) {
          context.pop();
        } else {
          print('⚠️ Cannot pop - navigating to dashboard');
          context.go('/dashboard');
        }
      } catch (e) {
        print('❌ Failed to close queue screen: $e');
      }
    }
  }

  void _syncRepeatMode() {
    // Music service stores LoopMode enum (just_audio), but iOS uses strings
    final currentLoopMode = musicService.loopMode;
    String newRepeatMode;

    // Convert LoopMode enum to string (matches both Android enum and iOS string)
    if (currentLoopMode == LoopMode.off) {
      newRepeatMode = 'off';
    } else if (currentLoopMode == LoopMode.one) {
      newRepeatMode = 'one';
    } else {
      newRepeatMode = 'all';
    }

    if (repeatMode != newRepeatMode) {
      setState(() {
        repeatMode = newRepeatMode;
      });
      print('🔁 Repeat mode synced: $repeatMode');
    }
  }

  @override
  void dispose() {
    _isClosing = true;
    _updateDebounceTimer?.cancel();
    _indexSubscription?.cancel();
    _shuffleSubscription?.cancel();
    _songsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _popIfQueueEmpty() async {
    if (!mounted || queueSongs.isNotEmpty) return;
    print('🔙 Queue is empty, navigating back');
    await musicService.stopAndClearQueue();
    // Give UI time to update
    await Future.delayed(Duration(milliseconds: 150));
    if (!mounted) return;

    try {
      // Method 1: Use context.pop() if available
      if (context.mounted && context.canPop()) {
        print('✅ Popping with context.pop()');
        context.pop();
        return;
      }

      // Method 2: Use Navigator.pop
      if (Navigator.canPop(context)) {
        print('✅ Popping with Navigator.pop()');
        Navigator.pop(context);
        return;
      }

      // Method 3: Use Navigator.of
      if (Navigator.of(context).canPop()) {
        print('✅ Popping with Navigator.of(context).pop()');
        Navigator.of(context).pop();
        return;
      }

      print('⚠️ No pop method worked');
    } catch (e) {
      print('❌ Error popping: $e');
    }
  }

  void _loadQueueSongs() {
    // Load songs from the current playlist/queue
    setState(() {
      queueSongs = List.from(musicService.songs);
      for (int i = 0; i < queueSongs.length; i++) {
        print("queue songs --->${queueSongs[i].title}");
      }
    });
  }

  Future<void> _removeSongAtIndex(int index) async {
    if (index < 0 || index >= queueSongs.length) return;

    final currentPlayingIndex = musicService.currentIndex;
    final isRemovingCurrentSong = index == currentPlayingIndex;

    final wasPlaying = musicService.isPlaying;
    final currentPosition = musicService.position;
    final removedSong = queueSongs[index];
    setState(() {
      queueSongs.removeAt(index);
    });


    if (queueSongs.isEmpty) {
      try {
      await musicService.stopAndClearQueue();
      // Wait a bit for state to settle
      if (mounted) {
        showSnackBar(
            context,
                () {},
            message: 'Queue cleared',
            alertBannerLocation: AlertBannerLocation.bottom
        );
      }

      await Future.delayed(Duration(milliseconds: 200));
      if (mounted) {
        print('  🔙 Popping screen now');

        // Use Future.microtask to ensure pop happens after this frame
        Future.microtask(() {
          if (mounted && context.mounted) {
            if (context.canPop()) {
              print('  ✅ Pop with context.pop()');
              context.pop();
            } else if (Navigator.canPop(context)) {
              print('  ✅ Pop with Navigator.pop()');
              Navigator.pop(context);
            } else {
              print('  ❌ Cannot pop - no route to pop');
            }
          } else {
            print('  ❌ Context not mounted');
          }
        });
      }
      } catch (e) {
        print('  ❌ Error in empty queue handling: $e');
      }
      return;
    }

    try {
      if (isRemovingCurrentSong) {
        // Removing current song - stop and play next
        final nextIndex = index < queueSongs.length ? index : 0;
        print('  Playing next at: $nextIndex');
        // Stop current playback to avoid glitches
        await musicService.player.stop();
        // Set new playlist and play
        await musicService.setPlaylist(
            queueSongs,
            startIndex: nextIndex,
            autoPlay: true
        );
      } else if (index < currentPlayingIndex) {

        final newCurrentIndex = currentPlayingIndex - 1;
        if (Platform.isAndroid) {
          final source = musicService.player.audioSource;
          if (source is ConcatenatingAudioSource && !musicService.isShuffleEnabled) {
            print('  Android: Using ConcatenatingAudioSource.removeAt()');

            await source.removeAt(index);

            musicService.updateSongsList(queueSongs);

          } else {
            // Fallback: rebuild
            print('  Android: Fallback to rebuild');
            await musicService.updateSongsInQueueWithIndex(queueSongs, newCurrentIndex);

            if (wasPlaying) {
              await musicService.seek(currentPosition, index: newCurrentIndex);
              await musicService.play();
            }
          }
        } else if (Platform.isIOS) {
          print('  iOS: Updating internal list only');
          await musicService.removeFromQueueAtIndex(index, newCurrentIndex);
          musicService.updateSongsList(queueSongs);
        }
      } else {
        print('  Removed song AFTER current, keeping index: $currentPlayingIndex');

        if (Platform.isAndroid) {
          // Android: Use ConcatenatingAudioSource.removeAt() for seamless removal
          final source = musicService.player.audioSource;
          if (source is ConcatenatingAudioSource && !musicService.isShuffleEnabled) {
            print('  Android: Using ConcatenatingAudioSource.removeAt()');
            await source.removeAt(index);
            musicService.updateSongsList(queueSongs);

          } else {
            await musicService.updateSongsInQueueWithIndex(queueSongs, currentPlayingIndex);
          }

        } else if (Platform.isIOS) {
          print('  iOS: Updating internal list only');
          musicService.updateSongsList(queueSongs);

        }
      }
      // showSnackBar(context, () {}, message: 'Removed "${removedSong.title}"', alertBannerLocation: AlertBannerLocation.bottom);

      print('✅ Song removed successfully');
    } catch (e) {
      print('❌ Error removing song: $e');
      if (wasPlaying && !musicService.isPlaying) {
        try {
          await musicService.play();
        } catch (_) {}
      }
    }
  }

  void _reorderSongs(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    if (oldIndex == newIndex) return;

    // Mark that we're reordering to prevent external updates
    _isReordering = true;

    setState(() {
      final SongsModel item = queueSongs.removeAt(oldIndex);
      queueSongs.insert(newIndex, item);
    });

    // Cancel any pending updates
    _updateDebounceTimer?.cancel();

    // Use the INSTANT reorder method (Android uses move(), iOS defers update)
    _updateDebounceTimer = Timer(Duration(milliseconds: 100), () async {
      try {
        await musicService.reorderSongInQueue(oldIndex, newIndex);
      } finally {
        _isReordering = false;
      }
    });
  }

  Future<void> _toggleShuffle() async {
    if (queueSongs.isEmpty) return;

    print('🔀 Toggle Shuffle - Current: $isShuffleEnabled');
    print('📱 Platform: ${Platform.isAndroid ? "Android" : "iOS"}');

    try {
      // Toggle shuffle via music service (handles both platforms)
      await musicService.toggleShuffle();

      // Update local state from music service
      setState(() {
        isShuffleEnabled = musicService.isShuffleEnabled;
      });

      showSnackBar(context, () {}, message: isShuffleEnabled ? 'Shuffle enabled' : 'Shuffle disabled', alertBannerLocation: AlertBannerLocation.bottom);

      // Reload queue to reflect any order changes
      _loadQueueSongs();

      print('✅ Shuffle toggled to: $isShuffleEnabled');
      print('   Android: ${Platform.isAndroid ? "setShuffleModeEnabled + shuffle()" : "N/A"}');
      print('   iOS: ${Platform.isIOS ? "setShuffleModeEnabled via method channel" : "N/A"}');
    } catch (e) {
      print('❌ Error toggling shuffle: $e');
      // _showSnackBar('Failed to toggle shuffle', Assets.svgIcSuffle);
    }
  }

  /* void _toggleShuffle() async {
    if (queueSongs.isEmpty) return;

    print('🔀 Toggle Shuffle - Current: $isShuffleEnabled');
    print('📱 Platform: ${Platform.isAndroid ? "Android" : "iOS"}');


    final currentSongId = musicService.currentSongId;
    final wasPlaying = musicService.isPlaying;

    if (!isShuffleEnabled) {
      // Enable shuffle
      final shuffledSongs = List<SongsModel>.from(queueSongs);
      shuffledSongs.shuffle();

      int startIndex = 0;
      if (currentSongId != null) {
        final currentIndex = shuffledSongs.indexWhere((song) => song.id == currentSongId);
        if (currentIndex >= 0) {
          startIndex = currentIndex;
        } else {
          startIndex = (DateTime.now().millisecondsSinceEpoch % shuffledSongs.length);
        }
      } else {
        startIndex = (DateTime.now().millisecondsSinceEpoch % shuffledSongs.length);
      }

      setState(() {
        queueSongs = shuffledSongs;
        isShuffleEnabled = true;
      });

      await musicService.ensureShuffleOnAndReshuffle();
      await musicService.setPlaylist(shuffledSongs, startIndex: startIndex, autoPlay: wasPlaying);
    } else {
      // Disable shuffle
      setState(() {
        isShuffleEnabled = false;
      });

      await musicService.ensureShuffleOff();
      _loadQueueSongs();

      // Use seamless update when disabling shuffle
      await musicService.updateSongsInQueue(queueSongs);
    }
  }*/

  Future<void> _toggleRepeat() async {
    if (queueSongs.isEmpty) return;

    print('🔁 Toggle Repeat - Current: $repeatMode');
    print('📱 Platform: ${Platform.isAndroid ? "Android" : "iOS"}');

    try {

      await musicService.toggleRepeat();

      _syncRepeatMode();

      String message;
      String iconAsset;

      if (repeatMode == 'off') {
        message = 'Repeat off';
        iconAsset = Assets.svgRepeatOff;
      } else if (repeatMode == 'one') {
        message = 'Repeat current';
        iconAsset = Assets.svgRepeatOnce;
      } else {
        message = 'Loop all';
        iconAsset = Assets.svgRepeatOn;
      }

      showSnackBar(context, () {}, message: message, alertBannerLocation: AlertBannerLocation.bottom);

      print('✅ Repeat toggled to: $repeatMode');
      if (Platform.isAndroid) {
        print('   Android: Using LoopMode.$repeatMode enum via just_audio');
      } else if (Platform.isIOS) {
        print('   iOS: Converted to string \'$repeatMode\' and sent via method channel');
        print('   iOS Native: AVQueuePlayer receives \'$repeatMode\' string');
      }
    } catch (e) {
      print('❌ Error toggling repeat: $e');
    }
  }

  Future<void> _clearQueue() async {

    // ✅ Close the dialog FIRST
    if (mounted && context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // Close the confirmation dialog
    }
    _isClosing = true;

    // Cancel subscriptions
    _songsSubscription?.cancel();
    _indexSubscription?.cancel();
    _shuffleSubscription?.cancel();

    setState(() {
      queueSongs = [];
      selectedSongs.clear();
    });
    try {
      print('  ⏹️ Stopping playback...');
      await musicService.player.stop();
      await musicService.player.seek(Duration.zero);
      print('  ✅ Playback stopped');
    } catch (e) {
      print('  ⚠️ Error stopping player: $e');
    }
    print('  🗑️ Clearing queue in service...');
    await musicService.stopAndClearQueue();
    await Future.delayed(Duration(milliseconds: 250));

    if (mounted && context.mounted) {
      print('✅ Closing queue screen');
      try {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      } catch (e) {
        print('❌ Pop failed: $e');
      }
    }
    print('✅ Queue cleared successfully');
  }

  void _showClearQueueDialog() {
    if (queueSongs.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
      isScrollControlled: true,
      builder: (_) => _buildClearQueueConfirmationDialog(),
    );
  }

  Widget _buildClearQueueConfirmationDialog() {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Container(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 10.h, bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.r)),
          ),
          SizedBox(height: 30.h),

          // Title
          Texts('Clear the queue', fontSize: 18.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.textColor),
          SizedBox(height: 30.h),

          // Message
          Texts(
            'Are you sure you want to clear the queue?',
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
            align: TextAlign.center,
          ),
          SizedBox(height: 25.h),

          // Action buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8.r)),
                    child: Center(
                      child: Texts(S.of(context).cancel, fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.black),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Clear button
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    // ✅ Await the clear operation
                    await _clearQueue();
                  },
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(8.r)),
                    child: Center(
                      child: Texts('Clear', fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  void _navigateToSelectSongScreen() {
    if (queueSongs.isEmpty) return;

    context.push('/dashboard/select-song', extra: {'songs': queueSongs});
  }

  @override
  Widget build(BuildContext context) {
    final bool hasQueue = queueSongs.isNotEmpty;
    final bool showMiniPlayer = hasQueue && musicService.isPlaying;

    final double miniPlayerHeight = 90.h;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomPadding = hasQueue ? miniPlayerHeight + bottomInset : 0;

    return BlocListener<SongsBloc, SongsState>(
      listener: (context, state) {
        state.maybeWhen(
          loaded: (songs) {
            // Remove any songs from queue that are no longer in the library
            final currentSongIds = songs.map((s) => s.id).toSet();
            final filteredQueue = queueSongs.where((song) => currentSongIds.contains(song.id)).toList();

            if (filteredQueue.length != queueSongs.length) {
              setState(() {
                queueSongs = filteredQueue;
                selectedSongs.clear(); // Clear selections if songs were removed
              });

              // Update music service with filtered queue
              if (musicService.songs.isNotEmpty) {
                musicService.setPlaylist(queueSongs);
              }
              _popIfQueueEmpty();
            }
          },
          orElse: () {},
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryOrange,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Texts("Playing Queue", fontSize: 18.sp, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter, color: AppColors.white),
          actions: [
            IconButton(
              onPressed: _showClearQueueDialog,
              icon: SvgPicture.asset(Assets.svgIcDelete, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn), height: 26.h, width: 26.w),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Queue Controls
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _navigateToSelectSongScreen,
                        child: Row(
                          children: [
                            SvgPicture.asset(Assets.svgSongsCount),
                            SizedBox(width: 8.w),
                            SizedBox(
                              height: 38.h, // Increase height so padding doesn't zero it out
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.h), // Leave some room for the line
                                child: VerticalDivider(
                                  color: AppColors.mediumDarkGrey.withOpacity(0.5),
                                  width: 1.w,      // Total space the widget occupies
                                  thickness: 1.2.w,   // The actual thickness of the line
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            if (queueSongs.isNotEmpty && musicService.currentIndex >= 0) ...[
                              Texts(
                                "${musicService.currentIndex + 1}/${queueSongs.length}",
                                fontSize: 14.sp,
                                color: AppColors.textColor,
                                fontWeight: FontWeight.w400,
                                fontFamily: AppFonts.inter,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleShuffle,
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r)),
                              child: SvgPicture.asset(
                                Assets.svgIcSuffle,
                                width: 20.w,
                                height: 20.h,
                                colorFilter: ColorFilter.mode(!isShuffleEnabled ? AppColors.mediumDarkGrey : AppColors.textColor, BlendMode.srcIn),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          GestureDetector(
                            onTap: _toggleRepeat,
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r)),
                              child: SvgPicture.asset(
                                repeatMode == 'one' ? Assets.svgRepeatOnce : repeatMode == 'off' ? Assets.svgRepeatOff : Assets.svgIcRepeat,
                                width: 20.w,
                                height: 20.h,
                                colorFilter: ColorFilter.mode(isRepeatEnabled ? AppColors.white : AppColors.textColor, BlendMode.srcIn),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Queue Songs List
                Expanded(
                  child: StreamBuilder<List<SongsModel>>(
                    stream: musicService.songsChanged,
                    initialData: musicService.songs,
                    builder: (context, snapshot) {
                      // Always check the current state, not just the snapshot
                      // final hasAny = musicService.songs.isNotEmpty;
                      // // final showMiniPlayer = hasAny;

                      return ReorderableListView.builder(
                        padding: EdgeInsets.only(
                          left: 16.w,
                          right: 16.w,
                          // bottom: showMiniPlayer ? 74.h : 10.h, // Space for MiniPlayerBar (which includes system nav bar padding)
                          bottom: bottomPadding, // Space for MiniPlayerBar (which includes system nav bar padding)
                        ),
                        itemCount: queueSongs.length,
                        onReorder: _reorderSongs,
                        itemBuilder: (context, index) {
                          final song = queueSongs[index];
                          final isCurrentlyPlaying = musicService.currentIndex == index;

                          return Container(
                            key: ValueKey(song.id),
                            child: MusicListTile(
                              margin: 7.w,
                              height: 66.h,
                              borderRadius: 10.r,
                              backgroundColor: AppColors.musicTileBackgroundColor,
                              cardHeight: 50.h,
                              cardWidth: 50.h,
                              cardRadius: 7.r,
                              cardIconAsset: song.artwork_path ?? Assets.svgMusicIcon,
                              isSvgCardIcon: (song.artwork_path ?? '').contains('.svg') || song.artwork_path == null,
                              cardIconSize: 32.r,
                              title: song.title,
                              subtitle: song.artist,
                              trailingIconAsset: Assets.svgMenuIcon,
                              trailingIconHeight: 19.5.h,
                              trailingIconWidth: 3.w,
                              trailingMargin: 10.w,
                              songLength: formatDuration(song.duration),
                              songLengthRequired: true,
                              isGifLoad: isCurrentlyPlaying,
                              titleSize: isCurrentlyPlaying ? 16 : 14,
                              titleWeight: isCurrentlyPlaying ? FontWeight.w600 : FontWeight.w500,
                              // Queue-specific icons
                              showDraggableIcon: true,
                              draggableIconAsset: Assets.svgDraggable,
                              draggableIconSize: 5,
                              showCancelIcon: false,
                              cancelIconAsset: Assets.svgCancel,
                              cancelIconSize: 24.r,
                              onCancelTap: () => _removeSongAtIndex(index),
                              onTap: () async {
                                if (musicService.songs.isNotEmpty && musicService.songs[musicService.currentIndex].id == song.id && musicService.isPlaying) {
                                  context.push('/dashboard/playing', extra: PlayingSongArgs(songs: musicService.songs));
                                } else {
                                  musicService.setPlaylist(queueSongs, startIndex: index);
                                }
                              },
                              onPlayTap: () async {
                                await showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
                                  isScrollControlled: true,
                                  builder: (_) => SongMenuScreen(
                                    songMenuList: songMenuItems,
                                    isPlaying: false,
                                    currentSong: song,
                                    songIndex: index,
                                    songsList: queueSongs,
                                    from: 'queue',
                                    maxHeight: 0.87.sh,
                                    onSongDeleted: () {
                                      setState(() {
                                        _loadQueueSongs();
                                      });
                                    },
                                  ),
                                );
                                setState(() {
                                  _loadQueueSongs();
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: SafeArea(top: false, child: MiniPlayerBar())),
            //   Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayerBar()),
          ],
        ),
      ),
    );
  }
}
