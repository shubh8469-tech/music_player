import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/themes/font.dart';

import '../generated/assets.dart';

class GradientCard extends StatelessWidget {
  final double height;
  final double width;
  final List<Color> colors;
  final double borderRadius;
  final String iconAsset;
  final String? title;
  final double iconSize;
  final double margin;
  final bool isSvg;
  final bool isSvgColorNeeded;
  final Color? iconColor;
  final VoidCallback? onTap;

  GradientCard({
    super.key,
    required this.height,
    required this.width,
    required this.colors,
    required this.borderRadius,
    required this.iconAsset,
    required this.iconSize,
    required this.margin,
    this.isSvg = true,
    this.isSvgColorNeeded = true,
    this.iconColor,
    this.onTap,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(right: margin),
            height: height,
            width: width,
            decoration: iconAsset.isEmpty || iconAsset.contains('.svg')
                ? BoxDecoration(
                    gradient: LinearGradient(colors: colors, begin: Alignment.bottomLeft, end: Alignment.topRight),
                    borderRadius: BorderRadius.circular(borderRadius),
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    image: DecorationImage(image: AssetImage(iconAsset)),
                  ),
            child: Center(
              child: iconAsset.isEmpty || iconAsset.contains('.svg')
                  ? SvgPicture.asset(Assets.svgMusicIcon, height: iconSize, width: iconSize)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(borderRadius),
                      child: Image.file(File(iconAsset), fit: BoxFit.cover),
                    ),
            ),
          ),
          if (title != null)
            Container(
              margin: EdgeInsets.only(right: margin, top: 5.h),
              child: Texts(title.toString(), fontFamily: AppFonts.inter, fontWeight: AppFontWeights.medium, fontSize: 14.sp),
            ),
        ],
      ),
    );
  }
}
