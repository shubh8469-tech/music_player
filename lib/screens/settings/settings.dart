import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../commonWidgets/textWidget.dart';
import '../../themes/color.dart';
import '../../themes/font.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Texts("Settings", fontSize: 18.sp, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter, color: AppColors.white),
      ),
      body: Column(
        children: [

        ],
      )
    );
  }

  Widget optionTile(String asset, String title){
    return Container(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          SvgPicture.asset(asset),
          Texts(
            title,
            fontSize: 16.sp,
            fontWeight: AppFontWeights.regular,
            fontFamily: AppFonts.inter,
          ),
        ],
      ),
    );
  }
}
