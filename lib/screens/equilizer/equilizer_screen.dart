import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/themes/color.dart';
import 'package:provider/provider.dart';

import '../../commonWidgets/app_bar_with_icon_title.dart';
import '../../commonWidgets/level_bar_Sliders.dart';
import '../../commonWidgets/textWidget.dart';
import '../../generated/assets.dart';
import '../../themes/font.dart';
import 'equalizer_provider.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EqualizerProvider>(
      create: (_) => EqualizerProvider(),
      child: const _EqualizerScreenContent(),
    );
  }
}

class _EqualizerScreenContent extends StatelessWidget {
  const _EqualizerScreenContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EqualizerProvider>();
    final eqService = provider.eqService;

    final presetList = provider.presetList;
    final half = (presetList.length / 2).ceil();
    final row1 = presetList.take(half).toList();
    final row2 = presetList.skip(half).toList();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBarWithIconTitle(
            title: "Equalizer",
            backgroundColor: AppColors.primaryOrange,
            titleColor: AppColors.white,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            showBackButton: false,
            actions: [
              Row(
                children: [
                  Switch(
                    value: eqService.isEnabled,
                    onChanged: (value) => provider.setEnabled(value),
                    activeThumbColor: Colors.white,
                    activeTrackColor: Colors.white.withValues(alpha: 0.5),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                  ),
                  SizedBox(width: 8.w),
                ],
              ),
            ],
          ),
          body: !provider.isInitialized
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primaryOrange),
                      SizedBox(height: 16.h),
                      Texts('Loading Equalizer...', fontSize: 14.sp, color: AppColors.textColor),
                    ],
                  ),
                )
              : provider.hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: AppColors.primaryOrange, size: 48.w),
                          SizedBox(height: 16.h),
                          Texts('Failed to load equalizer', fontSize: 14.sp, color: AppColors.textColor),
                          SizedBox(height: 8.h),
                          TextButton(
                            onPressed: provider.retryInit,
                            child: Texts('Retry', fontSize: 14.sp, color: AppColors.primaryOrange),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        SingleChildScrollView(
                          padding: EdgeInsets.symmetric(vertical: 15.w),
                          child: Container(
                            color: AppColors.white,
                            // height: MediaQuery.of(context).size.height,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PresetChips(
                                  row1: row1,
                                  row2: row2,
                                  selectedPreset: provider.selectedPreset,
                                  onPresetSelected: provider.applyPreset,
                                ),
                                _FrequencySliders(
                                  frequencies: provider.frequencies,
                                  frequencyLabels: provider.frequencyLabels,
                                  onBandChanged: provider.updateBandLevelUI,
                                  onBandChangeEnd: provider.commitBandLevelToBackend,
                                ),
                                SizedBox(height: 20.h),
                                _EffectsSection(
                                  selectedReverb: provider.selectedReverb,
                                  bassBoostLevel: provider.bassBoostLevel,
                                  virtualizerLevel: provider.virtualizerLevel,
                                  onBassBoostChanged: provider.updateBassBoostUI,
                                  onBassBoostChangeEnd: provider.commitBassBoostToBackend,
                                  onVirtualizerChanged: provider.updateVirtualizerUI,
                                  onVirtualizerChangeEnd: provider.commitVirtualizerToBackend,
                                  onReverbTap: () => _showReverbBottomSheet(context),
                                ),
                                if (!eqService.isAndroid && !eqService.isIOS) ...[
                                  SizedBox(height: 20.h),
                                  _PlatformInfo(),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (!eqService.isEnabled)
                          Positioned.fill(
                            child: ClipRRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                                child: Container(
                                  height: MediaQuery.of(context).size.height,
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }

  void _showReverbBottomSheet(BuildContext context) {
    final provider = context.read<EqualizerProvider>();
    final currentIndex = provider.reverbOptions.indexOf(provider.eqService.reverbType);
    provider.setLocalReverbIndex(currentIndex >= 0 ? currentIndex : 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      isScrollControlled: true,
      builder: (context) {
        // Use the provider we already captured above instead of a new Consumer,
        // so we don't depend on the bottom sheet's BuildContext having the provider.
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(Assets.svgIcLineBottom),
              SizedBox(height: 20.h),
              Texts('Select Reverb', fontSize: 18.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter),
              SizedBox(height: 16.h),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: List.generate(provider.reverbOptions.length, (index) {
                    final item = provider.reverbOptions[index];
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      title: Texts(
                        item,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFonts.inter,
                        color: index == provider.localSelectedIndex ? AppColors.primaryOrange : AppColors.textColor,
                      ),
                      trailing: SvgPicture.asset(
                        index == provider.localSelectedIndex ? Assets.svgIcRadioCheckl : Assets.svgIcRadioUncheck,
                        height: 20.h,
                        width: 20.w,
                      ),
                      onTap: () async {
                        provider.setLocalReverbIndex(index);
                        await provider.setReverb(item);
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PresetChips extends StatelessWidget {
  const _PresetChips({
    required this.row1,
    required this.row2,
    required this.selectedPreset,
    required this.onPresetSelected,
  });

  final List<String> row1;
  final List<String> row2;
  final int selectedPreset;
  final void Function(int) onPresetSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: EdgeInsets.only(left: 15.w),
        margin: EdgeInsets.only(right: 15.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10.w,
                  runSpacing: 5.h,
                  children: List.generate(row1.length, (i) {
                    return ChoiceChip(
                      showCheckmark: false,
                      backgroundColor: AppColors.chipUnselected,
                      side: BorderSide.none,
                      label: Text(row1[i]),
                      selected: selectedPreset == i,
                      selectedColor: AppColors.primaryOrange,
                      labelStyle: TextStyle(
                        color: selectedPreset == i ? Colors.white : Colors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.inter,
                      ),
                      shape: const StadiumBorder(),
                      onSelected: (_) => onPresetSelected(i),
                    );
                  }),
                ),
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 10.w,
                  runSpacing: 5.h,
                  children: List.generate(row2.length, (i) {
                    final index = i + row1.length;
                    return ChoiceChip(
                      side: BorderSide.none,
                      backgroundColor: AppColors.chipUnselected,
                      showCheckmark: false,
                      label: Text(row2[i]),
                      selected: selectedPreset == index,
                      selectedColor: AppColors.primaryOrange,
                      labelStyle: TextStyle(
                        color: selectedPreset == index ? Colors.white : Colors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.inter,
                      ),
                      shape: const StadiumBorder(),
                      onSelected: (_) => onPresetSelected(index),
                    );
                  }),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencySliders extends StatelessWidget {
  const _FrequencySliders({
    required this.frequencies,
    required this.frequencyLabels,
    required this.onBandChanged,
    required this.onBandChangeEnd,
  });

  final List<double> frequencies;
  final List<String> frequencyLabels;
  final void Function(int, double) onBandChanged;
  final void Function(int) onBandChangeEnd;

  static const double _sliderMin = -1.5;
  static const double _sliderMax = 1.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(frequencies.length, (i) {
              final clampedValue = frequencies[i].clamp(_sliderMin, _sliderMax);
              return Column(
                children: [
                  Texts(
                    "${clampedValue > 0 ? "+" : ""}${clampedValue.toStringAsFixed(1)}",
                    color: clampedValue > 0 ? AppColors.primaryOrange : AppColors.textColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.inter,
                  ),
                  SizedBox(
                    height: 280.h,
                    child: RotatedBox(
                      quarterTurns: -1,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.h,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
                        ),
                        child: Slider(
                          value: clampedValue,
                          min: _sliderMin,
                          max: _sliderMax,
                          activeColor: AppColors.primaryOrange,
                          inactiveColor: AppColors.black.withValues(alpha: 0.2),
                          onChanged: (value) => onBandChanged(i, value),
                          onChangeEnd: (_) => onBandChangeEnd(i),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Texts(
                    frequencyLabels[i],
                    fontSize: 12.sp,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.inter,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EffectsSection extends StatelessWidget {
  const _EffectsSection({
    required this.selectedReverb,
    required this.bassBoostLevel,
    required this.virtualizerLevel,
    required this.onBassBoostChanged,
    required this.onBassBoostChangeEnd,
    required this.onVirtualizerChanged,
    required this.onVirtualizerChangeEnd,
    required this.onReverbTap,
  });

  final String selectedReverb;
  final int bassBoostLevel;
  final int virtualizerLevel;
  final void Function(int) onBassBoostChanged;
  final void Function(int) onVirtualizerChanged;
   final void Function(int) onBassBoostChangeEnd;
   final void Function(int) onVirtualizerChangeEnd;
  final VoidCallback onReverbTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      margin: EdgeInsets.symmetric(horizontal: 15.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Texts("Reverb", fontSize: 16.sp, fontWeight: FontWeight.w600),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Texts(selectedReverb, fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textColor),
                SizedBox(width: 6.w),
                SvgPicture.asset(
                  Assets.svgIcDownArrow,
                  width: 20.w,
                  height: 20.h,
                  colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn),
                ),
              ],
            ),
            onTap: onReverbTap,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Texts("Bass Boost", fontSize: 14.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: LevelBarSlider(
                  level: bassBoostLevel,
                  displayMaxLevel: 20,
                  onChanged: onBassBoostChanged,
                  onChangeEnd: onBassBoostChangeEnd,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Texts("Virtualizer", fontSize: 14.sp),
              SizedBox(width: 15.w),
              Expanded(
                child: LevelBarSlider(
                  level: virtualizerLevel,
                  displayMaxLevel: 20,
                  onChanged: onVirtualizerChanged,
                  onChangeEnd: onVirtualizerChangeEnd,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class _PlatformInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.primaryOrange, size: 20.w),
          SizedBox(width: 10.w),
          Expanded(
            child: Texts(
              'Equalizer is available on Android and iOS devices',
              fontSize: 12.sp,
              color: AppColors.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
