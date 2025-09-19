import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/themes/color.dart';

import '../../../generated/assets.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/themes/color.dart';

import '../../../generated/assets.dart';
import '../../../utills/snack_bar.dart';
import '../../tabs/music_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final MusicPlayerService _musicService = MusicPlayerService();
  late final StreamSubscription<PlayerState> _playerStateSub;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // Duration updates
    _musicService.player.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _duration = d);
    });

    // Position updates
    _musicService.player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    // Playing state updates
    _playerStateSub = _musicService.player.playerStateStream.listen((state) {
      if (mounted) setState(() => _isPlaying = state.playing);
    });
  }

  String _formatTime(Duration duration) {
    final ms = duration.inMilliseconds;
    final date = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return DateFormat('m:ss').format(date);
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Slider
        Slider(
          min: 0.0,
          max: _duration.inMilliseconds.toDouble(),
          value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
          activeColor: AppColors.black,
          onChanged: (value) {
            final position = Duration(milliseconds: value.round());
            _musicService.player.seek(position);
          },
        ),

        // Time Labels
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(_position),
                style: TextStyle(color: Colors.black, fontSize: 14.sp),
              ),
              Text(
                _formatTime(_duration),
                style: TextStyle(color: Colors.black, fontSize: 14.sp),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Controls
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () async {
                await _musicService.toggleShuffle();
                showSnackBar(context, () {}, message: "Shuffle ${_musicService.isShuffleEnabled ? "On" : "Off"}", alertBannerLocation: AlertBannerLocation.bottom);
              },
              child: SvgPicture.asset(_musicService.isShuffleEnabled ? Assets.svgIcSuffle : Assets.svgShuffleOff, width: 28.w, height: 28.h),
            ),
            GestureDetector(
              onTap: () {
                _musicService.previous();
              },
              child: SvgPicture.asset(Assets.svgIcPrev, width: 28.w, height: 28.h),
            ),

            // Play/Pause Button with shadow
            GestureDetector(
              onTap: () {
                _isPlaying ? _musicService.player.pause() : _musicService.player.play();
              },
              child: Container(
                width: 65.w,
                height: 65.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.textColor.withValues(alpha: 0.2), blurRadius: 12.r, spreadRadius: 1.r, offset: Offset(0, 2.h))],
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(_isPlaying ? Assets.svgIcPause : Assets.svgIcPlay, height: 60.h, width: 60.w),
              ),
            ),

            GestureDetector(
              onTap: () {
                _musicService.next();
              },
              child: SvgPicture.asset(Assets.svgIcNext, width: 28.w, height: 28.h),
            ),
            GestureDetector(
              onTap: () {
                _musicService.toggleRepeat();
                showSnackBar(
                  context,
                  () {},
                  message: _musicService.loopMode == LoopMode.off
                      ? "Repeat off"
                      : _musicService.loopMode == LoopMode.all
                      ? "Loop all"
                      : "Repeat current",
                  alertBannerLocation: AlertBannerLocation.bottom,
                );
              },
              child: SvgPicture.asset(
                _musicService.loopMode == LoopMode.off
                    ? Assets.svgRepeatOff
                    : _musicService.loopMode == LoopMode.all
                    ? Assets.svgRepeatOn
                    : Assets.svgRepeatOnce,
                width: 28.w,
                height: 28.h,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
