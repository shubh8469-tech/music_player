import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import '../commonWidgets/app_bar_with_icon_title.dart';
import '../commonWidgets/gradientCard.dart';
import '../generated/assets.dart';
import '../l10n/l10n.dart';
import '../themes/color.dart';

class EditSongDetailsScreen extends StatefulWidget {
  const EditSongDetailsScreen({super.key});

  @override
  State<EditSongDetailsScreen> createState() => _EditSongDetailsScreenState();
}

class _EditSongDetailsScreenState extends State<EditSongDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithIconTitle(title: S.of(context).editDetails),
      body: Container(
        margin: EdgeInsets.symmetric(vertical: 25, horizontal: 15),
        child: Column(
          children: [
            GradientCard(
              height: 100.h,
              width: 100.w,
              colors: [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.primaryOrange],
              borderRadius: 8.r,
              iconAsset: Assets.svgIcTunes,
              iconSize: 80.r,
              title: "",
              onTap: () {},
              margin: 10.w,
            ),
            SizedBox(height: 50),
            Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(80),
                border: Border.all(color: AppColors.black.withValues(alpha: 0.10), width: 1),
              ),
              height: 50,
              width: 150,
              child: Texts("Change Cover", align: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
