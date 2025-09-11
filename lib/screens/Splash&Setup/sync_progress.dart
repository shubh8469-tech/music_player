import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/themes/color.dart';

import '../../commonWidgets/textWidget.dart';
import '../../generated/assets.dart';
import '../../l10n/l10n.dart';
import '../../themes/font.dart';

class SyncProgress extends StatefulWidget {
  const SyncProgress({super.key});

  @override
  _SyncProgressState createState() => _SyncProgressState();
}

class _SyncProgressState extends State<SyncProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // total time to reach 100%
    )..forward(); // start animation

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) context.go('/dashboard');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(Assets.pngLogo, height: 113.h, width: 113.w),
                  SizedBox(height: 16.h),
                  Texts(
                    S.of(context).musicPlayer,
                    fontSize: 24.sp,
                    fontFamily: AppFonts.manrope,
                    fontWeight: AppFontWeights.semiBold,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0, // 👈 add this to stretch horizontally
              bottom: 100,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 40.w,
                      vertical: 10.h,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Texts(
                              "Scanning files...",
                              fontSize: 14.sp,
                              fontFamily: AppFonts.manrope,
                              fontWeight: AppFontWeights.semiBold,
                              color: Colors.black87,
                            ),
                            Spacer(),
                            Texts(
                              "${(_controller.value * 100).toStringAsFixed(0)}%",
                              fontSize: 14.sp,
                              fontFamily: AppFonts.manrope,
                              fontWeight: AppFontWeights.semiBold,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        LinearProgressIndicator(
                          value: _controller.value, // goes from 0 → 1
                          minHeight: 10.h,
                          backgroundColor: AppColors.mediumDarkGrey,
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
