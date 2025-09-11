import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/themes/color.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../generated/assets.dart';
import '../../../../themes/font.dart';

class ArtistListScreen extends StatefulWidget {
  const ArtistListScreen({super.key});

  @override
  State<ArtistListScreen> createState() => _ArtistListScreenState();
}

class _ArtistListScreenState extends State<ArtistListScreen> {

  List<String> musicIcons = [ Assets.pngBand2, Assets.svgMusicIcon, Assets.pngBand,];

  List<String> songNames = [
    "Shape of You",
    "Blinding Lights",
    "Rolling in the Deep",
  ];

  List<String> artistNames = [
    "Ed Sheeran",
    "The Weeknd",
    "Adele",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 30.h, bottom: 1.h),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  SvgPicture.asset(Assets.svgSongsCount),
                  SizedBox(width: 10.w,),
                  Texts('5 Artists', fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
                  Spacer(),
                  SvgPicture.asset(Assets.svgFilter),
                  SizedBox(width: 5.w,),
                  Texts('Name', fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
                  SizedBox(width: 15.w,),
                  Icon(Icons.arrow_upward)
                ],
              ),
              SizedBox(height: 25.h,),

              Column(
                children: List.generate(3, (index) {

                  return MusicListTile(
                    margin: 7.w,
                    height: 66.h,
                    borderRadius: 10.r,
                    backgroundColor: AppColors.musicTileBackgroundColor,
                    cardHeight: 50.h,
                    cardWidth: 50.w,
                    cardRadius: 100.r,
                    cardIconAsset: musicIcons[index],
                    isSvgColorNeeded: false,
                    cardIconSize: 32.r,
                    title: artistNames[index],
                    subtitle: '1 Album - 23 Songs',
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
              )
            ],
          ),
        ),
      ),
    );
  }
}
