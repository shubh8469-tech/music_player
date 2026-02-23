import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/themes/color.dart';
import 'package:provider/provider.dart';
import 'package:music_app/core/widgets/common_functions.dart';
import 'package:music_app/generated/assets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/core/utils/snack_bar.dart';
import 'audio_player_provider.dart';

class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({super.key});

  String _formatTime(Duration duration) {
    final ms = duration.inMilliseconds;
    final date = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return DateFormat('m:ss').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioPlayerProvider>();
    final song = provider.currentSong;

    final maxValue = provider.sliderMax;
    final currentValue = provider.sliderValue;

    return Column(
      children: [
        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            // This is where you edit the circle size
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.5.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
            activeTrackColor: AppColors.white,
            inactiveTrackColor: AppColors.greyBorder.withValues(alpha: 0.15),
            thumbColor: Colors.redAccent,
          ),
          child: Slider(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            min: 0.0,
            max: maxValue,
            value: currentValue,
            activeColor: AppColors.black,
            onChangeStart: (value) {
              provider.startSeeking();
            },
            onChanged: (value) async {
              provider.updateDrag(Duration(milliseconds: value.round()));
            },
            onChangeEnd: (value) async {
              final position = Duration(milliseconds: value.round());
              try {
                await provider.seekTo(position);

                // Add delay to ensure iOS catches up (for iOS)
                if (Platform.isIOS) {
                  await Future.delayed(const Duration(milliseconds: 100));
                }

                // Update position state after seeking
              } catch (e) {
                print('Error seeking: $e');
              }
            },
          ),
        ),

        SizedBox(height: 10.h,),

        // Time Labels
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                // _formatTime(provider.position),
                formatDuration(provider.position.inMilliseconds),
                style: TextStyle(color: AppColors.textColor, fontSize: 12.sp, fontWeight: AppFontWeights.regular),
              ),
              Text(
                // _formatTime(provider.duration),
                formatDuration(provider.duration.inMilliseconds),
                style: TextStyle(color: AppColors.textColor, fontSize: 12.sp, fontWeight: AppFontWeights.regular),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Controls
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () async {
                  await provider.toggleShuffle();
                  showSnackBar(
                    context,
                    () {},
                    message:
                        "Shuffle ${provider.isShuffleEnabled ? "On" : "Off"}",
                    alertBannerLocation: AlertBannerLocation.bottom,
                  );
                },
                child: SvgPicture.asset(
                  provider.isShuffleEnabled
                      ? Assets.svgIcSuffle
                      : Assets.svgShuffleOff,
                  width: 28.w,
                  height: 28.h,
                ),
              ),

              GestureDetector(
                onTap: () => provider.previous(),
                child:
                    SvgPicture.asset(Assets.svgIcPrev, width: 28.w, height: 28.h),
              ),

              // Play/Pause Button with shadow
              GestureDetector(
                onTap: () async {
                  try {
                    if (provider.isPlaying) {
                      provider.pause();
                    } else {
                      provider.play();
                    }
                  } catch (e) {
                    print('Error toggling play/pause: $e');
                  }
                },
                child: Container(
                  width: 65.w,
                  height: 65.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: AppColors.textColor.withValues(alpha: 0.2),
                    //     blurRadius: 12.r,
                    //     spreadRadius: 1.r,
                    //     offset: Offset(0, 2.h),
                    //   ),
                    // ],
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    provider.isPlaying ? Assets.svgIcPause : Assets.svgIcPlay,
                    height: 60.h,
                    width: 60.w,
                  ),
                ),
              ),

              GestureDetector(
                onTap: () {
                  try {
                    provider.next();
                  } catch (e) {
                    print('Error going to next track: $e');
                  }
                },
                child:
                    SvgPicture.asset(Assets.svgIcNext, width: 28.w, height: 28.h),
              ),

              GestureDetector(
                onTap: () async {
                  try {
                    await provider.toggleRepeat();
                    showSnackBar(
                      context,
                      () {},
                      message: provider.loopMode == LoopMode.off
                          ? "Repeat off"
                          : provider.loopMode == LoopMode.all
                              ? "Loop all"
                              : "Repeat current",
                      alertBannerLocation: AlertBannerLocation.bottom,
                    );
                  } catch (e) {
                    print('Error toggling repeat: $e');
                  }
                },
                child: SvgPicture.asset(
                  provider.loopMode == LoopMode.off
                      ? Assets.svgRepeatOff
                      : provider.loopMode == LoopMode.all
                          ? Assets.svgRepeatOn
                          : Assets.svgRepeatOnce,
                  width: 28.w,
                  height: 28.h,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
