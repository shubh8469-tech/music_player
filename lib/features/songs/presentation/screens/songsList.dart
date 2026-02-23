import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

// import 'package:just_audio/just_audio.dart';
// import 'package:music_app/app_router.dart';
import 'package:music_app/core/widgets/textWidget.dart';

// import 'package:music_app/presentation/screens/play_song/playing_song_screen.dart';
import 'package:music_app/features/songs/presentation/screens/sort_by_bottomsheet.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
// import 'package:path/path.dart';

import 'package:music_app/core/widgets/MusicListTile.dart';
import 'package:music_app/core/widgets/common_functions.dart';

// import 'package:music_app/core/widgets/gradientCard.dart';
import 'package:music_app/core/widgets/song_menu_screen.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_event.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_state.dart';
import 'package:music_app/features/songs/presentation/bloc/songs_bloc.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/core/utils/globals.dart';

// import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/core/screens/common/commonTapProvider.dart';
import 'package:music_app/features/music_player/presentation/screens/play_song/playing_song_screen.dart';

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

  // The mini player uses player streams; these fields are optional for future UI
  Duration _duration = Duration.zero; // ignore: unused_field
  Duration _position = Duration.zero; // ignore: unused_field
  bool _showMiniPlayer = false; // ignore: unused_field

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  bool _streamsSubscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_streamsSubscribed && mounted) {
      _streamsSubscribed = true;
      final bloc = context.read<MusicPlayerBloc>();
      _durationSub = bloc.player.durationStream.listen((d) {
        if (d != null && mounted) setState(() => _duration = d);
      });
      _positionSub = bloc.player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
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
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(Assets.svgMusicLibrary, height: 64.h, width: 64.w, colorFilter: const ColorFilter.mode(AppColors.textColor, BlendMode.srcIn)),
                        SizedBox(height: 20.h),
                        Texts("No songs available", fontSize: 18.sp, fontWeight: AppFontWeights.semiBold, color: AppColors.textColor, align: TextAlign.center),
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
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                            decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(24.r)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(Assets.svgIcHide, height: 18.h, width: 18.w, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
                                SizedBox(width: 8.w),
                                Texts("Go to Hidden Music", fontSize: 14.sp, fontWeight: AppFontWeights.medium, color: AppColors.white),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return BlocBuilder<MusicPlayerBloc, MusicPlayerState>(
                buildWhen: (prev, curr) => prev.currentSongId != curr.currentSongId || prev.isPlaying != curr.isPlaying,
                builder: (context, playerState) {
                  return Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 15.w, right: 15.w, top: 30.h, bottom: 1.h),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: context.watch<HoldTheTapFor>().isHoldingShuffle ? null :  () async {
                                        try {
                                          final bloc = context.read<MusicPlayerBloc>();
                                          print('🔀 Shuffle button tapped');
                                          print('Current state - playing: ${bloc.state.isPlaying}, currentIndex: ${bloc.state.currentIndex ?? -1}');

                                          if (songs.isEmpty) return;

                                          context.read<HoldTheTapFor>().startHoldingShuffle();

                                          if ((bloc.state.currentIndex ?? -1) < 0) {
                                            log('shuffle:- Current index is invalid, resetting to 0');
                                            bloc.add(SetPlaylistEvent(songs.map((m) => m.toDomain()).toList(), startIndex: 0, autoPlay: true));
                                            bloc.add(const PlayEvent());
                                          } else {
                                            log('shuffle:- Setting shuffle playlist');
                                            bloc.add(SetShufflePlaylistEvent(songs.map((m) => m.toDomain()).toList(), autoPlay: true));
                                            bloc.add(const EnsureShuffleOnReshuffleIndexEvent());
                                            await bloc.player.currentIndexStream.firstWhere((idx) => idx != null && idx != 0);
                                            bloc.add(const PlayEvent());
                                          }

                                          if (mounted) {
                                            setState(() {
                                              _showMiniPlayer = true;
                                            });
                                          }
                                        } catch (e) {
                                          log("❌ Shuffle error: $e");
                                        }

                                        // if (musicService.currentIndex < 0) {
                                        //   await musicService.setPlaylist(songs, autoPlay: false, startIndex: 0);
                                        //   await musicService.play();
                                        // } else {
                                        //   await musicService.setShufflePlaylist(
                                        //     songs,
                                        //     autoPlay: false,
                                        //     startIndex: musicService.currentIndex != -1 ? musicService.currentIndex : 0,
                                        //   );
                                        //   await musicService.ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();
                                        //   await musicService.player.currentIndexStream.firstWhere((idx) => idx != null && idx != 0);
                                        //   await musicService.play();
                                        // }
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
                                      onTap: context.watch<HoldTheTapFor>().isHoldingPlay ? null : () async {
                                        try {
                                          final bloc = context.read<MusicPlayerBloc>();
                                          if (songs.isEmpty) return;

                                          context.read<HoldTheTapFor>().startHoldingPlay();

                                          if(bloc.state.isPlaying){
                                            context.push('/dashboard/playing', extra: PlayingSongArgs(songs: songs),);
                                          }
                                          else if((bloc.state.currentIndex ?? -1) >= 0){
                                            context.push('/dashboard/playing', extra: PlayingSongArgs(songs: songs),);
                                            bloc.add(const PlayEvent());
                                          }
                                          else{
                                            bloc.add(const EnsureShuffleOffEvent());
                                            bloc.add(SetPlaylistEvent(songs.map((m) => m.toDomain()).toList(), startIndex: 0, autoPlay: true));
                                            if (mounted) {
                                              setState(() {
                                                _showMiniPlayer = true;
                                              });
                                            }
                                          }
                                        } catch (e) {
                                          print('❌ Play error: $e');
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
                                          SizedBox(width: 8.w),
                                          SizedBox(
                                            height: 38.h, // Increase height so padding doesn't zero it out
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 8.h, // Leave some room for the line
                                              ),
                                              child: VerticalDivider(
                                                color: AppColors.mediumDarkGrey.withOpacity(0.5),
                                                width: 1.w, // Total space the widget occupies
                                                thickness: 1.2.w, // The actual thickness of the line
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
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
                                    ),
                                    SizedBox(width: 5.w),
                                  ],
                                ),
                                SizedBox(height: 15.h),

                                Column(
                                  children: List.generate(songs.length, (index) {
                                    final song = songs[index];
                                    final isCurrent = song.id == playerState.currentSongId;
                                    final isPlaying = playerState.isPlaying;

                                    return MusicListTile(
                                      margin: 7.w,
                                      height: 66.h,
                                      borderRadius: 10.r,
                                      backgroundColor: AppColors.musicTileBackgroundColor,
                                      cardHeight: 50.h,
                                      cardWidth: 50.h,
                                      cardRadius: 7.r,
                                      cardIconAsset: song.artwork_path ?? Assets.svgMusicIcon,
                                      cardIconSize: 32.r,
                                      isSvgCardIcon: (song.artwork_path ?? '').contains('.svg') || song.artwork_path == null,
                                      title: song.title,
                                      subtitle: song.artist,
                                      trailingIconAsset: Assets.svgMenuIcon,
                                      trailingIconHeight: 19.5.h,
                                      trailingIconWidth: 3.w,
                                      trailingMargin: 10.w,
                                      songLength: formatDuration(song.duration),
                                      songLengthRequired: true,
                                      isGifLoad: isCurrent,
                                      isPlaying: isPlaying,
                                      onTap: context.watch<HoldTheTapFor>().isHoldingSongPLay ? null : () async {
                                        context.read<HoldTheTapFor>().startHoldingSongPlay();
                                        final bloc = context.read<MusicPlayerBloc>();
                                        final current = bloc.state.currentSong;
                                        if (current != null &&
                                            current.id == song.id &&
                                            bloc.state.isPlaying) {
                                          log('song   innnn');
                                          context.push(
                                            '/dashboard/playing',
                                            extra:
                                                PlayingSongArgs(songs: bloc.state.songs),
                                          );
                                        } else {
                                          log('song   outttt');
                                          bloc.add(SetPlaylistEvent(
                                            songs.map((m) => m.toDomain()).toList(),
                                            startIndex: index,
                                          ));
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
                                            currentSong: song,
                                            songIndex: index,
                                            songsList: songs,
                                            maxHeight: 0.85.sh,
                                            onSongDeleted: () {
                                              if (!context.mounted) return;
                                              context.read<SongsBloc>().add(const SongsEvent.getAllSongs());
                                            },
                                          ),
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
                        // Mini player is now global in Dashboard
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
