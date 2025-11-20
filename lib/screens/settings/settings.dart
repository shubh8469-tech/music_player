import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../commonWidgets/textWidget.dart';
import '../../generated/assets.dart';
import '../../themes/color.dart';
import '../../themes/font.dart';
import '../../utills/snack_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool keepScreenOn = false;
  bool lockScreenPlaying = false;
  bool pauseOnDetach = false;

  void _showComingSoonSnack() {
    showSnackBar(
      context,
      () {},
      message: "Coming soon",
      alertBannerLocation: AlertBannerLocation.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: AppColors.primaryOrange,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Texts(
          "Settings",
          fontSize: 18.sp,
          fontWeight: AppFontWeights.medium,
          fontFamily: AppFonts.inter,
          color: AppColors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            children: [
              _optionTile(
                asset: Assets.svgPremium,
                title: "Go Premium ✨",
                onTap: _showComingSoonSnack,
              ),
              _optionTile(
                asset: Assets.svgScan,
                title: "Scan music",
                onTap: _showComingSoonSnack,
              ),
              _optionTile(
                asset: Assets.svgHidden,
                title: "Hidden music",
                onTap: (){
                  context.push('/dashboard/hidden-music');
                },
              ),
              _optionTile(
                asset: Assets.svgBackup,
                title: "Backup & restore",
                subtitle: "Last backup: 2025-08-25 13:52:14",
                onTap: _showComingSoonSnack,
              ),
              _sectionDivider(),
              _optionTile(
                asset: Assets.svgBulb,
                title: "Keep screen on",
                subtitle: "Stay on while on the player screen",
                trailing: _buildSwitch(
                  value: keepScreenOn,
                  onChanged: (value) {
                    // setState(() => keepScreenOn = value);
                    _showComingSoonSnack();
                  },
                ),
              ),
              _optionTile(
                asset: Assets.svgLock,
                title: "Lock screen playing",
                subtitle: "Show now playing when lock screen",
                trailing: _buildSwitch(
                  value: lockScreenPlaying,
                  onChanged: (value) {
                    // setState(() => lockScreenPlaying = value);
                    _showComingSoonSnack();
                  },
                ),
              ),
              _optionTile(
                asset: Assets.svgPauseHead,
                title: "Pause on detach",
                subtitle: "Pause playback when headphone is detached",
                trailing: _buildSwitch(
                  value: pauseOnDetach,
                  onChanged: (value) {
                    // setState(() => pauseOnDetach = value);
                    _showComingSoonSnack();
                  },
                ),
              ),
              _sectionDivider(),
              _optionTile(
                asset: Assets.svgFaq,
                title: "FAQs",
                onTap: _showComingSoonSnack,
              ),
              _optionTile(
                asset: Assets.svgFeedback,
                title: "Feedback",
                onTap: _showComingSoonSnack,
              ),
              _optionTile(
                asset: Assets.svgPrivacy,
                title: "Privacy Policy",
                onTap: _showComingSoonSnack,
              ),
              _optionTile(
                asset: Assets.svgTermsDoc,
                title: "Terms of use",
                onTap: _showComingSoonSnack,
              ),
              _optionTile(
                asset: Assets.svgVersion,
                title: "Version",
                subtitle: "3.8.1.541",
                onTap: _showComingSoonSnack,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile({
    required String asset,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          crossAxisAlignment: subtitle != null
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(asset, colorFilter: ColorFilter.mode(AppColors.textColor.withValues(alpha: 0.5), BlendMode.srcIn),),
            SizedBox(width: 17.5.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Texts(
                    title,
                    fontSize: 16.sp,
                    fontWeight: AppFontWeights.medium,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  if (subtitle != null) SizedBox(height: 4.h),
                  if (subtitle != null)
                    Texts(
                      subtitle,
                      fontSize: 12.sp,
                      fontWeight: AppFontWeights.regular,
                      fontFamily: AppFonts.inter,
                      color: AppColors.textColor.withOpacity(0.6),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.white,
      activeTrackColor: AppColors.primaryOrange,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.grey.shade300,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _sectionDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }
}
