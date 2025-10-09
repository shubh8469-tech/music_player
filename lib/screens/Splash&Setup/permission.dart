import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../commonWidgets/buton.dart';
import '../../commonWidgets/textWidget.dart';
import '../../core/di/injection.dart';
import '../../core/services/app_state_service.dart';
import '../../generated/assets.dart';
import '../../themes/color.dart';
import '../../themes/font.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  void permissionLib() async {
    if (Platform.isAndroid) {
      PermissionStatus status;
      if (await Permission.storage.isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.audio.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      }

      if (status.isGranted) {
        // Save permission granted state
        final appStateService = locator<AppStateService>();
        await appStateService.setPermissionGranted(true);

        if (mounted) context.go('/sync');
      }
    }
  }

  @override
  void initState() {
    permissionLib();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.17),
            Image.asset(
              Assets.pngMusicDirectory,
              height: 74.h,
              width: 64.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 25.h),
            Texts(
              'Permission Required',
              fontFamily: AppFonts.manrope,
              fontWeight: AppFontWeights.bold,
              fontSize: 20.sp,
            ),
            SizedBox(height: 17.h),
            Texts(
              'To play your songs, we need permission to access music files stored on your device.',
              fontFamily: AppFonts.inter,
              fontWeight: AppFontWeights.regular,
              fontSize: 14.sp,
            ),
            SizedBox(height: 25.h),
            Texts(
              'This allows the app to:',
              fontFamily: AppFonts.inter,
              fontWeight: AppFontWeights.semiBold,
              fontSize: 16.sp,
            ),
            SizedBox(height: 20.h),
            Column(
              children: [
                Row(
                  children: [
                    checkIconWidget(),
                    SizedBox(width: 5.w),
                    Texts(
                      'Detect and list your offline music files',
                      fontFamily: AppFonts.inter,
                      fontWeight: AppFontWeights.regular,
                      fontSize: 14.sp,
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    checkIconWidget(),
                    SizedBox(width: 5.w),
                    Texts(
                      'Play songs stored on your device',
                      fontFamily: AppFonts.inter,
                      fontWeight: AppFontWeights.regular,
                      fontSize: 14.sp,
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    checkIconWidget(),
                    SizedBox(width: 5.w),
                    Texts(
                      'Keep your playlists organized automatically',
                      fontFamily: AppFonts.inter,
                      fontWeight: AppFontWeights.regular,
                      fontSize: 14.sp,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 45.h),
            Center(
              child: OvalButton(
                text: "Open Settings",
                onPressed: () async {
                  if (Platform.isAndroid) {
                    PermissionStatus status;
                    if (await Permission.storage.isGranted) {
                      status = PermissionStatus.granted;
                    } else {
                      status = await Permission.audio.request();
                      if (!status.isGranted) {
                        status = await Permission.storage.request();
                      }
                    }

                    if (!status.isGranted) {
                      openAppSettings();
                      return;
                    } else {
                      // Save permission granted state
                      final appStateService = locator<AppStateService>();
                      await appStateService.setPermissionGranted(true);

                      if (mounted) context.go('/sync');
                    }
                  }
                  // context.go('/sync'); // 🔹 Navigate as before
                },
                backgroundColor: AppColors.primaryOrange,
                textColor: AppColors.white,
                borderRadius: 50.r,
                height: 48.h,
                width: 343.w,
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget checkIconWidget() => Icon(
    Icons.check_circle_outline,
    color: AppColors.primaryOrange,
    size: 20.sp,
  );
}
