import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/screens/play_song/widget/audio_player.dart';
import 'package:music_app/screens/play_song/widget/playlist_bottomsheet.dart';
import 'package:music_app/utills/globals.dart';

import '../../commonWidgets/song_menu_screen.dart';
import '../../commonWidgets/textWidget.dart';
import '../../generated/assets.dart';
import '../../themes/color.dart';
import '../../themes/font.dart';

class PlayingSongScreen extends StatefulWidget {
  const PlayingSongScreen({super.key});

  @override
  State<PlayingSongScreen> createState() => _PlayingSongScreenState();
}

class _PlayingSongScreenState extends State<PlayingSongScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        leadingWidth: 45.w,
        toolbarHeight: 52.h,
        leading: Padding(
          padding: EdgeInsets.only(left: 22.w),
          child: SizedBox(
            width: 26.w,
            height: 26.h,
            child: SvgPicture.asset(Assets.svgIcDownArrow, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
          ),
        ),
        actions: [
          SizedBox(
            width: 40.w,
            height: 40.h,
            child: IconButton(
              onPressed: () {},
              icon: SvgPicture.asset(Assets.svgIcShirt, height: 26.h, width: 26.w),
            ),
          ),
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
                isScrollControlled: true,
                builder: (_) => SongMenuScreen(songMenuList: songPlayingMenuItems,isPlaying: true,),
              );
            },
            icon: SvgPicture.asset(Assets.svgIcDots, height: 26.h, width: 26.w, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(Assets.pngIcframe, width: 300.w, height: 300.w, fit: BoxFit.cover),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
              child: Column(
                children: [
                  songTitlePlaylistWidget(),
                  SizedBox(height: 30.h),
                  songPropertiesWidget(),
                ],
              ),
            ),
            songProgressBarWidget(),
          ],
        ),
      ),
    );
  }

  Widget songTitlePlaylistWidget() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Texts('As It Was', fontSize: 20.sp, color: AppColors.black, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter),
              SizedBox(height: 4.h),
              Texts('Harry Styles', fontSize: 14.sp, color: AppColors.textColor, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            _showPlaylistBottomSheet(context);
          },
          child: SvgPicture.asset(Assets.svgIcPlaylist, width: 30.w, height: 30.h),
        ),
      ],
    );
  }

  void _showPlaylistBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      isScrollControlled: true,
      builder: (_) => PlaylistBottomSheet(),
    );
  }

  Widget songPropertiesWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SvgPicture.asset(Assets.svgIcQueue, width: 28.w, height: 28.h),
          SvgPicture.asset(Assets.svgIcTimer, width: 28.w, height: 28.h),
          SvgPicture.asset(Assets.svgIEquilizerc, width: 28.w, height: 28.h),
          SvgPicture.asset(Assets.svgFav, width: 28.w, height: 28.h),
        ],
      ),
    );
  }

  Widget songProgressBarWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 25.h, horizontal: 12.w),
      child: AudioPlayerWidget(url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'),
    );
  }
}
