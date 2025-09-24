import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/screens/play_song/widget/audio_player.dart';
import 'package:music_app/screens/play_song/widget/playlist_bottomsheet.dart';
import 'package:music_app/utills/globals.dart';

import '../../commonWidgets/gradientCard.dart';
import '../../commonWidgets/song_menu_screen.dart';
import '../../commonWidgets/textWidget.dart';
import '../../features/songs/data/models/song_model.dart';
import '../../generated/assets.dart';
import '../../themes/color.dart';
import '../../themes/font.dart';
import '../tabs/music_service.dart';

class PlayingSongArgs {
  final List<SongsModel> songs;

  PlayingSongArgs({required this.songs});
}

class PlayingSongScreen extends StatefulWidget {
  const PlayingSongScreen({super.key, required this.songs});

  final List<SongsModel> songs;

  @override
  State<PlayingSongScreen> createState() => _PlayingSongScreenState();
}

class _PlayingSongScreenState extends State<PlayingSongScreen> {
  late MusicPlayerService musicService;
  late final bool hasArtwork;
  StreamSubscription<int?>? _indexSubscription;

  @override
  void initState() {
    super.initState();
    musicService = MusicPlayerService();

    // Only set playlist if mini player has no songs
    if (musicService.songs.isEmpty || musicService.songs != widget.songs) {
      musicService.setPlaylist(widget.songs);
    }
    _indexSubscription = musicService.currentIndexStream.listen((index) {
      if (mounted) {
        setState(() {
          // Just trigger rebuild so UI reflects new song
        });
      }
    });
    final path = musicService.songs.isNotEmpty && musicService.currentIndex >= 0
        ? musicService.songs[musicService.currentIndex].artwork_path
        : null;

    hasArtwork = path != null && path.isNotEmpty && File(path).existsSync();
  }

  @override
  void dispose() {
    _indexSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong =
        (musicService.songs.isNotEmpty && musicService.currentIndex >= 0)
            ? musicService.songs[musicService.currentIndex]
            : null;

    print("currentSong?.artwork_path---->${currentSong?.artwork_path}");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        leadingWidth: 45.w,
        toolbarHeight: 52.h,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: EdgeInsets.only(left: 22.w),
            child: SizedBox(
              width: 26.w,
              height: 26.h,
              child: SvgPicture.asset(Assets.svgIcDownArrow,
                  colorFilter:
                      const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: 40.w,
            height: 40.h,
            child: IconButton(
              onPressed: () {},
              icon: SvgPicture.asset(Assets.svgIcShirt,
                  height: 26.h, width: 26.w),
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(40.r))),
                isScrollControlled: true,
                builder: (_) => SongMenuScreen(
                    songMenuList: songPlayingMenuItems, isPlaying: true),
              );
            },
            icon: SvgPicture.asset(Assets.svgIcDots,
                height: 26.h,
                width: 26.w,
                colorFilter:
                    const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 30.h),
          child: Column(
            children: [
              hasArtwork
                  ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.w),
                    child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9.r),
                      child: Image.file(File(currentSong!.artwork_path!),
                          width: 250.w, height: 250.w, fit: BoxFit.cover),
                    ),
                  )
                  : Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.w,),
                    child: GradientCard(
                        width: 250.w,
                        height: 250.w,
                        borderRadius: 10.r,
                        iconAsset: Assets.svgMusicIcon,
                        iconSize: 100.r,
                        isSvg: false,
                        margin: 10.w,
                        colors: [
                          AppColors.mildOrange.withValues(alpha: 0.21),
                          AppColors.mildOrange
                        ],
                      ),
                  ),
              SizedBox(height: 30.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 17.w),
                child: Column(
                  children: [
                    songTitlePlaylistWidget(currentSong),
                    SizedBox(height: 80.h),
                    songPropertiesWidget(),
                  ],
                ),
              ),
              SizedBox(height: 15.h),
              songProgressBarWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget songTitlePlaylistWidget(SongsModel? currentSong) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Texts(
                currentSong?.title ?? '',
                fontSize: 20.sp,
                color: AppColors.black,
                fontWeight: FontWeight.w500,
                fontFamily: AppFonts.inter,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Texts(
                currentSong?.artist.isNotEmpty == true
                    ? currentSong!.artist
                    : 'Unknown Artist',
                fontSize: 14.sp,
                color: AppColors.textColor,
                fontWeight: FontWeight.w400,
                fontFamily: AppFonts.inter,
              ),
            ],
          ),
        ),
        SizedBox(width: 15.w),
        GestureDetector(
          onTap: () {
            _showPlaylistBottomSheet(context, currentSong);
          },
          child: SvgPicture.asset(Assets.svgIcPlaylist,
              width: 32.w, height: 32.h),
        ),
      ],
    );
  }

  void _showPlaylistBottomSheet(BuildContext context, SongsModel? currentSong) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
      isScrollControlled: true,
      builder: (_) => PlaylistBottomSheet(
        songId: currentSong!.id!,
      ),
    );
  }

  Widget songPropertiesWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SvgPicture.asset(Assets.svgIcQueue, width: 23.w, height: 23.h),
        SvgPicture.asset(Assets.svgIcTimer, width: 23.w, height: 23.h),
        SvgPicture.asset(Assets.svgIEquilizerc, width: 23.w, height: 23.h),
        SvgPicture.asset(Assets.svgFav, width: 23.w, height: 23.h),
      ],
    );
  }

  Widget songProgressBarWidget() {
    return AudioPlayerWidget();
  }
}
