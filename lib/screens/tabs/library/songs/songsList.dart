import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:music_app/app_router.dart';
import 'package:music_app/commonWidgets/textWidget.dart';

// import 'package:music_app/screens/play_song/playing_song_screen.dart';
import 'package:music_app/screens/tabs/library/songs/sort_by_bottomsheet.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
// import 'package:path/path.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/common_functions.dart';

// import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/song_menu_screen.dart';
import '../../../../features/songs/bloc/songs_bloc.dart';
import '../../../../generated/assets.dart';
import '../../../../utills/globals.dart';
// import '../../../../l10n/l10n.dart';
import '../../../play_song/playing_song_screen.dart';
import '../../music_service.dart';

class SongsList extends StatefulWidget {
  const SongsList({super.key});

  @override
  State<SongsList> createState() => _SongsListState();
}

class _SongsListState extends State<SongsList> {
  List<Color> colors = [AppColors.mildOrange, AppColors.mildBlue, AppColors.mildPink];

  List<String> musicIcons = [Assets.pngBand2, Assets.svgMusicIcon, Assets.pngBand];

  List<String> songNames = ["Shape of You", "Blinding Lights", "Rolling in the Deep"];

  List<String> artistNames = ["Ed Sheeran", "The Weeknd", "Adele"];
  String selectedSongSort = sortByItems[0].title;

  int selectedIndex = 0; // or -1 if no default selection
  int selectedOrder = 0; // 0 = ascending, 1 = descending

  final musicService = MusicPlayerService();

  // The mini player uses player streams; these fields are optional for future UI
  Duration _duration = Duration.zero; // ignore: unused_field
  Duration _position = Duration.zero; // ignore: unused_field
  bool _showMiniPlayer = false; // ignore: unused_field

  late final StreamSubscription<Duration> _positionSub;

  @override
  void initState() {
    super.initState();
    // context.read<SongsBloc>().add(SongsEvent.sortSongs(0, 0));

    // Listen duration
    musicService.player.durationStream.listen((d) {
      if (d != null) {
        if (mounted) {
          setState(() => _duration = d);
        }
      }
    });

    // Listen position
    _positionSub = musicService.player.positionStream.listen((p) {
      if (mounted) {
        setState(() => _position = p);
      }
    });
  }

  @override
  void dispose() {
    _positionSub.cancel(); // cancel subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final progress = _duration.inMilliseconds > 0
    //     ? _position.inMilliseconds / _duration.inMilliseconds
    //     : 0.0;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: BlocBuilder<SongsBloc, SongsState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(
              child: Text(message, style: const TextStyle(color: Colors.red, fontSize: 16)),
            ),
            loaded: (songs) {
              if (songs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          Assets.svgMusicLibrary,
                          height: 64.h,
                          width: 64.w,
                          colorFilter: const ColorFilter.mode(
                            AppColors.textColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Texts(
                          "No songs available",
                          fontSize: 18.sp,
                          fontWeight: AppFontWeights.semiBold,
                          color: AppColors.textColor,
                          align: TextAlign.center,
                        ),
                        SizedBox(height: 12.h),
                        Texts(
                          "If you have hidden songs, you can manage them from the Hidden Music screen.",
                          fontSize: 14.sp,
                          fontWeight: AppFontWeights.regular,
                          color: AppColors.textColor.withValues(alpha: 0.7),
                          align: TextAlign.center,
                        ),
                        SizedBox(height: 24.h),
                        GestureDetector(
                          onTap: () {
                            context.push('/dashboard/hidden-music');
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  Assets.svgIcHide,
                                  height: 18.h,
                                  width: 18.w,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Texts(
                                  "Go to Hidden Music",
                                  fontSize: 14.sp,
                                  fontWeight: AppFontWeights.medium,
                                  color: AppColors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 30.h, bottom: 1.h),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    // final shuffledSongs = List<SongsModel>.from(songs);
                                    // shuffledSongs.shuffle();
                                    // context.read<SongsBloc>().add(SongsEvent.shuffleSongs(shuffledSongs));

                                    if (musicService.currentIndex < 0) {
                                      await musicService.setPlaylist(songs, autoPlay: false, startIndex: 0);
                                      await musicService.play();
                                    } else {
                                      await musicService.setShufflePlaylist(
                                        songs,
                                        autoPlay: false,
                                        startIndex: musicService.currentIndex != -1 ? musicService.currentIndex : 0,
                                      );
                                      await musicService.ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();
                                      await musicService.player.currentIndexStream.firstWhere((idx) => idx != null && idx != 0);
                                      await musicService.play();
                                    }

                                    log("New Shuffle Play started");
                                  },
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 40.h,
                                    width: 165.w,
                                    decoration: BoxDecoration(color: AppColors.shuffleBackground, borderRadius: BorderRadius.circular(100.r)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(Assets.svgShuffle, height: 16.79.h, width: 17.77),
                                        SizedBox(width: 10.w),
                                        Texts('Shuffle', fontWeight: AppFontWeights.medium, fontSize: 14.sp, color: AppColors.black),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    // Ensure shuffle is OFF
                                    await musicService.ensureShuffleOff();

                                    // Play from the first song in order
                                    await musicService.setPlaylist(songs, startIndex: 0);
                                    await musicService.play();

                                    if (mounted) {
                                      setState(() {
                                        _showMiniPlayer = true;
                                      });
                                    }

                                    log("Playing all songs from first position");
                                  },
                                  child: Container(
                                    height: 40.h,
                                    width: 165.w,
                                    decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(100.r)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(Assets.svgPlay, height: 16.79.h, width: 17.77),
                                        SizedBox(width: 10.w),
                                        Texts('Play', fontWeight: AppFontWeights.medium, fontSize: 14.sp, color: AppColors.white),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 25.h),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    context.push('/dashboard/select-song');
                                  },
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(Assets.svgSongsCount),
                                      SizedBox(width: 10.w),
                                      Texts("${songs.length} songs", fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
                                    ],
                                  ),
                                ),
                                Spacer(),
                                // GestureDetector(
                                //   onTap: () {
                                //     context.push('/dashboard/hidden-music');
                                //   },
                                //   child: SvgPicture.asset(
                                //     Assets.svgIcHide,
                                //     height: 20.h,
                                //     width: 20.w,
                                //     colorFilter: const ColorFilter.mode(
                                //       AppColors.textColor,
                                //       BlendMode.srcIn,
                                //     ),
                                //   ),
                                // ),
                                // SizedBox(width: 18.w),
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
                                      isScrollControlled: true,
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<SongsBloc>(),
                                        child: SortByBottomSheet(
                                          selectedIndex: selectedIndex,
                                          selectedOrder: selectedOrder,
                                          onItemSelected: (index, order) {
                                            setState(() {
                                              selectedIndex = index;
                                              selectedOrder = order;
                                              selectedSongSort = sortByItems[index].title; // Optional: update selected song title
                                            });
                                            // Trigger Bloc sort event
                                            context.read<SongsBloc>().add(SongsEvent.sortSongs(index, order));
                                            // Close bottom sheet safely
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (Navigator.canPop(context)) Navigator.pop(context);
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  child: SvgPicture.asset(Assets.svgFilter),
                                  // child: Row(
                                  //   children: [
                                  //     Texts(
                                  //       selectedSongSort,
                                  //       fontSize: 14.sp,
                                  //       fontWeight: AppFontWeights.regular,
                                  //       color: AppColors.textColor,
                                  //     ),
                                  //   ],
                                  // ),
                                ),
                                SizedBox(width: 10.w),
                              ],
                            ),
                            SizedBox(height: 15.h),

                            Column(
                              children: List.generate(songs.length, (index) {
                                return StreamBuilder<int?>(
                                  stream: musicService.currentSongIdStream,
                                  initialData: musicService.currentSongId,
                                  builder: (context, idSnap) {
                                    final currentId = idSnap.data;

                                    return StreamBuilder<bool>(
                                      stream: musicService.isPlayingStream,
                                      initialData: musicService.isPlaying,
                                      builder: (context, playingSnap) {
                                        final isCurrent = (songs[index].id == currentId);
                                        final isPlaying = musicService.isPlaying;

                                        return MusicListTile(
                                          margin: 7.w,
                                          height: 66.h,
                                          borderRadius: 10.r,
                                          backgroundColor: AppColors.musicTileBackgroundColor,
                                          cardHeight: 50.h,
                                          cardWidth: 50.w,
                                          cardRadius: 7.r,
                                          cardIconAsset: songs[index].artwork_path ?? Assets.svgMusicIcon,
                                          cardIconSize: 32.r,
                                          isSvgCardIcon: (songs[index].artwork_path ?? '').contains('.svg') || songs[index].artwork_path == null,
                                          title: songs[index].title,
                                          subtitle: songs[index].artist,
                                          trailingIconAsset: Assets.svgMenuIcon,
                                          trailingIconHeight: 19.5.h,
                                          trailingIconWidth: 3.w,
                                          trailingMargin: 10.w,
                                          songLength: formatDuration(songs[index].duration),
                                          songLengthRequired: true,
                                          isGifLoad: isCurrent,
                                          isPlaying: isPlaying,
                                          onTap: () async {
                                            if (musicService.songs.isNotEmpty &&
                                                musicService.songs[musicService.currentIndex].id == songs[index].id &&
                                                musicService.isPlaying) {
                                              log('song   innnn');
                                              context.push('/dashboard/playing', extra: PlayingSongArgs(songs: musicService.songs));
                                            } else {
                                              log('song   outttt');
                                              await musicService.setPlaylist(songs, startIndex: index);
                                            }
                                          },
                                          onPlayTap: () async {
                                            showModalBottomSheet(
                                              context: context,
                                              backgroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
                                              isScrollControlled: true,
                                              builder: (_) => SongMenuScreen(
                                                songMenuList: songMenuItems,
                                                isPlaying: false,
                                                currentSong: songs[index],
                                                songIndex: index,
                                                songsList: songs,
                                                maxHeight: 0.87.sh,
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              }),
                            ),
                            SizedBox(height: 90.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Mini player is now global in Dashboard
                ],
              );
            },
          );
        },
      ),
    );
  }
}
