import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/commonWidgets/app_bar_with_icon_title.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/features/music_player/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/bloc/music_player_state.dart';
import 'package:music_app/screens/play_song/playing_song_screen.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
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
  Set<int> selectedSongs = {};
  Timer? _updateDebounceTimer;
  bool _isReordering = false;
  bool _isClosing = false;
  bool _isDragging = false;

  MusicPlayerService get _musicService =>
      context.read<MusicPlayerBloc>().musicService;

  static String _loopModeToString(LoopMode mode) {
    if (mode == LoopMode.off) return 'off';
    if (mode == LoopMode.one) return 'one';
    return 'all';
  }

  @override
  void initState() {
    super.initState();
    _isClosing = false;
  }

  void _handleEmptyQueue() async {
    if (_isClosing) return;

    _isClosing = true;
    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted && context.mounted) {
      try {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      } catch (e) {
        // Ignore
      }
    }
  }

  @override
  void dispose() {
    _isClosing = true;
    _updateDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _popIfQueueEmpty(List<SongsModel> queueSongs) async {
    if (!mounted || queueSongs.isNotEmpty) return;
    await _musicService.stopAndClearQueue();
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

  Future<void> _removeSongAtIndex(int index, List<SongsModel> queueSongs) async {
    if (index < 0 || index >= queueSongs.length) return;

    final currentPlayingIndex = _musicService.currentIndex;
    final isRemovingCurrentSong = index == currentPlayingIndex;

    final wasPlaying = _musicService.isPlaying;
    final currentPosition = _musicService.position;
    final removedSong = queueSongs[index];
    final newQueue = List<SongsModel>.from(queueSongs)..removeAt(index);

    if (newQueue.isEmpty) {
      try {
        await _musicService.stopAndClearQueue();
        // Wait a bit for state to settle
        if (mounted) {
          showSnackBar(
            context,
            () {},
            message: 'Queue cleared',
            alertBannerLocation: AlertBannerLocation.bottom,
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
        final nextIndex = index < newQueue.length ? index : 0;
        await _musicService.player.stop();
        await _musicService.setPlaylist(
          newQueue,
          startIndex: nextIndex,
          autoPlay: true,
        );
      } else if (index < currentPlayingIndex) {
        final newCurrentIndex = currentPlayingIndex - 1;
        if (Platform.isAndroid) {
          final source = _musicService.player.audioSource;
          if (source is ConcatenatingAudioSource &&
              !_musicService.isShuffleEnabled) {
            await source.removeAt(index);
            _musicService.updateSongsList(newQueue);
          } else {
            await _musicService.updateSongsInQueueWithIndex(
              newQueue,
              newCurrentIndex,
            );
            if (wasPlaying) {
              await _musicService.seek(currentPosition, index: newCurrentIndex);
              await _musicService.play();
            }
          }
        } else if (Platform.isIOS) {
          await _musicService.removeFromQueueAtIndex(index, newCurrentIndex);
          _musicService.updateSongsList(newQueue);
        }
      } else {
        if (Platform.isAndroid) {
          final source = _musicService.player.audioSource;
          if (source is ConcatenatingAudioSource &&
              !_musicService.isShuffleEnabled) {
            await source.removeAt(index);
            _musicService.updateSongsList(newQueue);
          } else {
            await _musicService.updateSongsInQueueWithIndex(
              newQueue,
              currentPlayingIndex,
            );
          }
        } else if (Platform.isIOS) {
          _musicService.updateSongsList(newQueue);
        }
      }
    } catch (e) {
      if (wasPlaying && !_musicService.isPlaying) {
        try {
          await _musicService.play();
        } catch (_) {}
      }
    }
  }

  void _reorderSongs(int oldIndex, int newIndex, List<SongsModel> queueSongs) async {
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex == newIndex) return;

    _isReordering = true;
    _musicService.prepareReorderForCurrentSong(oldIndex, newIndex);
    _updateDebounceTimer?.cancel();

    try {
      await _musicService.swapReorderSongInQueue(oldIndex, newIndex);
    } finally {
      _isReordering = false;
    }
  }

  Future<void> _toggleShuffle(List<SongsModel> queueSongs) async {
    if (queueSongs.isEmpty) return;

    try {
      await _musicService.toggleShuffle();
      final enabled = _musicService.isShuffleEnabled;
      showSnackBar(
        context,
        () {},
        message: enabled ? 'Shuffle enabled' : 'Shuffle disabled',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      // Ignore
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

  Future<void> _toggleRepeat(List<SongsModel> queueSongs) async {
    if (queueSongs.isEmpty) return;

    try {
      await _musicService.toggleRepeat();
      final mode = _loopModeToString(_musicService.loopMode);
      String message;
      if (mode == 'off') {
        message = 'Repeat off';
      } else if (mode == 'one') {
        message = 'Repeat current';
      } else {
        message = 'Loop all';
      }
      showSnackBar(
        context,
        () {},
        message: message,
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _clearQueue() async {
    if (mounted && context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    _isClosing = true;
    setState(() => selectedSongs.clear());

    try {
      await _musicService.player.stop();
      await _musicService.player.seek(Duration.zero);
    } catch (e) {
      // Ignore
    }
    await _musicService.stopAndClearQueue();
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

  void _showClearQueueDialog(List<SongsModel> queueSongs) {
    if (queueSongs.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      isScrollControlled: true,
      builder: (_) => _buildClearQueueConfirmationDialog(),
    );
  }

  Widget _buildClearQueueConfirmationDialog() {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 10.h,
        bottom: bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 30.h),

          // Title
          Texts(
            'Clear the queue',
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
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
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Texts(
                        S.of(context).cancel,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.inter,
                        color: AppColors.black,
                      ),
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
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Texts(
                        'Clear',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.inter,
                        color: AppColors.white,
                      ),
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

  void _navigateToSelectSongScreen(List<SongsModel> queueSongs) {
    if (queueSongs.isEmpty) return;
    context.push('/dashboard/select-song', extra: {'songs': queueSongs});
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MusicPlayerBloc, MusicPlayerState>(
      listenWhen: (prev, curr) => prev.songs.isNotEmpty && curr.songs.isEmpty,
      listener: (context, state) {
        if (state.songs.isEmpty && !_isClosing) _handleEmptyQueue();
      },
      buildWhen: (prev, curr) => prev.songs != curr.songs ||
          prev.currentIndex != curr.currentIndex ||
          prev.currentSongId != curr.currentSongId ||
          prev.isPlaying != curr.isPlaying ||
          prev.shuffleEnabled != curr.shuffleEnabled ||
          prev.loopMode != curr.loopMode,
      builder: (context, state) {
        final queueSongs = state.songs;
        final hasQueue = queueSongs.isNotEmpty;
        final showMiniPlayer = hasQueue && state.isPlaying;

    final double miniPlayerHeight = 90.h;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomPadding = hasQueue ? miniPlayerHeight + bottomInset : 0;

    return BlocListener<SongsBloc, SongsState>(
        listener: (context, songsState) {
          songsState.maybeWhen(
            loaded: (librarySongs) {
              final currentSongIds = librarySongs.map((s) => s.id).toSet();
              final filteredQueue = queueSongs
                  .where((song) =>
                      song.id != null && currentSongIds.contains(song.id))
                  .toList();

              if (filteredQueue.length != queueSongs.length) {
                setState(() => selectedSongs.clear());
                if (_musicService.songs.isNotEmpty) {
                  _musicService.setPlaylist(filteredQueue);
                }
                _popIfQueueEmpty(filteredQueue);
              }
            },
            orElse: () {},
          );
        },
        child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBarWithIconTitle(
          title: "Playing Queue",
          backgroundColor: AppColors.primaryOrange,
          titleColor: AppColors.white,
          centerTitle: false,
          onBack: () => context.pop(),
          actions: [
            IconButton(
              onPressed: () => _showClearQueueDialog(queueSongs),
              icon: SvgPicture.asset(
                Assets.svgIcDelete,
                colorFilter: const ColorFilter.mode(
                  AppColors.white,
                  BlendMode.srcIn,
                ),
                height: 26.h,
                width: 26.w,
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Queue Controls
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToSelectSongScreen(queueSongs),
                        child: Row(
                          children: [
                            SvgPicture.asset(Assets.svgSongsCount),
                            SizedBox(width: 8.w),
                            SizedBox(
                              height: 38
                                  .h, // Increase height so padding doesn't zero it out
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 8.h,
                                ), // Leave some room for the line
                                child: VerticalDivider(
                                  color: AppColors.mediumDarkGrey.withOpacity(
                                    0.5,
                                  ),
                                  width: 1.w, // Total space the widget occupies
                                  thickness:
                                      1.2.w, // The actual thickness of the line
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            if (queueSongs.isNotEmpty &&
                                state.currentIndex != null &&
                                state.currentIndex! >= 0) ...[
                              Texts(
                                "${state.currentIndex! + 1}/${queueSongs.length}",
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
                            onTap: () => _toggleShuffle(queueSongs),
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: SvgPicture.asset(
                                Assets.svgIcSuffle,
                                width: 20.w,
                                height: 20.h,
                                colorFilter: ColorFilter.mode(
                                  !state.shuffleEnabled
                                      ? AppColors.mediumDarkGrey
                                      : AppColors.textColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          GestureDetector(
                            onTap: () => _toggleRepeat(queueSongs),
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: SvgPicture.asset(
                                _loopModeToString(state.loopMode) == 'one'
                                    ? Assets.svgRepeatOnce
                                    : _loopModeToString(state.loopMode) == 'off'
                                    ? Assets.svgRepeatOff
                                    : Assets.svgRepeatOn,
                                width: 20.w,
                                height: 20.h,
                                colorFilter: ColorFilter.mode(
                                  // isRepeatEnabled
                                      // ? AppColors.white
                                      // : AppColors.textColor,
                                       AppColors.textColor,
                                  BlendMode.srcIn,
                                ),
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
                  child: ReorderableListView.builder(
                        proxyDecorator:
                            (
                              Widget child,
                              int index,
                              Animation<double> animation,
                            ) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (BuildContext context, Widget? child) {
                                  return Material(
                                    elevation: 6,
                                    shadowColor: Colors.black.withValues(
                                      alpha: 0.4,
                                    ),
                                    color: Colors
                                        .transparent, // Keeps your orange background visible
                                    borderRadius: BorderRadius.circular(
                                      10.r,
                                    ), // Match your tile radius
                                    child: child,
                                  );
                                },
                                child: child,
                              );
                            },
                        padding: EdgeInsets.only(
                          left: 16.w,
                          right: 16.w,
                          // bottom: showMiniPlayer ? 74.h : 10.h, // Space for MiniPlayerBar (which includes system nav bar padding)
                          bottom:
                              bottomPadding, // Space for MiniPlayerBar (which includes system nav bar padding)
                        ),
                        itemCount: queueSongs.length,
                        onReorder: (oldIndex, newIndex) =>
                            _reorderSongs(oldIndex, newIndex, queueSongs),
                        itemBuilder: (context, index) {
                          final song = queueSongs[index];
                          final isCurrentlyPlaying =
                              state.currentSongId == song.id;
                          final isPlaying =
                              state.currentSongId == song.id &&
                              state.isPlaying;

                          return Container(
                            key: ValueKey(song.id),
                            child: MusicListTile(
                              margin: 7.w,
                              height: 66.h,
                              borderRadius: 10.r,
                              backgroundColor:
                                  AppColors.musicTileBackgroundColor,
                              cardHeight: 50.h,
                              cardWidth: 50.h,
                              cardRadius: 7.r,
                              cardIconAsset:
                                  song.artwork_path ?? Assets.svgMusicIcon,
                              isSvgCardIcon:
                                  (song.artwork_path ?? '').contains('.svg') ||
                                  song.artwork_path == null,
                              cardIconSize: 32.r,
                              title: song.title,
                              subtitle: song.artist,
                              trailingIconAsset: Assets.svgMenuIcon,
                              trailingIconHeight: 19.5.h,
                              trailingIconWidth: 3.w,
                              trailingMargin: 10.w,
                              songLength: formatDuration(song.duration),
                              songLengthRequired: true,
                              isPlaying: isPlaying,
                              isGifLoad: isCurrentlyPlaying,
                              titleSize: isCurrentlyPlaying ? 16 : 14,
                              titleWeight: isCurrentlyPlaying
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              showDraggableIcon: true,
                              draggableIconAsset: Assets.svgDraggable,
                              draggableIconSize: 5,
                              showCancelIcon: false,
                              cancelIconAsset: Assets.svgCancel,
                              cancelIconSize: 24.r,
                              onCancelTap: () =>
                                  _removeSongAtIndex(index, queueSongs),
                              onTap: () async {
                                if (state.songs.isNotEmpty &&
                                    state.currentIndex != null &&
                                    state.currentIndex! < state.songs.length &&
                                    state.songs[state.currentIndex!].id ==
                                        song.id &&
                                    state.isPlaying) {
                                  context.push(
                                    '/dashboard/playing',
                                    extra: PlayingSongArgs(
                                      songs: _musicService.songs,
                                    ),
                                  );
                                } else {
                                  _musicService.setPlaylist(
                                    queueSongs,
                                    startIndex: index,
                                  );
                                }
                              },
                              onPlayTap: () async {
                                await showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(40.r),
                                    ),
                                  ),
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
                                      setState(() {});
                                    },
                                  ),
                                );
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(top: false, child: MiniPlayerBar()),
            ),
            //   Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayerBar()),
          ],
        ),
      ),
    );
      },
    );
  }
}
