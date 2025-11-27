import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/themes/color.dart';

import '../../commonWidgets/level_bar_Sliders.dart';
import '../../commonWidgets/textWidget.dart';
import '../../generated/assets.dart';
import '../../themes/font.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  final presetList = [
    "Custom",
    "Normal",
    "Rock",
    "Dance",
    "Pop",
    "Hip Hop",
    "Acoustic",
    "Heavy Metal",
    "Folk",
    "Head Phones",
    "Loud",
    "Piano",
    "Bass Boost",
    "Electronic",
    "Flat",
    "Classical",
    "Straightness",
    "Jazz",
    "Treble Boost",
    "Vocal Boost",
    "Latin",
    "Deep",
    "Lounge",
    "R&B",
  ];

  int selectedPreset = 0;

  List<double> frequencies = [0.8, 0.0, 0.8, 0.8, 0.8];
  final frequencyLabels = ["60Hz", "230Hz", "910Hz", "4kHz", "14kHz"];

  String selectedReverb = "None";
  final reverbOptions = ["None", "Small Room", "Medium Room", "Large Room", "Medium Hall", "Large Hall", "Plate"];

  int bassBoostLevel = 0;
  int virtualizerLevel = 5;

  @override
  Widget build(BuildContext context) {
    int half = (presetList.length / 2).ceil();
    final row1 = presetList.take(half).toList();
    final row2 = presetList.skip(half).toList();

    return SafeArea(
      bottom: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.orange,
          elevation: 0,
          title: Texts("Equalizer", fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {},
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 15.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
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
                              final index = i;
                              return ChoiceChip(
                                showCheckmark: false,
                                backgroundColor: AppColors.chipUnselected,
                                side: BorderSide.none,
                                label: Text(row1[i]),
                                selected: selectedPreset == index,
                                selectedColor: Colors.orange,
                                labelStyle: TextStyle(
                                  color: selectedPreset == index ? Colors.white : Colors.black,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFonts.inter,
                                ),
                                shape: StadiumBorder(),
                                onSelected: (_) {
                                  setState(() => selectedPreset = index);
                                },
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
                                selectedColor: Colors.orange,
                                labelStyle: TextStyle(
                                  color: selectedPreset == index ? Colors.white : Colors.black,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFonts.inter,
                                ),
                                shape: StadiumBorder(),
                                onSelected: (_) {
                                  setState(() => selectedPreset = index);
                                },
                              );
                            }),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(frequencies.length, (i) {
                        return Column(
                          children: [
                            Texts(
                              "${frequencies[i] > 0 ? "+" : ""}${frequencies[i].toStringAsFixed(1)}",
                              color: Colors.orange,
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
                                    trackHeight: 4.h, // thicker track
                                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
                                    overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
                                  ),
                                  child: Slider(
                                    value: frequencies[i],
                                    min: -1.5,
                                    max: 1.5,
                                    activeColor: Colors.orange,
                                    inactiveColor: AppColors.black.withValues(alpha: 0.2),
                                    onChanged: (value) {
                                      setState(() => frequencies[i] = value);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Texts(frequencyLabels[i], fontSize: 12.sp, color: AppColors.textColor, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                margin: EdgeInsets.symmetric(horizontal: 15.w),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reverb
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Texts("Reverb", fontSize: 16.sp, fontWeight: FontWeight.w600),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Texts(selectedReverb, fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textColor),
                          SizedBox(width: 6.w),
                          SvgPicture.asset(Assets.svgIcDownArrow, width: 20.w, height: 20.h, colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn)),
                        ],
                      ),
                      onTap: () => _showReverbBottomSheet(),
                    ),

                    SizedBox(height: 16.h),

                    // Bass Boost
                    Row(
                      children: [
                        Texts("Bass Boost", fontSize: 14.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: LevelBarSlider(level: bassBoostLevel, displayMaxLevel: 21, onChanged: (value) => setState(() => bassBoostLevel = value)),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // Virtualizer
                    Row(
                      children: [
                        Texts("Virtualizer", fontSize: 14.sp),
                        SizedBox(width: 15.w),
                        Expanded(
                          child: LevelBarSlider(level: virtualizerLevel, displayMaxLevel: 21, onChanged: (value) => setState(() => virtualizerLevel = value)),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),

              // Reverb section
            ],
          ),
        ),
      ),
    );
  }

  int localSelectedIndex = 0;

  void _showReverbBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      isScrollControlled: true,
      builder: (context) {
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
                  children: [
                    ...List.generate(reverbOptions.length, (index) {
                      var item = reverbOptions[index];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                        title: Texts(
                          item,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFonts.inter,
                          color: index == localSelectedIndex ? AppColors.primaryOrange : AppColors.textColor,
                        ),
                        trailing: SvgPicture.asset(index == localSelectedIndex ? Assets.svgIcRadioCheckl : Assets.svgIcRadioUncheck, height: 20.h, width: 20.w),
                        onTap: () {
                          setState(() {
                            localSelectedIndex = index;
                            selectedReverb = reverbOptions[index];
                          });
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
