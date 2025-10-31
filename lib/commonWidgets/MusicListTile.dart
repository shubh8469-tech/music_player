import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart'; // assuming you already made GradientCard
import 'package:music_app/themes/color.dart';
import '../generated/assets.dart';
import 'gradientCard.dart';
import 'textWidget.dart';
import '../themes/font.dart';

class MusicListTile extends StatelessWidget {
  final double height;
  final double borderRadius;
  final Color backgroundColor;

  final double padding;
  final double spacing;

  // Left Gradient Icon
  final double cardHeight;
  final double cardWidth;
  final double cardRadius;
  final List<Color>? noLogoGradientColor;
  final String cardIconAsset;
  final double cardIconSize;
  final bool isSvgCardIcon;
  final bool isSvgColorNeeded;

  // Song Info
  final String title;
  final String subtitle;
  final String songLength;
  final bool songLengthRequired;
  final double titleSize;
  final double subtitleSize;
  final FontWeight titleWeight;
  final FontWeight subtitleWeight;

  // Right Play Icon
  final String trailingIconAsset;
  final double trailingIconHeight;
  final double trailingIconWidth;
  final double trailingMargin;
  final bool isSvg;
  final bool isLeading;
  final bool isGifLoad;

  // info icons for menu
  final String leadingIconAsset;
  final double leadingIconHeight;
  final double leadingIconWidth;
  final double leadingMargin;

  // Optional draggable icon (for queue screen)
  final bool showDraggableIcon;
  final String draggableIconAsset;
  final double draggableIconSize;

  // Optional cancel icon (for queue screen)
  final bool showCancelIcon;
  final String cancelIconAsset;
  final double cancelIconSize;
  final VoidCallback? onCancelTap;

  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onInfoTap;

  final double? margin;

  MusicListTile({
    super.key,
    required this.height,
    required this.borderRadius,
    required this.backgroundColor,
    this.padding = 10,
    this.spacing = 15,

    // Card
    required this.cardHeight,
    required this.cardWidth,
    required this.cardRadius,
    this.noLogoGradientColor,
    required this.cardIconAsset,
    required this.cardIconSize,
    this.isSvgCardIcon = true,
    this.isSvgColorNeeded = true,

    // Texts
    required this.title,
    required this.subtitle,
    this.songLength = '',
    this.titleSize = 16,
    this.subtitleSize = 10,
    this.titleWeight = FontWeight.w500,
    this.subtitleWeight = FontWeight.w400,

    // Trailing
    required this.trailingIconAsset,
    required this.trailingIconHeight,
    required this.trailingIconWidth,
    required this.trailingMargin,

    // leading
    this.leadingIconAsset = '',
    this.leadingIconHeight = 0,
    this.leadingIconWidth = 0,
    this.leadingMargin = 0,

    // Optional icons
    this.showDraggableIcon = false,
    this.draggableIconAsset = '',
    this.draggableIconSize = 24,
    this.showCancelIcon = false,
    this.cancelIconAsset = '',
    this.cancelIconSize = 24,
    this.onCancelTap,

    this.isSvg = true,
    this.isLeading = false,
    this.songLengthRequired = false,
    this.isGifLoad = false,

    this.onTap,
    this.onPlayTap,
    this.onInfoTap,

    this.margin = 5,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: margin!),
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: backgroundColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Optional draggable icon (for queue screen)
              if (showDraggableIcon && draggableIconAsset.isNotEmpty) ...[
                SvgPicture.asset(
                  draggableIconAsset,
                  height: draggableIconSize.h,
                  width: draggableIconSize.w,
                  colorFilter: const ColorFilter.mode(
                    AppColors.black,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: 12.w),
              ],

              Stack(
                children: [
                  GradientCard(
                    height: cardHeight,
                    width: cardWidth,
                    colors:
                        noLogoGradientColor ??
                        [
                          AppColors.mildOrange.withValues(alpha: 0.21),
                          AppColors.mildOrange,
                        ],
                    borderRadius: cardRadius,
                    iconAsset: cardIconAsset,
                    iconSize: cardIconSize,
                    isSvg: isSvgCardIcon,
                    isSvgColorNeeded: isSvgColorNeeded,
                    margin: 0,
                  ),
                  if (isGifLoad)
                    Container(
                      height: cardHeight,
                      width: cardWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: AppColors.white.withValues(alpha: .4),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 5,
                        ),
                        child: Image.asset(
                          Assets.pngSongPlaying,
                          fit: BoxFit.cover,
                          height: 55,
                          width: 55,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: spacing.w),

              // Title + Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Texts(
                      title,
                      fontSize: titleSize.sp,
                      fontWeight: titleWeight,
                      fontFamily: AppFonts.inter,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Texts(
                      subtitle,
                      fontSize: subtitleSize.sp,
                      fontWeight: subtitleWeight,
                      fontFamily: AppFonts.inter,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              SizedBox(width: spacing.w),

              // Show either cancel icon OR duration text (mutually exclusive)
              if (showCancelIcon && cancelIconAsset.isNotEmpty)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCancelTap,
                  child: Container(
                    child: SvgPicture.asset(
                      cancelIconAsset,
                      height: cancelIconSize.h,
                      width: cancelIconSize.w,
                      colorFilter: const ColorFilter.mode(
                        AppColors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                )
              else
                Visibility(
                  visible: songLengthRequired,
                  child: Texts(
                    songLength,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),

              Visibility(
                visible: isLeading,
                child: Container(
                  margin: EdgeInsets.only(right: leadingMargin, left: 15.w),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onInfoTap,
                    child: SvgPicture.asset(
                      leadingIconAsset,
                      height: leadingIconHeight,
                      width: leadingIconWidth,
                    ),
                  ),
                ),
              ),

              Container(
                margin: EdgeInsets.only(right: trailingMargin, left: 15.w),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (onPlayTap != null) {
                      onPlayTap!();
                    }
                  },
                  child: Container(
                    width: trailingIconWidth + 20, // Add extra touch area
                    height: trailingIconHeight + 20,
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      trailingIconAsset,
                      height: trailingIconHeight,
                      width: trailingIconWidth,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
