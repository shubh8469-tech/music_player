import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../generated/assets.dart';

class SongsList extends StatefulWidget {
  const SongsList({super.key});

  @override
  State<SongsList> createState() => _SongsListState();
}

class _SongsListState extends State<SongsList> {

  List<Color> colors = [AppColors.mildOrange, AppColors.mildBlue, AppColors.mildPink];

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    alignment: Alignment.center,
                    height: 40.h,
                    width: 165.w,
                    decoration: BoxDecoration(
                      color: AppColors.shuffleBackground,
                      borderRadius: BorderRadius.circular(100.r)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(Assets.svgShuffle, height: 16.79.h, width: 17.77,),
                        SizedBox(width: 10.w,),
                        Texts('Shuffle', fontWeight: AppFontWeights.medium, fontSize: 14.sp, color: AppColors.black)
                      ],
                    ),
                  ),
                  Container(
                    height: 40.h,
                    width: 165.w,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(100.r)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(Assets.svgPlay, height: 16.79.h, width: 17.77,),
                        SizedBox(width: 10.w,),
                        Texts('Play', fontWeight: AppFontWeights.medium, fontSize: 14.sp, color: AppColors.white,)
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25.h,),
              Row(
                children: [
                  SvgPicture.asset(Assets.svgSongsCount),
                  SizedBox(width: 10.w,),
                  Texts('20 Songs', fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
                  Spacer(),
                  SvgPicture.asset(Assets.svgFilter),
                  SizedBox(width: 5.w,),
                  Texts('Song Name', fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
                  SizedBox(width: 15.w,),
                  Icon(Icons.arrow_upward)
                ],
              ),
              SizedBox(height: 35.h,),
              Column(
                children: List.generate(20, (index) {

                  final image = (index % 2 == 0) ? musicIcons[0] : (index % 3 == 0) ? musicIcons[1] : musicIcons[2];
                  final title = (index % 2 == 0) ? songNames[0] : (index % 3 == 0) ? songNames[1] : songNames[2];
                  final subTitle = (index % 2 == 0) ? artistNames[0] : (index % 3 == 0) ? artistNames[1] : artistNames[2];

                  return MusicListTile(
                    margin: 7.w,
                    height: 66.h,
                    borderRadius: 10.r,
                    backgroundColor: AppColors.musicTileBackgroundColor,
                    cardHeight: 50.h,
                    cardWidth: 50.w,
                    cardRadius: 7.r,
                    cardIconAsset: image,//Assets.svgMusicIcon,
                    cardIconSize: 32.r,
                    isSvgCardIcon: image.contains('.svg'),
                    title: title,
                    subtitle: subTitle,
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
