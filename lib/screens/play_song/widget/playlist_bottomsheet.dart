import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/themes/font.dart';

import '../../../commonWidgets/MusicListTile.dart';
import '../../../commonWidgets/bottom_button_two.dart';
import '../../../commonWidgets/textWidget.dart';
import '../../../generated/assets.dart';
import '../../../l10n/l10n.dart';
import '../../../themes/color.dart';
import 'create_new_playlist_bottomsheet.dart';

class PlaylistBottomSheet extends StatefulWidget {
  const PlaylistBottomSheet({super.key});

  @override
  _PlaylistBottomSheetState createState() => _PlaylistBottomSheetState();
}

class _PlaylistBottomSheetState extends State<PlaylistBottomSheet> {
  String selectedPlaylist = 'Bollywood Hits';

  final List<Map<String, dynamic>> playlists = [
    {'title': 'Bollywood Hits', 'songs': 3},
    {'title': '90s Songs', 'songs': 6},
  ];

  @override
  Widget build(BuildContext context) {
    final double maxHeight = 0.75.sh;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 10.h, bottom: MediaQuery.of(context).viewInsets.bottom + 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 20.h),
          Texts('Add to playlist', fontSize: 18.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter),
          SizedBox(height: 16.h),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: SvgPicture.asset(Assets.svgIcPlus),
                  title: Texts('Create new playlist', fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter),
                  onTap: () {
                    Navigator.of(context).pop();
                    createNewPlayListWidget();
                  },
                ),
                SizedBox(height: 8.h),
                ...playlists.map((playlist) {
                  final title = playlist['title'];
                  final songs = playlist['songs'];
                  final isSelected = selectedPlaylist == title;

                  return MusicListTile(
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
                    onTap: () => setState(() {
                      selectedPlaylist = title;
                    }),
                    onPlayTap: () => setState(() {
                      selectedPlaylist = title;
                    }),
                  );
                }).toList(),
              ],
            ),
          ),

          SizedBox(height: 12.h),
          BottomButtonTwo(leftBtnTitle: S.of(context).cancel, rightBtnTitle: "Add", lefBtnTap: () {}, rightBtnTap: () {}),
          // Action buttons
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  void createNewPlayListWidget() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      isScrollControlled: true,
      builder: (_) => CreateNewPlaylistBottomSheet(),
    );
  }
}
