import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/themes/font.dart';
import '../generated/assets.dart';
import '../l10n/l10n.dart';
import '../model/song_menu_model.dart';
import '../themes/color.dart';
import 'MusicListTile.dart';

class SongMenuScreen extends StatefulWidget {
  final List<SongMenuItem> songMenuList;
  final bool isPlaying;

  const SongMenuScreen({super.key, required this.songMenuList, required this.isPlaying});

  @override
  State<SongMenuScreen> createState() => _SongMenuScreenState();
}

class _SongMenuScreenState extends State<SongMenuScreen> {
  bool keepScreenOn = false;

  @override
  Widget build(BuildContext context) {
    final double maxHeight = 0.87.sh;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.only(top: 10.h, bottom: MediaQuery.of(context).viewInsets.bottom + 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 10.h),
          Flexible(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                    title: "As it Was",
                    subtitle: "5:20 - 120kbps",
                    trailingIconAsset: Assets.svgIcShare,
                    trailingIconHeight: 25.h,
                    trailingIconWidth: 25.w,
                    trailingMargin: 2.w,
                    onTap: () => setState(() {}),
                    onPlayTap: () => setState(() {}),
                    onInfoTap: () => {},
                    leadingIconAsset: Assets.svgIcInfo,
                    leadingIconHeight: 25.h,
                    leadingIconWidth: 25.w,
                    isLeading: true,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.songMenuList.length,
                    itemBuilder: (context, index) {
                      final songItem = widget.songMenuList[index];

                      List<String> dividerAfterTitles = [];
                      if (widget.isPlaying) {
                        dividerAfterTitles = [S.of(context).goToArtist, S.of(context).keepScreenOn, S.of(context).changeCover];
                      } else {
                        dividerAfterTitles = [S.of(context).addToPlaylist, S.of(context).goToArtist, S.of(context).changeCover];
                      }
                      final showDivider = dividerAfterTitles.contains(songItem.title);
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(horizontal: 0.w, vertical: 0.h),
                            leading: SvgPicture.asset(songItem.icon, height: 24, width: 24),
                            title: Texts(songItem.title, fontSize: 16.sp, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
                            trailing: songItem.title == S.of(context).keepScreenOn
                                ? IconButton(
                                    icon: SvgPicture.asset(keepScreenOn ? Assets.svgIcSwitchOn : Assets.svgIcSwitchOff),
                                    onPressed: () {
                                      setState(() {
                                        keepScreenOn = !keepScreenOn;
                                      });
                                    },
                                  )
                                : null,
                            onTap: songItem.title == S.of(context).keepScreenOn
                                ? null
                                : () {
                                    if (songItem.title == 'Edit details') {
                                      context.push('/dashboard/edit-song');
                                    } else {
                                      context.push('/dashboard/playing');
                                    }
                                  },
                          ),
                          if (showDivider)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                              child: Divider(height: 1, thickness: 1, color: AppColors.black.withValues(alpha: .1)),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(80.r),
                      border: Border.all(color: AppColors.black.withValues(alpha: 0.10), width: 1),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                    height: 50.w,
                    child: Texts(
                      S.of(context).cancel,
                      fontSize: 14.sp,
                      align: TextAlign.center,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColor,
                      fontFamily: AppFonts.medium,
                    ),
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
