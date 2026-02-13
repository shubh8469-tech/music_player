import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../commonWidgets/app_bar_with_icon_title.dart';
import '../../commonWidgets/textWidget.dart';
import '../../core/di/injection.dart';
import '../../features/settings/data/dataSource/scan_preferences_local_data_source.dart';
import '../../generated/assets.dart';
import '../../themes/color.dart';
import '../../themes/font.dart';

enum DurationFilter { thirtySeconds, sixtySeconds }

enum SizeFilter { fiftyKB, hundredKB }

class ScanMusicScreen extends StatefulWidget {
  const ScanMusicScreen({super.key});

  @override
  State<ScanMusicScreen> createState() => _ScanMusicScreenState();
}

class _ScanMusicScreenState extends State<ScanMusicScreen> {
  DurationFilter _durationFilter = DurationFilter.thirtySeconds;
  SizeFilter _sizeFilter = SizeFilter.fiftyKB;
  Set<String> _selectedFolders = {};
  late final ScanPreferencesLocalDataSource _scanPreferencesLocalDataSource;
  bool _isLoadingPrefs = true;

  int _getDurationInMs() {
    return _durationFilter == DurationFilter.thirtySeconds ? 30000 : 60000;
  }

  int _getSizeInBytes() {
    return _sizeFilter == SizeFilter.fiftyKB ? 50000 : 100000;
  }

  @override
  void initState() {
    super.initState();
    _scanPreferencesLocalDataSource = locator<ScanPreferencesLocalDataSource>();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _scanPreferencesLocalDataSource.getPreferences();
    if (!mounted) return;
    setState(() {
      _durationFilter = prefs.minDurationMs <= 30000
          ? DurationFilter.thirtySeconds
          : DurationFilter.sixtySeconds;
      _sizeFilter = prefs.minSizeBytes <= 50000
          ? SizeFilter.fiftyKB
          : SizeFilter.hundredKB;
      _isLoadingPrefs = false;
    });
  }

  void _navigateToSelectFolders() async {
    final result = await context.push<Set<String>>(
      '/dashboard/scan-select-folders',
      extra: _selectedFolders,
    );
    if (result != null) {
      setState(() {
        _selectedFolders = result;
      });
    }
  }

  Future<void> _startScan() async {
    final minDuration = _getDurationInMs();
    final minSize = _getSizeInBytes();

    await _scanPreferencesLocalDataSource.savePreferences(
      minDurationMs: minDuration,
      minSizeBytes: minSize,
    );

    if (!mounted) return;

    context.push(
      '/dashboard/scanning-progress',
      extra: {
        'durationFilter': minDuration,
        'sizeFilter': minSize,
        'selectedFolders': _selectedFolders,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: "Scan Music",
        backgroundColor: AppColors.primaryOrange,
        titleColor: AppColors.white,
        centerTitle: false,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  Assets.svgScanning,
                  width: 106.w,
                  height: 106.h,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Texts(
                    "Scan Files",
                    fontSize: 16.sp,
                    fontWeight: AppFontWeights.medium,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  InkWell(
                    onTap: _navigateToSelectFolders,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Texts(
                          "Select Folders",
                          fontSize: 16.sp,
                          fontWeight: AppFontWeights.medium,
                          fontFamily: AppFonts.inter,
                          color: AppColors.primaryOrange,
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16.sp,
                          color: AppColors.primaryOrange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Texts(
                  _selectedFolders.isEmpty
                      ? "All folders selected"
                      : "${_selectedFolders.length} folders selected",
                  fontSize: 12.sp,
                  fontWeight: AppFontWeights.regular,
                  fontFamily: AppFonts.inter,
                  color: AppColors.textColor.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 32.h),
              // Ignore duration section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Texts(
                    "Ignore duration less than",
                    fontSize: 16.sp,
                    fontWeight: AppFontWeights.medium,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  SizedBox(height: 12.h),
                  Column(
                    children: [
                      _buildRadioOption(
                        value: DurationFilter.thirtySeconds,
                        groupValue: _durationFilter,
                        label: "30s",
                        onChanged: (value) {
                          setState(() {
                            _durationFilter = value!;
                          });
                        },
                      ),
                      SizedBox(height: 20.h),
                      _buildRadioOption(
                        value: DurationFilter.sixtySeconds,
                        groupValue: _durationFilter,
                        label: "60s",
                        onChanged: (value) {
                          setState(() {
                            _durationFilter = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              // Ignore size section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Texts(
                    "Ignore size less than",
                    fontSize: 16.sp,
                    fontWeight: AppFontWeights.medium,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  SizedBox(height: 12.h),
                  Column(
                    children: [
                      _buildRadioOption(
                        value: SizeFilter.fiftyKB,
                        groupValue: _sizeFilter,
                        label: "50k",
                        onChanged: (value) {
                          setState(() {
                            _sizeFilter = value!;
                          });
                        },
                      ),
                      SizedBox(height: 20.h),
                      _buildRadioOption(
                        value: SizeFilter.hundredKB,
                        groupValue: _sizeFilter,
                        label: "100k",
                        onChanged: (value) {
                          setState(() {
                            _sizeFilter = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: ElevatedButton(
            onPressed: _startScan,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.r),
              ),
            ),
            child: Texts(
              "Scan",
              fontSize: 16.sp,
              fontWeight: AppFontWeights.medium,
              fontFamily: AppFonts.inter,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption<T>({
    required T value,
    required T? groupValue,
    required String label,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Container(
            width: 20.w,
            height: 20.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primaryOrange : AppColors.black,
                width: 1.5.w,
              ),
              color: Colors.transparent,
            ),
            child: isSelected
                ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(2.r),
                    child: Container(
                      height: 14.sp,
                      width: 14.sp,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100.r),
                        color: AppColors.primaryOrange,
                      ),
                      ),
                  ),
                )
                : null,
          ),
          SizedBox(width: 8.w),
          Texts(
            label,
            fontSize: 16.sp,
            fontWeight: AppFontWeights.regular,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
        ],
      ),
    );
  }
}

