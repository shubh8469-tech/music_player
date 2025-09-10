import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/themes/color.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../generated/assets.dart';
import '../../../../themes/font.dart';

class PlayListScreen extends StatefulWidget {
  const PlayListScreen({super.key});

  @override
  State<PlayListScreen> createState() => _PlayListScreenState();
}

class _PlayListScreenState extends State<PlayListScreen> {

  List<String> categories = ['Most Played', 'Recently Added', 'Recently Added', 'My Favorites'];

  List<String> icons = [Assets.svgMostPlayed, Assets.svgRecentlyAdded, Assets.svgRecentlyAdded, Assets.svgFavorites];

  List<Color> colors = [AppColors.mildOrange, AppColors.mildBlue, AppColors.mildYellow, AppColors.mildPink,];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 30.h, bottom: 1.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SvgPicture.asset(Assets.svgSongsCount),
                  SizedBox(width: 10.w,),
                  Texts('5 Playlists', fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
                  Spacer(),
                  Container(
                    height: 24.h,
                    width: 24.w,
                    decoration: BoxDecoration(
                      color: AppColors.mediumDarkGrey.withAlpha(100),
                      borderRadius: BorderRadius.circular(4.r)
                    ),
                    child: Icon(Icons.add),
                  ),
                  SizedBox(width: 15.w,),
                  SvgPicture.asset(Assets.svgMenuIcon)
                ],
              ),
              SizedBox(height: 33.h,),
              Column(
                children: List.generate(categories.length, (index) {
          
                  return MusicListTile(
                    margin: 7.w,
                    height: 66.h,
                    borderRadius: 10.r,
                    backgroundColor: AppColors.musicTileBackgroundColor,
                    cardHeight: 50.h,
                    cardWidth: 50.w,
                    cardRadius: 7.r,
                    cardIconAsset: icons[index],
                    cardIconSize: 32.r,
                    isSvgCardIcon: icons[index].contains('.svg'),
                    title: categories[index],
                    noLogoGradientColor: [colors[index].withValues(alpha: 0.21), colors[index]],
                    subtitle: '15 Songs',
                    trailingIconAsset: Assets.svgMenuIcon,
                    trailingIconHeight: 15.h,
                    trailingIconWidth: 3.w,
                    trailingMargin: 10.w,
                    songLength: '5:20',
                    songLengthRequired: true,
                    onTap: () => print("Tile tapped"),
                    onPlayTap: () => print("Play tapped"),
                  );
                },),
              ),
              SizedBox(height: 33.h,),
              Texts('My PlayLists (2)', fontSize: 18, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter),
              SizedBox(height: 15.h,),
              Column(
                children: List.generate(2, (index) {
                  return MusicListTile(
                    margin: 7.w,
                    height: 66.h,
                    borderRadius: 10.r,
                    backgroundColor: AppColors.musicTileBackgroundColor,
                    cardHeight: 50.h,
                    cardWidth: 50.w,
                    cardRadius: 7.r,
                    cardIconAsset: Assets.svgMusicIcon,
                    cardIconSize: 32.r,
                    title: 'Bollywood Hits',
                    subtitle: '23 Songs',
                    trailingIconAsset: Assets.svgMenuIcon,
                    trailingIconHeight: 15.h,
                    trailingIconWidth: 3.w,
                    trailingMargin: 10.w,
                    onTap: () => print("Tile tapped"),
                    onPlayTap: () => print("Play tapped"),
                  );
                },),
              )
            ],
          ),
        ),
      ),
    );
  }
}
