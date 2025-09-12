import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/commonWidgets/song_menu_screen.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

import '../../../commonWidgets/MusicListTile.dart';
import '../../../commonWidgets/gradientCard.dart';
import '../../../commonWidgets/textWidget.dart';
import '../../../generated/assets.dart';
import '../../../utills/globals.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  List<String> categories = ['Most Played', 'Recently Added', 'My Favorites'];

  List<String> icons = [Assets.svgMostPlayed, Assets.svgRecentlyAdded, Assets.svgFavorites];

  List<String> musicIcons = [Assets.svgMusicIcon, Assets.pngBand, Assets.pngBand2];

  List<Color> colors = [AppColors.mildOrange, AppColors.mildBlue, AppColors.mildPink];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Texts('Explore Playlists', fontSize: 18.sp, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter),

              SizedBox(height: 13.h),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) {
                    return GradientCard(
                      height: 104.h,
                      width: 104.w,
                      colors: [colors[index].withValues(alpha: 0.21), colors[index]],
                      borderRadius: 13.r,
                      iconAsset: icons[index],
                      iconSize: 40.r,
                      title: categories[index],
                      onTap: () {
                        print("Most Played tapped!");
                      },
                      margin: 10.w,
                    );
                  }),
                ),
              ),

              SizedBox(height: 40.h),

              Row(
                children: [
                  Texts('Recently Played', fontSize: 18, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter),
                  Spacer(),
                  Texts('see all', fontSize: 14, fontWeight: AppFontWeights.regular, fontFamily: AppFonts.inter),
                ],
              ),

              SizedBox(height: 5.h),

              Column(
                children: List.generate(3, (index) {
                  return MusicListTile(
                    margin: 7.w,
                    height: 66.h,
                    borderRadius: 10.r,
                    backgroundColor: AppColors.musicTileBackgroundColor,
                    cardHeight: 50.h,
                    cardWidth: 50.w,
                    cardRadius: 7.r,
                    cardIconAsset: musicIcons[index],
                    cardIconSize: 32.r,
                    isSvgCardIcon: musicIcons[index].contains('.svg'),
                    title: 'Memories',
                    subtitle: 'Artist Name - Folder',
                    trailingIconAsset: Assets.svgPlayLogo,
                    trailingIconHeight: 32.r,
                    trailingIconWidth: 32.r,
                    trailingMargin: 0,
                    onTap: () => print("Tile tapped"),
                    onPlayTap: () => print("Play tapped"),
                  );
                }),
              ),

              SizedBox(height: 38.h),

              Row(
                children: [
                  Texts('My PlayLists', fontSize: 18, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter),
                  Spacer(),
                  Texts('see all', fontSize: 14, fontWeight: AppFontWeights.regular, fontFamily: AppFonts.inter),
                ],
              ),

              SizedBox(height: 5.h),

              MusicListTile(
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
                onTap: () => {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
                    isScrollControlled: true,
                    builder: (_) => SongMenuScreen(songMenuList: songMenuItems,isPlaying: false,),
                  ),
                },
                onPlayTap: () => print("Play tapped"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
