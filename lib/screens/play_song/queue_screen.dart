import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/screens/play_song/playing_song_screen.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/screens/tabs/music_service.dart';

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

  @override
  void initState() {
    super.initState();
    musicService = MusicPlayerService();
    _loadQueueSongs();

    // Sync shuffle state with music service
    isShuffleEnabled = musicService.isShuffleEnabled;

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

    // Listen to songs list changes
    _songsSubscription = musicService.songsChanged.listen((newSongs) {
      if (mounted) {
        setState(() {
          queueSongs = List.from(newSongs);
        });
      }
    });
  }

  @override
  void dispose() {
    _indexSubscription?.cancel();
    _shuffleSubscription?.cancel();
    _songsSubscription?.cancel();
    super.dispose();
  }

  void _loadQueueSongs() {
    // Load songs from the current playlist/queue
    setState(() {
      queueSongs = List.from(musicService.songs);
    });
  }

  void _removeSelectedSongs() {
    if (selectedSongs.isEmpty) return;

    setState(() {
      // Remove selected songs from queue
      List<SongsModel> newQueue = [];
      for (int i = 0; i < queueSongs.length; i++) {
        if (!selectedSongs.contains(i)) {
          newQueue.add(queueSongs[i]);
        }
      }
      queueSongs = newQueue;
      selectedSongs.clear();
    });

    // Update music service
    musicService.setPlaylist(queueSongs);
  }

  void _removeSongAtIndex(int index) {
    if (index < 0 || index >= queueSongs.length) return;

    setState(() {
      queueSongs.removeAt(index);
    });

    // Update music service with new queue
    musicService.setPlaylist(queueSongs);
  }

  void _reorderSongs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final SongsModel item = queueSongs.removeAt(oldIndex);
      queueSongs.insert(newIndex, item);
    });
    // Update music service with new order
    musicService.setPlaylist(queueSongs);
  }

  void _toggleShuffle() async {
    if (queueSongs.isEmpty) return;

    // Get current playing song info before shuffling
    final currentSongId = musicService.currentSongId;
    final wasPlaying = musicService.isPlaying;

    if (!isShuffleEnabled) {
      // Enable shuffle - rearrange the queue
      final shuffledSongs = List<SongsModel>.from(queueSongs);
      shuffledSongs.shuffle();

      // Find the position of the currently playing song in the shuffled list
      int startIndex = 0;
      if (currentSongId != null) {
        final currentIndex = shuffledSongs.indexWhere((song) => song.id == currentSongId);
        if (currentIndex >= 0) {
          startIndex = currentIndex;
        } else {
          // If current song not found, pick a random index
          startIndex = (DateTime.now().millisecondsSinceEpoch % shuffledSongs.length);
        }
      } else {
        // If no current song, pick a random index
        startIndex = (DateTime.now().millisecondsSinceEpoch % shuffledSongs.length);
      }

      // Update UI with shuffled order
      setState(() {
        queueSongs = shuffledSongs;
        isShuffleEnabled = true;
      });

      // Enable shuffle mode and set playlist with shuffled order
      await musicService.ensureShuffleOnAndReshuffle();
      await musicService.setPlaylist(shuffledSongs, startIndex: startIndex, autoPlay: wasPlaying);
    } else {
      // Disable shuffle - restore original order
      setState(() {
        isShuffleEnabled = false;
      });

      await musicService.ensureShuffleOff();
      // Reload the original queue order
      _loadQueueSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _removeSelectedSongs,
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
                      Row(
                        children: [
                          SvgPicture.asset(Assets.svgSongsCount),
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
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Repeat mode feature coming soon'),
                                  backgroundColor: AppColors.primaryOrange,
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r)),
                              child: SvgPicture.asset(
                                repeatMode == 'one' ? Assets.svgRepeatOnce : Assets.svgIcRepeat,
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
                      final hasAny = musicService.songs.isNotEmpty;
                      final showMiniPlayer = hasAny;

                      return queueSongs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    Assets.svgIcQueue,
                                    width: 60.w,
                                    height: 60.h,
                                    colorFilter: const ColorFilter.mode(AppColors.mediumDarkGrey, BlendMode.srcIn),
                                  ),
                                  SizedBox(height: 16.h),
                                  Texts("Queue is empty", fontSize: 16.sp, color: AppColors.mediumDarkGrey, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter),
                                  SizedBox(height: 8.h),
                                  Texts(
                                    "Add songs to start playing",
                                    fontSize: 14.sp,
                                    color: AppColors.mediumDarkGrey,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: AppFonts.inter,
                                  ),
                                ],
                              ),
                            )
                          : ReorderableListView.builder(
                              padding: EdgeInsets.only(
                                left: 16.w,
                                right: 16.w,
                                bottom: showMiniPlayer ? 74.h : 10.h, // Space for MiniPlayerBar (which includes system nav bar padding)
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
                                    cardWidth: 50.w,
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
                                    showCancelIcon: true,
                                    cancelIconAsset: Assets.svgCancel,
                                    cancelIconSize: 24.r,
                                    onCancelTap: () => _removeSongAtIndex(index),
                                    onTap: () async {
                                      if(musicService.songs.isNotEmpty && musicService.songs[musicService.currentIndex].id == song.id && musicService.isPlaying){
                                        context.push(
                                          '/dashboard/playing',
                                          extra: PlayingSongArgs(songs: musicService.songs),
                                        );
                                      }
                                      else{
                                        musicService.setPlaylist(queueSongs, startIndex: index);
                                      }
                                    },
                                    onPlayTap: () {
                                      showModalBottomSheet(
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
                                          maxHeight: 0.87.sh,
                                        ),
                                      );
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
            Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayerBar()),
          ],
        ),
      ),
    );
  }
}
