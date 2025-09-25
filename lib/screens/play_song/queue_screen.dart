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

  @override
  void initState() {
    super.initState();
    musicService = MusicPlayerService();
    _loadQueueSongs();
  }

  void _loadQueueSongs() {
    // Load songs from the current playlist/queue
    setState(() {
      queueSongs = List.from(musicService.songs);
    });
  }

  void _toggleSongSelection(int index) {
    setState(() {
      if (selectedSongs.contains(index)) {
        selectedSongs.remove(index);
      } else {
        selectedSongs.add(index);
      }
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

  void _toggleShuffle() {
    setState(() {
      isShuffleEnabled = !isShuffleEnabled;
    });
    // Implement shuffle logic
  }

  void _toggleRepeat() {
    setState(() {
      switch (repeatMode) {
        case 'off':
          repeatMode = 'all';
          isRepeatEnabled = true;
          break;
        case 'all':
          repeatMode = 'one';
          break;
        case 'one':
          repeatMode = 'off';
          isRepeatEnabled = false;
          break;
      }
    });
    // Implement repeat logic
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
                // Selection info
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
                      final isSelected = selectedSongs.contains(index);
                      final isCurrentlyPlaying =
                          musicService.currentIndex == index;

                      return Container(
                        key: ValueKey(song.id),
                        child: MusicListTile(
                          margin: 7.w,
                          height: 66.h,
                          borderRadius: 10.r,
                          backgroundColor: AppColors
                              .musicTileBackgroundColor,
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
                          songLength: formatDuration(
                            song.duration,
                          ),
                          songLengthRequired: true,
                          // isGifLoad: isCurrent,
                          onTap: () async {

                          },
                          onPlayTap: () => print("Play tapped"),
                        ),
                      );

                      return Container(
                        key: ValueKey(song.id),
                        margin: EdgeInsets.only(bottom: 8.h),
                        child: _buildQueueItem(
                          song,
                          index,
                          isSelected,
                          isCurrentlyPlaying,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(
    SongsModel song,
    int index,
    bool isSelected,
    bool isCurrentlyPlaying,
  ) {
    return GestureDetector(
      onTap: () => _toggleSongSelection(index),
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.1)
              : AppColors.musicTileBackgroundColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            // Reorder handle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: SvgPicture.asset(
                Assets.svgIcDots,
                width: 20.w,
                height: 20.h,
                colorFilter: const ColorFilter.mode(
                  AppColors.mediumDarkGrey,
                  BlendMode.srcIn,
                ),
              ),
            ),

            // Song artwork or icon
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: song.artwork_path != null && song.artwork_path!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: Image.asset(song.artwork_path!, fit: BoxFit.cover),
                    )
                  : SvgPicture.asset(
                      Assets.svgMusicIcon,
                      width: 24.w,
                      height: 24.h,
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
            ),

            SizedBox(width: 12.w),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Texts(
                    song.title,
                    fontSize: 14.sp,
                    color: isCurrentlyPlaying
                        ? AppColors.primaryOrange
                        : AppColors.black,
                    fontWeight: isCurrentlyPlaying
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontFamily: AppFonts.inter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Texts(
                    "${song.artist} - ${song.folder ?? 'Unknown'}",
                    fontSize: 12.sp,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.inter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Action buttons
            Row(
              children: [
                // Remove from queue
                GestureDetector(
                  onTap: () {
                    setState(() {
                      queueSongs.removeAt(index);
                    });
                    musicService.setPlaylist(queueSongs);
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    child: SvgPicture.asset(
                      Assets.svgIcDelete,
                      width: 18.w,
                      height: 18.h,
                      colorFilter: const ColorFilter.mode(
                        AppColors.mediumDarkGrey,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // More options
                GestureDetector(
                  onTap: () {
                    // Show song options menu
                  },
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    child: SvgPicture.asset(
                      Assets.svgIcDots,
                      width: 18.w,
                      height: 18.h,
                      colorFilter: const ColorFilter.mode(
                        AppColors.mediumDarkGrey,
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
    );
  }
}
