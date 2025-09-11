import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/themes/color.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../generated/assets.dart';
import '../../../../themes/font.dart';

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {

  List<String> folderName = ['Downloads', 'WhatsApp Audio', 'Audio Trimmer'];

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
                  Texts('5 Folders', fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
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
                    cardRadius: 7.r,
                    cardIconAsset: Assets.svgDirectory,
                    cardIconSize: 32.r,
                    isSvgColorNeeded: false,
                    title: folderName[index],
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
