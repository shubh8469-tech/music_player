import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/commonWidgets/textWidget.dart';

import '../generated/assets.dart';
import '../l10n/l10n.dart';
import '../themes/font.dart';
import 'bottom_button_two.dart';

class DeleteSongBottomSheet extends StatefulWidget {
  final int? songCount;
  final Function isLeftBtnTap;
  final Function isRightBtnTap;

  const DeleteSongBottomSheet({
    super.key,
    this.songCount,
    required this.isLeftBtnTap,
    required this.isRightBtnTap,
  });

  @override
  _DeleteSongBottomSheetState createState() => _DeleteSongBottomSheetState();
}

class _DeleteSongBottomSheetState extends State<DeleteSongBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final double minHeight = 0.32.sh;

    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 10.h,
        bottom: bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 30.h),
          Texts(
            'Delete Song',
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.inter,
          ),
          SizedBox(height: 30.h),
          Texts(
            'Are you sure you want to delete these ${widget.songCount} songs?',
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.inter,
            align: TextAlign.center,
          ),

          SizedBox(height: 25.h),
          BottomButtonTwo(
            leftBtnTitle: S.of(context).cancel,
            rightBtnTitle: S.of(context).delete,
            lefBtnTap: () {
              widget.isLeftBtnTap();
            },
            rightBtnTap: widget.isRightBtnTap(),
          ),
          // Action buttons
        ],
      ),
    );
  }
}
