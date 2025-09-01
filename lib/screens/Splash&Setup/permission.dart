import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../commonWidgets/buton.dart';
import '../../commonWidgets/textWidget.dart';
import '../../generated/assets.dart';
import '../../themes/color.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.17,
            ),
            Image.asset(
              Assets.pngMusicDirectory,
              height: 74.h,
              width: 64.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 25.h,),
            Texts(
              'Permission Required',
              fontWeight: FontWeight.w700,
              fontSize: 20.sp,
            ),
            SizedBox(height: 17.h,),
            Texts(
              'To play your songs, we need permission to access music files stored on your device.',
              fontWeight: FontWeight.w400,
              fontSize: 14.sp,
            ),
            SizedBox(height: 25.h,),
            Texts(
              'This allows the app to:',
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
            ),
            SizedBox(height: 20.h,),
            Column(
              children: [
                Row(
                  children: [
                    checkIconWidget(),
                    SizedBox(width: 5.w,),
                    Texts('Detect and list your offline music files',
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                    )
                  ],
                ),
                SizedBox(height: 10.h,),
                Row(
                  children: [
                    checkIconWidget(),
                    SizedBox(width: 5.w,),
                    Texts('Play songs stored on your device',
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                    )
                  ],
                ),
                SizedBox(height: 10.h,),
                Row(
                  children: [
                    checkIconWidget(),
                    SizedBox(width: 5.w,),
                    Texts('Keep your playlists organized automatically',
                      fontWeight: FontWeight.w400,
                      fontSize: 14.sp,
                    )
                  ],
                )
              ],
            ),

            SizedBox(height: 45.h,),
            Center(
              child: OvalButton(
                text: "Open Settings",
                onPressed: () {
                  print("Button pressed!");
                },
                backgroundColor: AppColors.primaryOrange,
                textColor: AppColors.white,
                borderRadius: 50, // More oval
                height: 48.h,
                width: 343.w,
                icon: Icons.arrow_forward,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget checkIconWidget() => Icon(Icons.check_circle_outline, color: AppColors.primaryOrange, size: 20.sp,);
}
