import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_app/themes/color.dart';
import '../../../generated/assets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../utills/snack_bar.dart';
import '../../tabs/music_service.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final MusicPlayerService _musicService;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<bool>? _playerStateSub;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isSeeking = false; // Track if user is actively seeking

  @override
  void initState() {
    super.initState();
    _musicService = MusicPlayerService();

    // Initialize current state from the player
    _duration = _musicService.duration ?? Duration.zero;
    _position = _musicService.position;
    _isPlaying = _musicService.isPlaying;

    // Duration updates
    // _musicService.player.durationStream.listen((d) {
    //   if (mounted && d != null) setState(() => _duration = d);
    // });
    //
    // // Position updates
    // _musicService.player.positionStream.listen((p) {
    //   if (mounted) setState(() => _position = p);
    // });
    // Duration updates
    _durationSub = _musicService.durationStream.listen((d) {
      if (mounted && d != null) setState(() => _duration = d);
    });

    // Position updates
    _positionSub = _musicService.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    // Playing state updates - use isPlayingStream instead of playerStateStream
    _playerStateSub = _musicService.isPlayingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    // // Playing state updates
    // _playerStateSub = _musicService.player.playerStateStream.listen((state) {
    //   if (mounted) setState(() => _isPlaying = state.playing);
    // });
  }

  String _formatTime(Duration duration) {
    final ms = duration.inMilliseconds;
    final date = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return DateFormat('m:ss').format(date);
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure max value is never zero to avoid slider issues
    final maxValue = _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0;

    // Clamp position to valid range
    final currentValue = _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble();
    return Column(
      children: [
        // Slider
        Slider(
          min: 0.0,
          max: maxValue,
          value: currentValue,
          activeColor: AppColors.black,
          onChangeStart: (value) {
            // User started dragging - prevent position updates from stream
            setState(() {
              _isSeeking = true;
            });
          },
          onChanged: (value) {
            setState(() {
              _position = Duration(milliseconds: value.round());
            });
          },
          onChangeEnd: (value) async {
            final position = Duration(milliseconds: value.round());
            try {
              await _musicService.seek(position);

              // Add delay to ensure iOS catches up (for iOS)
              if (Platform.isIOS) {
                await Future.delayed(const Duration(milliseconds: 100));
              }

              // Update position state after seeking
              final isPlaying = await _musicService.isPlaying;
              setState(() {
                _isPlaying = isPlaying;
                _position = position;
              });
            } catch (e) {
              print('Error seeking: $e');
            }
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

        SizedBox(height: 10.h),

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
              onTap: () async {
                try {
                  if (_isPlaying) {
                    await _musicService.pause();
                    // UI updates via stream listener, no need to setState here
                  } else {
                    await _musicService.play();
                    // UI updates via stream listener, no need to setState here
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
                  boxShadow: [BoxShadow(color: AppColors.textColor.withValues(alpha: 0.2), blurRadius: 12.r, spreadRadius: 1.r, offset: Offset(0, 2.h))],
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(_isPlaying ? Assets.svgIcPause : Assets.svgIcPlay, height: 60.h, width: 60.w),
              ),
            ),

            GestureDetector(
              onTap: () async {
                try {
                  await _musicService.next();
                } catch (e) {
                  print('Error going to next track: $e');
                }
              },
              child: SvgPicture.asset(Assets.svgIcNext, width: 28.w, height: 28.h),
            ),

            GestureDetector(
              onTap: () async {
                try {
                  await _musicService.toggleRepeat();
                  setState(() {
                    // This triggers a rebuild to show the updated loop mode icon
                  });
                  if (mounted) {
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
                  }
                } catch (e) {
                  print('Error toggling repeat: $e');
                }
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
