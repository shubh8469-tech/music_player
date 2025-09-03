import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart'; // assuming you already made GradientCard
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
  final List<Color> gradientColors;
  final String cardIconAsset;
  final double cardIconSize;
  final bool isSvgCardIcon;

  // Song Info
  final String title;
  final String subtitle;
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

  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;

  final double? margin;

  const MusicListTile({
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
    required this.gradientColors,
    required this.cardIconAsset,
    required this.cardIconSize,
    this.isSvgCardIcon = true,

    // Texts
    required this.title,
    required this.subtitle,
    this.titleSize = 16,
    this.subtitleSize = 10,
    this.titleWeight = FontWeight.w500,
    this.subtitleWeight = FontWeight.w400,

    // Trailing
    required this.trailingIconAsset,
    required this.trailingIconHeight,
    required this.trailingIconWidth,
    required this.trailingMargin,
    this.isSvg = true,

    this.onTap,
    this.onPlayTap,

    this.margin = 5
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
              GradientCard(
                height: cardHeight,
                width: cardWidth,
                colors: gradientColors,
                borderRadius: cardRadius,
                iconAsset: cardIconAsset,
                iconSize: cardIconSize,
                isSvg: isSvgCardIcon,
                margin: 0,
              ),
              SizedBox(width: spacing.w),

              // Title + Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Texts(
                    title,
                    fontSize: titleSize.sp,
                    fontWeight: titleWeight,
                    fontFamily: AppFonts.inter,
                  ),
                  Texts(
                    subtitle,
                    fontSize: subtitleSize.sp,
                    fontWeight: subtitleWeight,
                    fontFamily: AppFonts.inter,
                  ),
                ],
              ),

              const Spacer(),

              Container(
                margin: EdgeInsets.only(right: trailingMargin),
                child: GestureDetector(
                  onTap: onPlayTap,
                  child: SvgPicture.asset(
                    trailingIconAsset,
                    height: trailingIconHeight,
                    width: trailingIconHeight,
                  )
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
