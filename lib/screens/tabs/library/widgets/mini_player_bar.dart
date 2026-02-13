import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/music_player/bloc/music_player_bloc.dart';
import '../../../../features/music_player/bloc/music_player_state.dart';
import '../../../../features/songs/data/models/song_model.dart';
import '../../../../generated/assets.dart';
import '../../../../themes/color.dart';
import '../../../../themes/font.dart';
import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../play_song/playing_song_screen.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicPlayerBloc, MusicPlayerState>(
      buildWhen: (prev, curr) =>
          prev.songs != curr.songs ||
          prev.isPlaying != curr.isPlaying ||
          prev.currentSongId != curr.currentSongId ||
          prev.currentIndex != curr.currentIndex ||
          prev.position != curr.position ||
          prev.duration != curr.duration,
      builder: (context, state) {
        if (state.songs.isEmpty) {
          return const SizedBox.shrink();
        }

        final musicService = context.read<MusicPlayerBloc>().musicService;
        final currentSong = state.currentSong;

        return GestureDetector(
          onTap: () {
            context.push('/dashboard/playing', extra: PlayingSongArgs(songs: musicService.songs));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: state.progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 13.w, right: 13.w, top: 10.h, bottom: 10.h + MediaQuery.of(context).padding.bottom),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _ArtworkSection(song: currentSong, isPlaying: state.isPlaying),
                      SizedBox(width: 5.w),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.31,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Texts(
                              currentSong?.title.split('/').last ?? '',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppFonts.inter,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Texts(currentSong?.artist ?? '', fontSize: 8.sp, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            GestureDetector(
                              onTap: () => context.go('/dashboard/queue'),
                              child: SvgPicture.asset(Assets.svgIcQueue, width: 24.w, height: 24.h),
                            ),
                            GestureDetector(
                              onTap: () => musicService.next(),
                              child: SvgPicture.asset(Assets.svgIcPlayingnext, width: 24.w, height: 24.h),
                            ),
                            _PlayPauseButton(state: state),
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
  }
}

class _ArtworkSection extends StatelessWidget {
  const _ArtworkSection({this.song, this.isPlaying = false});

  final SongsModel? song;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final hasArtwork = song?.artwork_path != null && song!.artwork_path!.isNotEmpty;

    return Stack(
      children: [
        if (hasArtwork)
          Container(
            margin: EdgeInsets.all(10.w),
            child: GradientCard(
              height: 50.h,
              width: 50.w,
              borderRadius: 7.r,
              iconAsset: song!.artwork_path!,
              iconSize: 40.r,
              isSvg: true,
              margin: 0.w,
              colors: [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.mildOrange],
            ),
          )
        else
          Container(
            margin: EdgeInsets.all(10.w),
            child: GradientCard(
              height: 50.h,
              width: 50.w,
              borderRadius: 7.r,
              iconAsset: Assets.svgMusicIcon,
              iconSize: 40.r,
              isSvg: true,
              margin: 0.w,
              colors: [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.mildOrange],
            ),
          ),
        if (isPlaying)
        Container(
          margin: EdgeInsets.all(10.w),
          child: GradientCard(
            height: 50.h,
            width: 50.w,
            borderRadius: 10.r,
            iconAsset: Assets.pngSongPlaying,
            iconSize: 40.r,
            isSvg: true,
            margin: 0.w,
            colors: [AppColors.white.withValues(alpha: 0.21), AppColors.white.withValues(alpha: 0.21)],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7.r),
            color: AppColors.white.withValues(alpha: .4),
          ),
          height: 50.h,
          width: 50.w,
          margin: EdgeInsets.only(top: 10.w, bottom: 10.w, left: 9.w),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0.w, vertical: 5.h),
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
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.state});

  final MusicPlayerState state;

  @override
  Widget build(BuildContext context) {
    final musicService = context.read<MusicPlayerBloc>().musicService;

    if (state.isPlaying) {
      return GestureDetector(
        onTap: () => musicService.pause(),
        child: SvgPicture.asset(Assets.svgNewPause, height: 19.h, width: 19.w, colorFilter: const ColorFilter.mode(AppColors.primaryOrange, BlendMode.srcIn)),
      );
    }
    return GestureDetector(
      onTap: () => musicService.play(),
      child: SvgPicture.asset(Assets.svgPlay, height: 19.h, width: 19.w, colorFilter: const ColorFilter.mode(AppColors.primaryOrange, BlendMode.srcIn)),
    );
  }
}
