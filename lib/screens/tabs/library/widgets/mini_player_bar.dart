import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/songs/data/models/song_model.dart';
import '../../../../generated/assets.dart';
import '../../../../themes/color.dart';
import '../../../../themes/font.dart';
import '../../../play_song/playing_song_screen.dart';
import '../../../play_song/queue_navigation_helper.dart';
import '../../music_service.dart';
import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/textWidget.dart';

class MiniPlayerBar extends StatelessWidget {
  MiniPlayerBar({super.key});

  final musicService = MusicPlayerService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SongsModel>>(
      stream: musicService.songsChanged,
      initialData: musicService.songs,

      builder: (context, songsSnapshot) {
        final songs = songsSnapshot.data ?? [];

        // ✅ Hide mini player if no songs
        if (songs.isEmpty) {
          log('🙈 MiniPlayer: Hidden (no songs)');
          return const SizedBox.shrink();
        }
        return StreamBuilder<bool>(
          stream: musicService.isPlayingStream,
          initialData: musicService.isPlaying,
          builder: (context, playingSnap) {
            final isPlaying = playingSnap.data ?? false;
            final hasAny = musicService.songs.isNotEmpty;
            if (!hasAny && !isPlaying) return const SizedBox.shrink();

            log('in hereeeee again $hasAny $isPlaying');

            return GestureDetector(
              onTap: () {
                context.push(
                  '/dashboard/playing',
                  extra: PlayingSongArgs(songs: musicService.songs),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<Duration>(
                      stream: musicService.player.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final total =
                            musicService.player.duration ?? Duration.zero;

                        double progress = 0.0;
                        if (total.inMilliseconds > 0) {
                          progress =
                              position.inMilliseconds / total.inMilliseconds;
                        }
                        return LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryOrange,
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 13.w,
                        right: 13.w,
                        top: 10.h,
                        bottom: 10.h + MediaQuery.of(context).padding.bottom,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          StreamBuilder<int?>(
                            stream: musicService.currentIndexStream,
                            initialData: musicService.currentIndex,
                            builder: (context, indexSnap) {
                              return StreamBuilder<bool>(
                                stream: musicService.isPlayingStream,
                                initialData: musicService.isPlaying,
                                builder: (context, playingSnap) {
                                  final isPlaying = playingSnap.data ?? false;
                                  final index = indexSnap.data ?? 0;
                                  final songsList = musicService.songs;
                                  final safeIndex =
                                      (index >= 0 && index < songsList.length)
                                      ? index
                                      : 0;
                                  // Use currentSongId (respects reorder cache) so mini bar shows correct song during reorder
                                  final currentSongId =
                                      musicService.currentSongId;
                                  SongsModel? currentSong;
                                  if (songsList.isNotEmpty) {
                                    if (currentSongId != null) {
                                      for (final s in songsList) {
                                        if (s.id == currentSongId) {
                                          currentSong = s;
                                          break;
                                        }
                                      }
                                    }
                                    currentSong ??= songsList[safeIndex];
                                  }

                                  final hasArtwork =
                                      currentSong?.artwork_path != null &&
                                      currentSong!.artwork_path!.isNotEmpty;

                                  return Stack(
                                    children: [
                                      // Show artwork if available, otherwise show default gradient card
                                      if (hasArtwork)
                                        Container(
                                          height: 50.h,
                                          width: 50.h,
                                          margin: EdgeInsets.all(10.w),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(7.r),
                                            image: DecorationImage(
                                              image: FileImage(
                                                File(
                                                  currentSong.artwork_path!,
                                                ),
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          margin: EdgeInsets.all(10.w),
                                          child: GradientCard(
                                            height: 50.h,
                                            width: 50.w,
                                            borderRadius: 10.r,
                                            iconAsset: Assets.svgMusicIcon,
                                            iconSize: 40.r,
                                            isSvg: true,
                                            margin: 10.w,
                                            colors: [
                                              AppColors.mildOrange.withValues(
                                                alpha: 0.21,
                                              ),
                                              AppColors.mildOrange,
                                            ],
                                          ),
                                        ),
                                      // Show playing animation overlay when playing
                                      if (playingSnap.data ?? false)
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(7.r),
                                            color: AppColors.white.withValues(
                                              alpha: .4,
                                            ),
                                          ),
                                          height: 50.h,
                                          width: 50.w,
                                          margin: EdgeInsets.only(top: 10.w, bottom: 10.w, left: 9.w),
                                          child: Padding(
                                            padding:
                                            EdgeInsets.symmetric(
                                                  horizontal: 8.0.w,
                                                  vertical: 5.h,
                                                ),
                                            child: Image.asset(
                                              Assets.pngSongPlaying,
                                              fit: BoxFit.contain,
                                              height: 50.h,
                                              width: 50.w,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          SizedBox(width: 5.w),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.31,//130.w,
                            child: StreamBuilder<int?>(
                              stream: musicService.currentIndexStream,
                              initialData: musicService.currentIndex,
                              builder: (context, snapshot) {
                                final index = snapshot.data ?? 0;
                                final songsList = musicService.songs;
                                final safeIndex =
                                    (index >= 0 && index < songsList.length)
                                    ? index
                                    : 0;
                                // Use currentSongId (respects reorder cache) so mini bar shows correct song during reorder
                                final currentSongId =
                                    musicService.currentSongId;
                                SongsModel? song;
                                if (songsList.isNotEmpty) {
                                  if (currentSongId != null) {
                                    for (final s in songsList) {
                                      if (s.id == currentSongId) {
                                        song = s;
                                        break;
                                      }
                                    }
                                  }
                                  song ??= songsList[safeIndex];
                                }
                                final songName =
                                    song?.title.split('/').last ??
                                    ''; // Fallback to empty string if no song
                                final artistName =
                                    song?.artist ??
                                    ''; // Fallback to empty string if no artist

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Texts(
                                      songName,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: AppFonts.inter,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Texts(
                                      artistName,
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: AppFonts.inter,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    context.go(
                                      '/dashboard/queue',
                                    );
                                    // QueueNavigationHelper.navigateToQueueScreen(
                                    //   context,
                                    // );
                                  },
                                  child: SvgPicture.asset(
                                    Assets.svgIcQueue,
                                    width: 24.w,
                                    height: 24.h,
                                  ),
                                ),
                                // SizedBox(width: 20.w),
                                GestureDetector(
                                  onTap: () {
                                    musicService.next();
                                  },
                                  child: SvgPicture.asset(
                                    Assets.svgIcPlayingnext,
                                    width: 24.w,
                                    height: 24.h,
                                  ),
                                ),
                                // SizedBox(width: 20.w),
                                StreamBuilder<bool>(
                                  stream: musicService.isPlayingStream,
                                  initialData: musicService.isPlaying,
                                  builder: (context, snapshot) {
                                    final isPlaying = snapshot.data ?? false;
                                    if (isPlaying) {
                                      return GestureDetector(
                                        onTap: () => musicService.pause(),
                                        child: SvgPicture.asset(
                                          Assets.svgNewPause,
                                          height: 19.h,
                                          width: 19.w,
                                          colorFilter: const ColorFilter.mode(
                                            AppColors.primaryOrange,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      );
                                    } else {
                                      return GestureDetector(
                                        onTap: () => musicService.play(),
                                        child: SvgPicture.asset(
                                          Assets.svgPlay,
                                          height: 19.h,
                                          width: 19.w,
                                          colorFilter: const ColorFilter.mode(
                                            AppColors.primaryOrange,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
