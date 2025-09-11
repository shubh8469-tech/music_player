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

class AudioPlayerWidget extends StatefulWidget {
  final String url;

  const AudioPlayerWidget({super.key, required this.url});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioPlayer.setUrl(widget.url);

    _audioPlayer.durationStream.listen((d) {
      setState(() => _duration = d ?? Duration.zero);
    });

    _audioPlayer.positionStream.listen((p) {
      setState(() => _position = p);
    });

    _audioPlayer.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
    });
  }

  String _formatTime(Duration duration) {
    final ms = duration.inMilliseconds;
    final date = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return DateFormat('m:ss').format(date);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
            _audioPlayer.seek(position);
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
            SvgPicture.asset(
              Assets.svgIcSuffle,
              width: 28.w,
              height: 28.h,
            ),
            SvgPicture.asset(
              Assets.svgIcPrev,
              width: 28.w,
              height: 28.h,
            ),

            // Play/Pause Button with shadow
            GestureDetector(
              onTap: () {
                _isPlaying ? _audioPlayer.pause() : _audioPlayer.play();
              },
              child: Container(
                width: 65.w,
                height: 65.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textColor.withValues(alpha: 0.2),
                      blurRadius: 12.r,
                      spreadRadius: 1.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  _isPlaying ? Assets.svgIcPause : Assets.svgIcPlay,
                  height: 60.h,
                  width: 60.w,
                ),
              ),
            ),

            SvgPicture.asset(
              Assets.svgIcNext,
              width: 28.w,
              height: 28.h,
            ),
            SvgPicture.asset(
              Assets.svgIcRepeat,
              width: 28.w,
              height: 28.h,
            ),
          ],
        ),
      ],
    );
  }
}


/*
class AudioPlayerWidget extends StatefulWidget {
  final String url;

  const AudioPlayerWidget({super.key, required this.url});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioPlayer.setUrl(widget.url);

    _audioPlayer.durationStream.listen((d) {
      setState(() => _duration = d ?? Duration.zero);
    });

    _audioPlayer.positionStream.listen((p) {
      setState(() => _position = p);
    });

    _audioPlayer.playerStateStream.listen((state) {
      setState(() => _isPlaying = state.playing);
    });
  }

  String _formatTime(Duration duration) {
    final ms = duration.inMilliseconds;
    final date = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return DateFormat('m:ss').format(date);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          min: 0.0,
          max: _duration.inMilliseconds.toDouble(),
          value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
          activeColor: AppColors.black,
          onChanged: (value) {
            final position = Duration(milliseconds: value.round());
            _audioPlayer.seek(position);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18.0, right: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatTime(_position), style: const TextStyle(color: Colors.black)),
              Text(_formatTime(_duration), style: const TextStyle(color: Colors.black)),
            ],
          ),
        ),
        SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SvgPicture.asset(Assets.svgIcSuffle),
            SvgPicture.asset(Assets.svgIcPrev),
            GestureDetector(
              onTap: () {
                _isPlaying ? _audioPlayer.pause() : _audioPlayer.play();
              },
              child: Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textColor.withValues(alpha: 0.2), // Shadow color
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: Offset(0, 2), // Shadow position
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(_isPlaying ? Assets.svgIcPause : Assets.svgIcPlay, height: 60),
              ),
            ),
            SvgPicture.asset(Assets.svgIcNext),
            SvgPicture.asset(Assets.svgIcRepeat),
          ],
        ),
      ],
    );
  }
}
*/
