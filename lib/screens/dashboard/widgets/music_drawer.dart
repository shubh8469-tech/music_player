import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../../../generated/assets.dart';
import '../../../themes/color.dart';
import '../../../themes/font.dart';

enum MusicDrawerAction {
  library,
  settings,
  equalizer,
  sleepTimer,
  theme,
  widgets,
  musicStops,
  removeAds,
}

class MusicDrawer extends StatelessWidget {
  const MusicDrawer({super.key, this.onAction});

  final ValueChanged<MusicDrawerAction>? onAction;

  void _handleTap(BuildContext context, MusicDrawerAction action) {
    Navigator.of(context).pop();
    onAction?.call(action);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 310.w,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Center(
                      child: Image.asset(
                        Assets.pngLogo,
                        width: 50.r,
                        height: 50.r,
                      ),
                    ),
                    SizedBox(width: 24.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MUSIC PLAYER',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontFamily: AppFonts.inter,
                            fontWeight: AppFontWeights.semiBold,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        // Text(
                        //   'Side menu',
                        //   style: TextStyle(
                        //     fontSize: 12.sp,
                        //     fontFamily: AppFonts.inter,
                        //     color: AppColors.textColor.withOpacity(0.6),
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 28.h),
                _buildMenuItem(
                  context,
                  label: 'Library',
                  assetPath: Assets.svgMusicLibrary,
                  action: MusicDrawerAction.library,
                ),
                _buildMenuItem(
                  context,
                  label: 'Settings',
                  assetPath: Assets.svgSetting,
                  action: MusicDrawerAction.settings,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Divider(
                    color: AppColors.mediumDarkGrey.withOpacity(0.5),
                    height: 1,
                  ),
                ),
                _buildMenuItem(
                  context,
                  label: 'Equalizer',
                  assetPath: Assets.svgIEquilizerc,
                  action: MusicDrawerAction.equalizer,
                ),
                _buildMenuItem(
                  context,
                  label: 'Sleep timer',
                  assetPath: Assets.svgIcTimer,
                  action: MusicDrawerAction.sleepTimer,
                ),
                _buildMenuItem(
                  context,
                  label: 'Theme',
                  assetPath: Assets.svgThemeBrush,
                  action: MusicDrawerAction.theme,
                ),
                _buildMenuItem(
                  context,
                  label: 'Widgets',
                  assetPath: Assets.svgWidget,
                  action: MusicDrawerAction.widgets,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Divider(
                    color: AppColors.mediumDarkGrey.withOpacity(0.5),
                    height: 1,
                  ),
                ),
                _buildMenuItem(
                  context,
                  label: 'Music stops playing?',
                  assetPath: Assets.svgMusicStops,
                  action: MusicDrawerAction.musicStops,
                ),
                _buildMenuItem(
                  context,
                  label: 'Remove ads',
                  assetPath: Assets.svgRemoveAds,
                  action: MusicDrawerAction.removeAds,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String label,
    required String assetPath,
    required MusicDrawerAction action,
  }) {
    return InkWell(
      onTap: () => _handleTap(context, action),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: [
            SizedBox(
              height: 25.h,
              width: 25.w,
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: SvgPicture.asset(
                  assetPath,
                  colorFilter: assetPath != Assets.svgThemeBrush ? const ColorFilter.mode(
                    AppColors.black,
                    BlendMode.srcIn,
                  ) : null,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: AppFonts.inter,
                  fontWeight: AppFontWeights.regular,
                  color: AppColors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

