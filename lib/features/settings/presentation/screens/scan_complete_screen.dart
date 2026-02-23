import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:music_app/core/widgets/app_bar_with_icon_title.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

class ScanCompleteScreen extends StatelessWidget {
  const ScanCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final extra = state.extra;
    
    int addedCount = 0;
    int filteredCount = 0;
    
    if (extra is Map<String, dynamic>) {
      addedCount = extra['addedCount'] as int? ?? 0;
      filteredCount = extra['filteredCount'] as int? ?? 0;
    } else if (extra is int) {
      // Backward compatibility with old format
      addedCount = extra;
      filteredCount = extra;
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: "Scan Music",
        backgroundColor: AppColors.primaryOrange,
        titleColor: AppColors.white,
        centerTitle: false,
        onBack: (){
          context.go('/dashboard');
          context.push('/dashboard/settings');
        },
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 40.h),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                Assets.svgScannedSongs,
                width: 100.w,
                height: 100.h,
              ),
            ),
            // Song count
            Texts(
              "$filteredCount Songs",
              fontSize: 40.sp,
              fontWeight: AppFontWeights.medium,
              fontFamily: AppFonts.inter,
              color: AppColors.textColor,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: ElevatedButton(
            onPressed: () {
              context.go('/dashboard');
              context.push('/dashboard/settings');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.r),
              ),
            ),
            child: Texts(
              "Done",
              fontSize: 16.sp,
              fontWeight: AppFontWeights.medium,
              fontFamily: AppFonts.inter,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

