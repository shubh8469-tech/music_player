import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/commonWidgets/textWidget.dart';

import '../generated/assets.dart';
import '../themes/color.dart';
import '../themes/font.dart';

class AppBarWithIconTitle extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  bool? isActionBtnDisplay;
  Function? onTapAction;

  AppBarWithIconTitle({super.key, this.title, this.isActionBtnDisplay, this.onTapAction});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 5,
      title: Texts(title ?? "", fontFamily: AppFonts.manrope, fontSize: 16.sp, color: AppColors.white, fontWeight: FontWeight.w500),
      backgroundColor: AppColors.primaryOrange,
      leading: IconButton(icon: SvgPicture.asset(Assets.svgIcBack, width: 22, height: 22), onPressed: () => Navigator.of(context).maybePop()),
      actions: [
        if (isActionBtnDisplay == true)
          IconButton(
            icon: SvgPicture.asset(Assets.svgIcDots, height: 26.h, width: 26.w, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
            onPressed: () => {onTapAction!()},
          ),
      ],
    );
  }

  // Required by PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
