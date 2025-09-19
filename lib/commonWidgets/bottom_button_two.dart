import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_app/commonWidgets/textWidget.dart';

import '../themes/color.dart';
import '../themes/font.dart';

class BottomButtonTwo extends StatefulWidget {
  final String? leftBtnTitle;
  final String? rightBtnTitle;
  final VoidCallback? lefBtnTap;
  final Function? rightBtnTap;

  const BottomButtonTwo({super.key, this.leftBtnTitle, this.rightBtnTitle, this.lefBtnTap, this.rightBtnTap});

  @override
  State<BottomButtonTwo> createState() => _BottomButtonTwoState();
}

class _BottomButtonTwoState extends State<BottomButtonTwo> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              widget.lefBtnTap!();
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(80.r),
                border: Border.all(color: AppColors.black.withValues(alpha: 0.10), width: 1),
              ),
              height: 50.w,
              width: 160.w,
              child: Texts(
                widget.leftBtnTitle!,
                fontSize: 14.sp,
                align: TextAlign.center,
                fontWeight: FontWeight.w500,
                color: AppColors.textColor,
                fontFamily: AppFonts.medium,
              ),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              widget.rightBtnTap!();
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(80),
                border: Border.all(color: AppColors.black.withValues(alpha: 0.10), width: 1),
              ),
              height: 50.w,
              width: 160.w,
              child: Texts(
                widget.rightBtnTitle!,
                fontSize: 14.sp,
                align: TextAlign.center,
                color: AppColors.white,
                fontWeight: FontWeight.w500,
                fontFamily: AppFonts.medium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
