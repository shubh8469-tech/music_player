import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

import '../../../../generated/assets.dart';

class SongsList extends StatefulWidget {
  const SongsList({super.key});

  @override
  State<SongsList> createState() => _SongsListState();
}

class _SongsListState extends State<SongsList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 30),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  alignment: Alignment.center,
                  height: 40,
                  width: 165,
                  decoration: BoxDecoration(
                    color: AppColors.shuffleBackground,
                    borderRadius: BorderRadius.circular(100)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(Assets.svgShuffle, height: 16.79, width: 17.77,),
                      SizedBox(width: 10.w,),
                      Texts('Shuffle', fontWeight: AppFontWeights.medium, fontSize: 14.sp, color: AppColors.black)
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 165,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.circular(100)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(Assets.svgPlay, height: 16.79, width: 17.77,),
                      SizedBox(width: 10.w,),
                      Texts('Play', fontWeight: AppFontWeights.medium, fontSize: 14.sp, color: AppColors.white,)
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
