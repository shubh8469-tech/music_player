import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/folders/domain/entities/folder.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../features/folders/domain/repositories/folder_repository.dart';
import '../../../../generated/assets.dart';
import '../../../../core/di/injection.dart';
import '../widgets/mini_player_bar.dart';

class FolderDetailScreen extends StatefulWidget {
  final Folder folder;
  const FolderDetailScreen({super.key, required this.folder});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  final _repo = locator<FolderRepository>();
  final _player = MusicPlayerService();

  List<SongsModel> _songs = [];

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await _repo.getSongsForFolder(widget.folder.id!);
    _songs = songs.cast<SongsModel>();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textColor),
          onPressed: () => context.pop(),
        ),
        title: Texts(
          widget.folder.name,
          fontSize: 18.sp,
          fontWeight: AppFontWeights.semiBold,
          color: AppColors.textColor,
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset(Assets.svgMenuIcon),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Row(
              children: [
                SvgPicture.asset(Assets.svgSongsCount),
                SizedBox(width: 10.w),
                Texts(
                  '${_songs.length} Songs',
                  fontSize: 14.sp,
                  fontWeight: AppFontWeights.regular,
                  color: AppColors.textColor,
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_songs.isNotEmpty) {
                      await _player.setPlaylist(
                        _songs,
                        startIndex: 0,
                        autoPlay: true,
                      );
                      await _player.play();
                    }
                  },
                  icon: Icon(Icons.play_arrow, size: 20.r),
                  label: Texts(
                    'Play All',
                    fontSize: 14.sp,
                    fontWeight: AppFontWeights.medium,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _songs.isEmpty
                    ? Center(
                      child: Texts(
                        'No songs in this folder',
                        fontSize: 16.sp,
                        color: AppColors.mediumDarkGrey,
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        return MusicListTile(
                          margin: 7.w,
                          height: 66.h,
                          borderRadius: 10.r,
                          backgroundColor: AppColors.musicTileBackgroundColor,
                          cardHeight: 50.h,
                          cardWidth: 50.w,
                          cardRadius: 7.r,
                          cardIconAsset: Assets.svgMusicIcon,
                          cardIconSize: 32.r,
                          title: song.title,
                          subtitle: song.artist,
                          trailingIconAsset: Assets.svgMenuIcon,
                          trailingIconHeight: 22.5.h,
                          trailingIconWidth: 3.w,
                          trailingMargin: 10.w,
                          onTap: () async {
                            await _player.setPlaylist(
                              _songs,
                              startIndex: index,
                              autoPlay: true,
                            );
                            await _player.play();
                          },
                          onPlayTap: () async {
                            await _player.setPlaylist(
                              _songs,
                              startIndex: index,
                              autoPlay: true,
                            );
                            await _player.play();
                          },
                        );
                      },
                    ),
          ),
          MiniPlayerBar(),
        ],
      ),
    );
  }
}
