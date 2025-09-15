import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/model/song_menu_model.dart';
import 'package:music_app/themes/font.dart';

import '../../../../commonWidgets/bottom_button_two.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../utills/globals.dart';

class SortByBottomSheet extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SortByBottomSheet({required this.selectedIndex, required this.onItemSelected, super.key});

  @override
  State<SortByBottomSheet> createState() => _SortByBottomSheetState();
}

class _SortByBottomSheetState extends State<SortByBottomSheet> {

  SongMenuItem? songItem;
  late int localSelectedIndex;


  @override
  void initState() {
    super.initState();
    localSelectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = 0.60.sh;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.only(top: 10.h, bottom: MediaQuery.of(context).viewInsets.bottom + 16.h, left: 10.w, right: 10.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 20.h),
          Texts('Sort By', fontSize: 18.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter),
          SizedBox(height: 10.h),
          Flexible(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: sortByItems.length,
                    itemBuilder: (context, index) {
                      var songItem = sortByItems[index];
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(horizontal: 0.w, vertical: 0.h),
                            title: Texts(songItem.title, fontSize: 16.sp, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
                            trailing: SvgPicture.asset(index == localSelectedIndex  ? Assets.svgIcRadioCheckl : Assets.svgIcRadioUncheck, height: 20, width: 20),
                            onTap: () {


                                setState(() {
                                  localSelectedIndex = index;
                                });

                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: BottomButtonTwo(
                    leftBtnTitle: S.of(context).cancel,
                    rightBtnTitle: "Done",
                    lefBtnTap: () {},
                    rightBtnTap: () {
                      widget.onItemSelected(localSelectedIndex);
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25.h),
        ],
      ),
    );
  }
}
