import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/themes/font.dart';

import '../../../../commonWidgets/bottom_button_two.dart';
import '../../../../features/albums/bloc/album_bloc.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../themes/color.dart';
import '../../../../utills/globals.dart';

class AlbumSortByBottomSheet extends StatefulWidget {
  final int selectedIndex;
  final int selectedOrder; // 0 = ascending, 1 = descending
  final Function(int, int) onItemSelected; // (sortIndex, orderIndex)

  const AlbumSortByBottomSheet({
    required this.selectedIndex,
    this.selectedOrder = 0, // Default to ascending
    required this.onItemSelected,
    super.key,
  });

  @override
  State<AlbumSortByBottomSheet> createState() => _AlbumSortByBottomSheetState();
}

class _AlbumSortByBottomSheetState extends State<AlbumSortByBottomSheet> {
  late int localSelectedIndex;
  late int localSelectedOrder; // 0 = ascending, 1 = descending

  @override
  void initState() {
    super.initState();
    localSelectedIndex = widget.selectedIndex;
    localSelectedOrder = widget.selectedOrder;
  }

  @override
  Widget build(BuildContext context) {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Container(
      padding: EdgeInsets.only(
        top: 10.h,
        bottom: bottomPadding,
        left: 10.w,
        right: 10.w,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 20.h),
          Texts(
            'Sort By',
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.inter,
          ),
          SizedBox(height: 10.h),

          // Sort Type Options
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(albumSortByItems.length, (index) {
                var item = albumSortByItems[index];
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                  title: Texts(
                    item.title,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.inter,
                    color: index == localSelectedIndex
                        ? AppColors.primaryOrange
                        : AppColors.textColor,
                  ),
                  trailing: SvgPicture.asset(
                    index == localSelectedIndex
                        ? Assets.svgIcRadioCheckl
                        : Assets.svgIcRadioUncheck,
                    height: 20.h,
                    width: 20.w,
                  ),
                  onTap: () {
                    setState(() {
                      localSelectedIndex = index;
                    });
                  },
                );
              }),

              // Divider before Order options
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                child: Divider(
                  color: AppColors.textColor.withOpacity(0.2),
                  thickness: 1,
                ),
              ),

              // Only show Ascending/Descending if not Random
              if (localSelectedIndex != 3) ...[
                // Ascending Option
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                  title: Texts(
                    'Ascending',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.inter,
                    color: localSelectedOrder == 0
                        ? AppColors.primaryOrange
                        : AppColors.textColor,
                  ),
                  trailing: SvgPicture.asset(
                    localSelectedOrder == 0
                        ? Assets.svgIcRadioCheckl
                        : Assets.svgIcRadioUncheck,
                    height: 20.h,
                    width: 20.w,
                  ),
                  onTap: () {
                    setState(() {
                      localSelectedOrder = 0;
                    });
                  },
                ),

                // Descending Option
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                  title: Texts(
                    'Descending',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.inter,
                    color: localSelectedOrder == 1
                        ? AppColors.primaryOrange
                        : AppColors.textColor,
                  ),
                  trailing: SvgPicture.asset(
                    localSelectedOrder == 1
                        ? Assets.svgIcRadioCheckl
                        : Assets.svgIcRadioUncheck,
                    height: 20.h,
                    width: 20.w,
                  ),
                  onTap: () {
                    setState(() {
                      localSelectedOrder = 1;
                    });
                  },
                ),
              ],
            ],
          ),

          SizedBox(height: 20.h),

          // Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: BottomButtonTwo(
              leftBtnTitle: S.of(context).cancel,
              rightBtnTitle: "Done",
              lefBtnTap: () {},
              rightBtnTap: () {
                context.read<AlbumBloc>().add(
                  AlbumEvent.sortAlbums(localSelectedIndex, localSelectedOrder),
                );
                widget.onItemSelected(localSelectedIndex, localSelectedOrder);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                });
              },
            ),
          ),
          SizedBox(height: 25.h),
        ],
      ),
    );
  }
}
