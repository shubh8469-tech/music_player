import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_event.dart';

class PlaybackSpeedBottomSheet extends StatefulWidget {
  const PlaybackSpeedBottomSheet({super.key});

  @override
  State<PlaybackSpeedBottomSheet> createState() => _PlaybackSpeedBottomSheetState();
}

class _PlaybackSpeedBottomSheetState extends State<PlaybackSpeedBottomSheet> {
  static const double _minSpeed = 0.5;
  static const double _maxSpeed = 2.0;
  static const double _stepSize = 0.1;
  static const List<double> _presetSpeeds = [0.5, 1.0, 1.5, 2.0];
  static const List<double> _labelStops = [0.5, 1.0, 1.5, 2.0];
  static const List<double> _dotStops = [1.0, 1.5];

  late double _selectedSpeed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<MusicPlayerBloc>();
        setState(() => _selectedSpeed = _normalizeSpeed(bloc.playbackSpeed));
      }
    });
    _selectedSpeed = 1.0;
  }

  String get _formattedSpeed {
    final value = double.parse(_selectedSpeed.toStringAsFixed(2));
    return value.toStringAsFixed(1);
  }

  Future<void> _apply() async {
    context.read<MusicPlayerBloc>().add(SetPlaybackSpeedEvent(_selectedSpeed));
    if (mounted) Navigator.pop(context);
  }

  void _tapPreset(double speed) {
    setState(() {
      _selectedSpeed = _normalizeSpeed(speed);
    });
  }

  double _normalizeSpeed(double value) {
    final clamped = value.clamp(_minSpeed, _maxSpeed);
    return double.parse(clamped.toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32.r), topRight: Radius.circular(32.r)),
        ),
        padding: EdgeInsets.symmetric(vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(
                width: 44.w,
                height: 5.h,
                decoration: BoxDecoration(color: AppColors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r)),
              ),
            ),
            SizedBox(height: 30.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Playback Speed : ',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                      fontFamily: AppFonts.interMedium,
                      // fontStyle: AppFonts.interMedium
                    ),
                  ),
                  TextSpan(
                    text: '${_formattedSpeed}x',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: AppColors.primaryOrange, fontFamily: AppFonts.interMedium),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),
            _SliderWithFixedLabels(
              min: _minSpeed,
              max: _maxSpeed,
              stepSize: _stepSize,
              value: _selectedSpeed,
              labelStops: _labelStops,
              dotStops: _dotStops,
              onChanged: (value) {
                setState(() {
                  _selectedSpeed = _normalizeSpeed(value);
                });
              },
            ),
            SizedBox(height: 22.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.h),
              child: Column(
                children: [
                  Row(
                    children: _presetSpeeds
                        .map(
                          (speed) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: GestureDetector(
                                onTap: () => _tapPreset(speed),
                                child: Container(
                                  height: 42.h,
                                  decoration: BoxDecoration(
                                    color: (speed - _selectedSpeed).abs() < 0.05 ? AppColors.primaryOrange : AppColors.textColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  alignment: Alignment.center,
                                  child: Texts(
                                    '${speed.toStringAsFixed(1)}x',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: (speed - _selectedSpeed).abs() < 0.05 ? AppColors.white : AppColors.textColor,
                                    fontFamily: AppFonts.inter,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: 28.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 52.h,
                            decoration: BoxDecoration(color: AppColors.black.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(30.r)),
                            alignment: Alignment.center,
                            child: Texts(localization.cancel, fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.medium, color: AppColors.textColor),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: _apply,
                          child: Container(
                            height: 52.h,
                            decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(30.r)),
                            alignment: Alignment.center,
                            child: Texts('Done', fontSize: 16.sp, fontWeight: FontWeight.w600, fontFamily: AppFonts.medium, color: AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderWithFixedLabels extends StatelessWidget {
  const _SliderWithFixedLabels({
    required this.min,
    required this.max,
    required this.stepSize,
    required this.value,
    required this.labelStops,
    required this.dotStops,
    required this.onChanged,
  });

  final double min;
  final double max;
  final double stepSize;
  final double value;
  final List<double> labelStops;
  final List<double> dotStops;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final totalDivisions = ((max - min) / 0.5).round();

    return Column(
      children: [
        SizedBox(
          height: 56.h,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalInset = 36.w;
              final trackWidth = constraints.maxWidth - (horizontalInset * 2);
              final barWidth = 3.w;
              final barHeight = 18.h;
              final dotDiameter = 6.w;

              double positionForValue(double input) {
                final fraction = (input - min) / (max - min);
                return horizontalInset + (fraction * trackWidth);
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: horizontalInset,
                    right: horizontalInset,
                    top: (56.h - 4.h) / 2,
                    child: Container(
                      height: 4.h,
                      decoration: BoxDecoration(color: AppColors.textColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(40.r)),
                    ),
                  ),
                  Positioned(
                    left: horizontalInset - (barWidth / 2),
                    top: (56.h - barHeight) / 2,
                    child: Container(
                      width: barWidth,
                      height: barHeight,
                      decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(3.r)),
                    ),
                  ),
                  Positioned(
                    right: horizontalInset - (barWidth / 2),
                    top: (56.h - barHeight) / 2,
                    child: Container(
                      width: barWidth,
                      height: barHeight,
                      decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(3.r)),
                    ),
                  ),
                  for (final stop in dotStops)
                    Positioned(
                      left: positionForValue(stop) - (dotDiameter / 2),
                      top: (56.h - dotDiameter) / 2,
                      child: Container(
                        width: dotDiameter,
                        height: dotDiameter,
                        decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28.w),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.h,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: AppColors.primaryOrange,
                          overlayShape: SliderComponentShape.noOverlay,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
                        ),
                        child: Slider(value: value, min: min, max: max, divisions: totalDivisions, onChanged: onChanged),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labelStops
                .map(
                  (speed) => Texts(
                    '${speed.toStringAsFixed(1)}x',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColor.withValues(alpha: 0.7),
                    fontFamily: AppFonts.inter,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
