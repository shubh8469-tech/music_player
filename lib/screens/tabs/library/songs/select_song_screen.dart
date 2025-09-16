import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/commonWidgets/delete_song_bottomsheet.dart';
import 'package:music_app/themes/font.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/app_bar_with_icon_title.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../commonWidgets/text_field_widget.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../themes/color.dart';
import '../../../../utills/snack_bar.dart';
import '../../../play_song/widget/playlist_bottomsheet.dart';

class SelectSongScreen extends StatefulWidget {
  const SelectSongScreen({super.key});

  @override
  State<SelectSongScreen> createState() => _SelectSongScreenState();
}

class _SelectSongScreenState extends State<SelectSongScreen> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool? isSelectedAll = false;
  final List<Map<String, dynamic>> playlists = [
    {'title': 'Bollywood Hits', 'songs': 3, 'isCheck': false},
    {'title': 'Rolling in the deep', 'songs': 3, 'isCheck': false},
    {'title': 'Bollywood Hits', 'songs': 3, 'isCheck': false},
    {'title': 'super Hits', 'songs': 3, 'isCheck': false},
    {'title': '90s Songs', 'songs': 6, 'isCheck': false},
    {'title': 'hollywood Songs', 'songs': 6, 'isCheck': false},
    {'title': 'bollywood Songs', 'songs': 6, 'isCheck': false},
    {'title': 'Garba Songs', 'songs': 6, 'isCheck': false},
    {'title': '90s Songs', 'songs': 6, 'isCheck': false},
  ];

  int get selectedCount => playlists.where((pData) => pData['isCheck'] == true).length;

  @override
  void initState() {
    super.initState();
    isSelectedAll = playlists.every((p) => p['isCheck'] == true);
  }

  void updateSelectAllState() {
    final allSelected = playlists.every((pData) => pData['isCheck'] == true);
    setState(() {
      isSelectedAll = allSelected;
    });
  }

  // Select All
  void toggleSelectAll() {
    final newValue = !isSelectedAll!;
    setState(() {
      for (var playlist in playlists) {
        playlist['isCheck'] = newValue;
      }
      isSelectedAll = newValue;
    });
  }

  //  individual selection
  void toggleSelection(int index) {
    setState(() {
      playlists[index]['isCheck'] = !(playlists[index]['isCheck'] as bool);
      updateSelectAllState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithIconTitle(title: S.of(context).selectSongs, isActionBtnDisplay: true, onTapAction: () {}),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
              child: Container(
                height: 48,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r), color: AppColors.black.withValues(alpha: .14)),
                child: TextFormField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Padding(padding: EdgeInsets.only(left: 14, right: 10), child: SvgPicture.asset(Assets.svgIcSerach)),
                    hintText: S.of(context).selectSongs,
                    hintStyle: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
              child: Row(
                children: [
                  Expanded(
                    child: Texts(
                      selectedCount != 0 ? "$selectedCount ${S.of(context).selected}" : "",
                      fontSize: 14.sp,
                      fontFamily: AppFonts.inter,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: toggleSelectAll,
                    child: SvgPicture.asset(isSelectedAll == true ? Assets.svgIcRadioCheckl : Assets.svgIcRadioUncheck, height: 20, width: 20),
                  ),
                  SizedBox(width: 10),
                  Texts(S.of(context).selectAll, fontSize: 14.sp, fontFamily: AppFonts.inter, fontWeight: FontWeight.w400, color: AppColors.textColor),
                ],
              ),
            ),
            ...playlists.asMap().entries.map((entry) {
              final index = entry.key;
              final playlist = entry.value;
              final title = playlist['title'];
              final songs = playlist['songs'];
              final isSelected = playlist['isCheck'] as bool;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: MusicListTile(
                  margin: 7.w,
                  height: 66.h,
                  borderRadius: 10.r,
                  backgroundColor: AppColors.musicTileBackgroundColor,
                  cardHeight: 50.h,
                  cardWidth: 50.w,
                  cardRadius: 7.r,
                  noLogoGradientColor: [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.primaryOrange],
                  cardIconAsset: Assets.svgMusicIcon,
                  cardIconSize: 32.r,
                  title: title,
                  subtitle: "$songs Songs",
                  trailingIconAsset: isSelected ? Assets.svgIcCheck : Assets.svgIcUncheck,
                  trailingIconHeight: 20.h,
                  trailingIconWidth: 10.w,
                  trailingMargin: 2.w,
                  onTap: () => toggleSelection(index),
                  onPlayTap: () => toggleSelection(index),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(mainAxisSize: MainAxisSize.min, children: [SvgPicture.asset(Assets.svgIcNavPlay), SizedBox(height: 3), Texts(S.of(context).play)]),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
                    isScrollControlled: true,
                    builder: (_) => PlaylistBottomSheet(),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [SvgPicture.asset(Assets.svgIcNavPlaylist), SizedBox(height: 3), Texts(S.of(context).addToPlaylist)],
                ),
              ),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
                    isScrollControlled: true,
                    builder: (_) => DeleteSongBottomSheet(songCount: selectedCount,isLeftBtnTap: (){},isRightBtnTap: (){
                      showSnackBar(
                        context, () {},
                        message: "Delete Songs successfully!",
                        alertBannerLocation: AlertBannerLocation.bottom
                      );
                    },),
                  );
                },
                child: Column(mainAxisSize: MainAxisSize.min, children: [SvgPicture.asset(Assets.svgIcNavDelete), SizedBox(height: 3), Texts(S.of(context).delete)]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
