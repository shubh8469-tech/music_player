import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/themes/font.dart';

import '../generated/assets.dart';
import '../themes/color.dart';

class GradientCard extends StatelessWidget {
  final double height;
  final double width;
  final List<Color> colors;
  final double borderRadius;
  final String iconAsset;
  final Widget? content;
  final String? title;
  final double? titleSize;
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
    this.content,
    this.isSvg = true,
    this.isSvgColorNeeded = true,
    this.iconColor,
    this.onTap,
    this.title,
    this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    final Widget childWidget =
        content ??
        ((iconAsset.isEmpty || iconAsset.contains('.svg'))
            ? SvgPicture.asset(iconAsset.isEmpty ? Assets.svgMusicIcon : iconAsset, height: iconSize, width: iconSize)
            : (iconAsset.contains('.gif'))
            ? Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(7.r), color: AppColors.white.withValues(alpha: .4)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 5.h),
                  child: Image.asset(Assets.pngSongPlaying, fit: BoxFit.contain, height: height, width: width),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Image.file(File(iconAsset), fit: BoxFit.cover, height: height, width: width),
              ));

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          borderRadius == 100.r
              ? CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Container(
                    margin: EdgeInsets.only(right: margin),
                    height: height,
                    width: width,
                    decoration: (iconAsset.isEmpty || iconAsset.contains('.svg')) && !iconAsset.contains('directory')
                        ? BoxDecoration(
                            gradient: LinearGradient(colors: colors, begin: Alignment.bottomLeft, end: Alignment.topRight),
                            borderRadius: BorderRadius.circular(borderRadius),
                          )
                        : BoxDecoration(borderRadius: BorderRadius.circular(borderRadius)),
                    child: Center(child: childWidget),
                  ),
                )
              : Container(
                  margin: EdgeInsets.only(right: margin),
                  height: height,
                  width: width,
                  decoration: (iconAsset.isEmpty || iconAsset.contains('.svg')) && !iconAsset.contains('directory')
                      ? BoxDecoration(
                          gradient: LinearGradient(colors: colors, begin: Alignment.bottomLeft, end: Alignment.topRight),
                          borderRadius: BorderRadius.circular(borderRadius),
                        )
                      : BoxDecoration(borderRadius: BorderRadius.circular(borderRadius)),
                  child: Center(child: childWidget),
                ),
          if (title != null)
            Container(
              margin: EdgeInsets.only(right: margin, top: 5.h),
              child: Texts(title.toString(), fontFamily: AppFonts.inter, fontWeight: AppFontWeights.medium, fontSize: titleSize ?? 14.sp),
            ),
        ],
      ),
    );
  }
}
