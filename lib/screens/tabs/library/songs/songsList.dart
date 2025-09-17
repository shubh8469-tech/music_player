import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/app_router.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/screens/play_song/playing_song_screen.dart';
import 'package:music_app/screens/tabs/library/songs/sort_by_bottomsheet.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import 'package:path/path.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/gradientCard.dart';
import '../../../../features/songs/bloc/songs_bloc.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../utills/globals.dart';
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
  String selectedSong = sortByItems[0].title;

  int selectedIndex = 0; // or -1 if no default selection

  final musicService = MusicPlayerService();

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Listen duration
    musicService.player.durationStream.listen((d) {
      if (d != null) {
        setState(() => _duration = d);
      }
    });

    // Listen position
    musicService.player.positionStream.listen((p) {
      setState(() => _position = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: BlocBuilder<SongsBloc, SongsState>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
            loaded: (songs) {
              if (songs.isEmpty) {
                return const Center(
                  child: Text(
                    "No songs available",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
                                Container(
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
                                Container(
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
                                      Texts('20 Songs', fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
                                    ],
                                  ),
                                ),
                                Spacer(),
                                SvgPicture.asset(Assets.svgFilter),
                                SizedBox(width: 5.w),
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      backgroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
                                      isScrollControlled: true,
                                      builder: (_) =>
                                          SortByBottomSheet(
                                            selectedIndex: selectedIndex,
                                            onItemSelected: (index) {
                                              setState(() {
                                                selectedIndex = index;
                                                selectedSong = sortByItems[index].title; // Optional: update selected song title
                                              });
                                            },
                                          ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Texts(selectedSong, fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
                                      SizedBox(width: 15.w),
                                      Icon(Icons.arrow_upward),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 35.h),
                            Column(
                              children: List.generate(songs.length, (index) {
                                final image = (index % 2 == 0)
                                    ? musicIcons[0]
                                    : (index % 3 == 0)
                                    ? musicIcons[1]
                                    : musicIcons[2];
                                final title = (index % 2 == 0)
                                    ? songNames[0]
                                    : (index % 3 == 0)
                                    ? songNames[1]
                                    : songNames[2];
                                final subTitle = (index % 2 == 0)
                                    ? artistNames[0]
                                    : (index % 3 == 0)
                                    ? artistNames[1]
                                    : artistNames[2];

                                return MusicListTile(
                                  margin: 7.w,
                                  height: 66.h,
                                  borderRadius: 10.r,
                                  backgroundColor: AppColors.musicTileBackgroundColor,
                                  cardHeight: 50.h,
                                  cardWidth: 50.w,
                                  cardRadius: 7.r,
                                  cardIconAsset: image,
                                  //Assets.svgMusicIcon,
                                  cardIconSize: 32.r,
                                  isSvgCardIcon: image.contains('.svg'),
                                  title: title,
                                  subtitle: subTitle,
                                  trailingIconAsset: Assets.svgMenuIcon,
                                  trailingIconHeight: 15.h,
                                  trailingIconWidth: 3.w,
                                  trailingMargin: 10.w,
                                  songLength: '5:20',
                                  songLengthRequired: true,
                                  isGifLoad: index == 1 ? true : false,
                                  onTap: () async {
                                    final musicService = MusicPlayerService();
                                    await musicService.setPlaylist(["/storage/emulated/0/Download/apartment-buzzer-doorbell-sound-325245.mp3"]);
                                  },
                                  onPlayTap: () => print("Play tapped"),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push(
                        '/dashboard/playing',
                        extra: PlayingSongArgs(songs: ["/storage/emulated/0/Download/apartment-buzzer-doorbell-sound-325245.mp3"], currentIndex: 0),
                      );
                    },
                    child: Column(
                      children: [
                        StreamBuilder<Duration>(
                          stream: musicService.player.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            final total = musicService.player.duration ?? Duration.zero;

                            double progress = (total.inMilliseconds > 0) ? position.inMilliseconds / total.inMilliseconds : 0.0;

                            if (progress >= 1.0) progress = 0.0;

                            return LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                            );
                          },
                        ),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  GradientCard(
                                    height: 50.h,
                                    width: 50.w,
                                    borderRadius: 10.r,
                                    iconAsset: musicIcons[2],
                                    iconSize: 40.r,
                                    isSvg: false,
                                    onTap: () {
                                      print("Most Played tapped!");
                                    },
                                    margin: 10.w,
                                    colors: [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.mildOrange],
                                  ),
                                  Container(
                                    color: AppColors.white.withValues(alpha: .4),
                                    height: 55,
                                    width: 55,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                                      child: Image.asset(Assets.pngSongPlaying, fit: BoxFit.cover, height: 55, width: 55),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 5.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Texts(songNames[2], fontSize: 14.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter),
                                  Texts(artistNames[2], fontSize: 8.sp, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  SvgPicture.asset(Assets.svgIcQueue, width: 24.w, height: 24.h),
                                  SizedBox(width: 20.w),
                                  GestureDetector(
                                    onTap: () {
                                      musicService.next();
                                    },
                                    child: SvgPicture.asset(Assets.svgIcPlayingNext, width: 24.w, height: 24.h),
                                  ),
                                  SizedBox(width: 20.w),
                                  GestureDetector(
                                    onTap: () async {
                                      if (musicService.isPlaying) {
                                        await musicService.pause();
                                      } else {
                                        await musicService.play();
                                      }
                                      setState(() {});
                                    },
                                    child: StreamBuilder<PlayerState>(
                                      stream: musicService.player.playerStateStream,
                                      builder: (context, snapshot) {
                                        final state = snapshot.data;
                                        final isPlaying = state?.playing ?? false;
                                        final isCompleted = state?.processingState == ProcessingState.completed;

                                        if (isPlaying) {
                                          return SvgPicture.asset(Assets.svgIcOverlayPause, width: 26.w, height: 24.h);
                                        } else {
                                          return SvgPicture.asset(
                                            Assets.svgPlay,
                                            width: 18.w,
                                            height: 18.h,
                                            colorFilter: const ColorFilter.mode(AppColors.primaryOrange, BlendMode.srcIn),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              // Controls
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          );
        },
      ),
    );
  }
}
