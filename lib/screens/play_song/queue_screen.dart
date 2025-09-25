import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/generated/assets.dart';
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
  String repeatMode = 'off'; // 'off', 'all', 'one'
  StreamSubscription<int?>? _indexSubscription;

  @override
  void initState() {
    super.initState();
    musicService = MusicPlayerService();
    _loadQueueSongs();

    // Listen to current index changes to update UI
    _indexSubscription = musicService.currentIndexStream.listen((index) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _indexSubscription?.cancel();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        leadingWidth: 45.w,
        toolbarHeight: 52.h,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: EdgeInsets.only(left: 22.w),
            child: SizedBox(
              width: 26.w,
              height: 26.h,
              child: SvgPicture.asset(
                Assets.svgIcBack,
                colorFilter: const ColorFilter.mode(
                  AppColors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        title: Texts(
          "Playing Queue",
          fontSize: 16.sp,
          color: AppColors.white,
          fontWeight: FontWeight.w500,
          fontFamily: AppFonts.manrope,
        ),
        actions: [
          IconButton(
            onPressed: _removeSelectedSongs,
            icon: SvgPicture.asset(
              Assets.svgIcDelete,
              height: 26.h,
              width: 26.w,
              colorFilter: const ColorFilter.mode(
                AppColors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Queue Controls
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                // Selection info and current playing position
                Row(
                  children: [
                    SvgPicture.asset(Assets.svgSongsCount),
                    SizedBox(width: 8.w),
                    Texts(
                      "${selectedSongs.length}/${queueSongs.length}",
                      fontSize: 14.sp,
                      color: AppColors.textColor,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppFonts.inter,
                    ),
                    if (queueSongs.isNotEmpty &&
                        musicService.currentIndex >= 0) ...[
                      SizedBox(width: 16.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Texts(
                          "${musicService.currentIndex + 1} of ${queueSongs.length}",
                          fontSize: 12.sp,
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppFonts.inter,
                        ),
                      ),
                    ],
                  ],
                ),
                // const Spacer(),
                // Row(
                //   children: [
                //     GestureDetector(
                //       onTap: _toggleShuffle,
                //       child: Container(
                //         padding: EdgeInsets.all(8.w),
                //         decoration: BoxDecoration(
                //           color: isShuffleEnabled
                //               ? AppColors.primaryOrange
                //               : AppColors.shuffleBackground,
                //           borderRadius: BorderRadius.circular(20.r),
                //         ),
                //         child: SvgPicture.asset(
                //           Assets.svgShuffle,
                //           width: 20.w,
                //           height: 20.h,
                //           colorFilter: ColorFilter.mode(
                //             isShuffleEnabled
                //                 ? AppColors.white
                //                 : AppColors.textColor,
                //             BlendMode.srcIn,
                //           ),
                //         ),
                //       ),
                //     ),
                //     SizedBox(width: 12.w),
                //     GestureDetector(
                //       onTap: _toggleRepeat,
                //       child: Container(
                //         padding: EdgeInsets.all(8.w),
                //         decoration: BoxDecoration(
                //           color: isRepeatEnabled
                //               ? AppColors.primaryOrange
                //               : AppColors.shuffleBackground,
                //           borderRadius: BorderRadius.circular(20.r),
                //         ),
                //         child: SvgPicture.asset(
                //           repeatMode == 'one'
                //               ? Assets.svgRepeatOnce
                //               : Assets.svgIcRepeat,
                //           width: 20.w,
                //           height: 20.h,
                //           colorFilter: ColorFilter.mode(
                //             isRepeatEnabled
                //                 ? AppColors.white
                //                 : AppColors.textColor,
                //             BlendMode.srcIn,
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),

          // Queue Songs List
          Expanded(
            child: queueSongs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          Assets.svgIcQueue,
                          width: 60.w,
                          height: 60.h,
                          colorFilter: const ColorFilter.mode(
                            AppColors.mediumDarkGrey,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Texts(
                          "Queue is empty",
                          fontSize: 16.sp,
                          color: AppColors.mediumDarkGrey,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.inter,
                        ),
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
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: queueSongs.length,
                    onReorder: _reorderSongs,
                    itemBuilder: (context, index) {
                      final song = queueSongs[index];
                      final isCurrentlyPlaying =
                          musicService.currentIndex == index;

                      return Container(
                        key: ValueKey(song.id),
                        child: MusicListTile(
                          margin: 7.w,
                          height: 66.h,
                          borderRadius: 10.r,
                          backgroundColor: isCurrentlyPlaying
                              ? AppColors.primaryOrange.withValues(alpha: 0.1)
                              : AppColors.musicTileBackgroundColor,
                          cardHeight: 50.h,
                          cardWidth: 50.w,
                          cardRadius: 7.r,
                          cardIconAsset: song.artwork_path!,
                          cardIconSize: 32.r,
                          title: song.title,
                          subtitle: song.artist,
                          trailingIconAsset: Assets.svgMenuIcon,
                          trailingIconHeight: 15.h,
                          trailingIconWidth: 3.w,
                          trailingMargin: 10.w,
                          songLength: formatDuration(song.duration),
                          songLengthRequired: true,
                          isGifLoad: isCurrentlyPlaying,
                          titleSize: isCurrentlyPlaying ? 16 : 14,
                          titleWeight: isCurrentlyPlaying
                              ? FontWeight.w600
                              : FontWeight.w500,
                          onTap: () async {
                            // Play the selected song
                            musicService.setPlaylist(
                              queueSongs,
                              startIndex: index,
                            );
                          },
                          onPlayTap: () {
                            showModalBottomSheet(
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
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Mini Player Bar
          MiniPlayerBar(),
        ],
      ),
    );
  }
}
