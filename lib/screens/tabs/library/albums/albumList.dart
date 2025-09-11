import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/themes/color.dart';

import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../generated/assets.dart';
import '../../../../themes/font.dart';

class AlbumListScreen extends StatefulWidget {
  const AlbumListScreen({super.key});

  @override
  State<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends State<AlbumListScreen> {

  List<String> albumName = ['Downloads', 'WhatsApp Audio', 'Audio Trimmer', 'WhatsApp Audio'];

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
                  Texts('5 Albums', fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
                  Spacer(),
                  SvgPicture.asset(Assets.svgFilter),
                  SizedBox(width: 5.w,),
                  Texts('Name', fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
                  SizedBox(width: 15.w,),
                  Icon(Icons.arrow_upward)
                ],
              ),
              SizedBox(height: 25.h,),
              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 5.h,
                      crossAxisSpacing: 20.w,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: albumName.length,
                  itemBuilder: (context, index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GradientCard(
                          height: 120.h,
                          width: 120.w,
                          colors: [
                            AppColors.mildOrange.withValues(alpha: 0.21),
                            AppColors.mildOrange
                          ],
                          borderRadius: 13.r,
                          iconAsset: Assets.svgAlbum,
                          iconSize: 66.51.r,
                          onTap: () {
                            print("Most Played tapped!");
                          },
                          margin: 0, // 👈 remove margin for clean alignment
                        ),
                        SizedBox(height: 6.h),
                        SizedBox(
                          width: 118.w,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Texts(
                                      albumName[index],
                                      fontFamily: AppFonts.inter,
                                      fontWeight: AppFontWeights.medium,
                                      fontSize: 14.sp,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Texts(
                                      '17 songs',
                                      fontFamily: AppFonts.inter,
                                      fontWeight: AppFontWeights.regular,
                                      fontSize: 10.sp,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 5.w),
                              SvgPicture.asset(
                                Assets.svgMenuIcon,
                                height: 15.h,
                                width: 15.w, // 👈 fix width, not 3.w
                              ),
                            ],
                          ),
                        )
                      ],
                    );
                  },

                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
