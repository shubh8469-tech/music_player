import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/core/widgets/textWidget.dart';

import '../../generated/assets.dart';
import '../../themes/color.dart';
import '../../themes/font.dart';

/// A single, reusable AppBar used across the app.
///
/// This widget centralises the look & feel (height, typography,
/// default colours, spacing, icons) while still allowing each
/// screen to customise the title, leading widget and actions.
class AppBarWithIconTitle extends StatelessWidget implements PreferredSizeWidget {
  /// Title text shown in the middle/left depending on [centerTitle].
  final String? title;

  /// Whether the default three‑dots action button is shown.
  final bool? isActionBtnDisplay;

  /// Callback for the default three‑dots action button.
  final VoidCallback? onTapAction;

  /// Custom leading widget. If null and [showBackButton] is true,
  /// a default back arrow will be shown.
  final Widget? leading;

  /// Custom action widgets. If null, the legacy "dots" action
  /// controlled by [isActionBtnDisplay] will be used.
  final List<Widget>? actions;

  /// Background colour of the app bar.
  final Color backgroundColor;

  /// Title text colour.
  final Color titleColor;

  /// Whether to show the default back button when [leading] is null.
  final bool showBackButton;

  /// Optional callback when the default back button is tapped.
  /// Falls back to `Navigator.maybePop` if null.
  final VoidCallback? onBack;

  /// Whether the title is centred.
  final bool centerTitle;

  /// Optional elevation for the material AppBar.
  final double elevation;

  const AppBarWithIconTitle({
    super.key,
    this.title,
    this.isActionBtnDisplay,
    this.onTapAction,
    this.leading,
    this.actions,
    this.onBack,
    this.showBackButton = true,
    this.backgroundColor = AppColors.primaryOrange,
    this.titleColor = AppColors.white,
    this.centerTitle = false,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final defaultLeading = showBackButton
        ? IconButton(
            icon: SvgPicture.asset(
              Assets.svgIcBack,
              width: 17.w,
              height: 17.h,
            ),
            onPressed: () {
              if (onBack != null) {
                onBack!();
              } else {
                Navigator.of(context).maybePop();
              }
            },
          )
        : null;

    final defaultActions = <Widget>[
      if (isActionBtnDisplay == true)
        IconButton(
          icon: SvgPicture.asset(
            Assets.svgIcDots,
            height: 30.h,
            width: 30.w,
            colorFilter: const ColorFilter.mode(
              AppColors.white,
              BlendMode.srcIn,
            ),
          ),
          onPressed: onTapAction,
        ),
    ];

    return AppBar(
      titleSpacing: 5,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      elevation: elevation,
      leading: leading ?? defaultLeading,
      title: title == null
          ? null
          : Texts(
              title ?? '',
              fontFamily: AppFonts.manrope,
              fontSize: 16.sp,
              overflow: TextOverflow.ellipsis,
              color: titleColor,
              fontWeight: FontWeight.w500,
            ),
      actions: actions ?? defaultActions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
