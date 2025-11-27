import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../commonWidgets/textWidget.dart';
import '../../core/di/injection.dart';
import '../../features/settings/data/dataSource/backup_options_local_data_source.dart';
import '../../generated/assets.dart';
import '../../l10n/l10n.dart';
import '../../themes/color.dart';
import '../../themes/font.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  late final BackupOptionsLocalDataSource _backupOptionsLocalDataSource;
  List<BackupOption> _backupOptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _backupOptionsLocalDataSource = locator<BackupOptionsLocalDataSource>();
    _loadBackupOptions();
  }

  Future<void> _loadBackupOptions() async {
    try {
      final options = await _backupOptionsLocalDataSource.getAllOptions();
      if (!mounted) return;
      setState(() {
        _backupOptions = options;
        _isLoading = false;
      });
    } catch (error, stack) {
      log('Failed to load backup options', error: error, stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _backupOptions = [];
        _isLoading = false;
      });
    }
  }

  void _persistBackupSelection(String key, bool isSelected) {
    final index = _backupOptions.indexWhere((option) => option.key == key);
    if (index == -1 || !mounted) return;
    setState(() {
      _backupOptions[index] =
          _backupOptions[index].copyWith(isSelected: isSelected);
    });
    _backupOptionsLocalDataSource.updateSelection(key, isSelected);
  }

  String get _selectedItemsSummary {
    if (_isLoading) {
      return 'Loading backup items...';
    }
    if (_backupOptions.isEmpty) {
      return 'No backup items configured yet';
    }
    final selected =
        _backupOptions.where((option) => option.isSelected).toList();
    if (selected.isEmpty) {
      return 'No items selected';
    }
    return selected.map((option) => option.label).join(', ');
  }

  void _showSelectionSheet() {
    showModalBottomSheet(
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (_isLoading) {
              return SizedBox(
                height: 200.h,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 30.h),
                  Center(
                    child: Texts(
                      "Select backup items",
                      fontSize: 16.sp,
                      fontWeight: AppFontWeights.medium,
                      fontFamily: AppFonts.inter,
                      color: AppColors.textColor,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  ..._backupOptions.map(
                    (option) => _checkTag(
                      label: option.label,
                      value: option.isSelected,
                      onChanged: (bool? value) {
                        if (value == null) return;
                        _persistBackupSelection(option.key, value);
                        setModalState(() {});
                      },
                    ),
                  ),
                  SizedBox(height: 25.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            child: Center(
                              child: Texts(
                                S.of(context).cancel,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFonts.inter,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 25.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, {
                            for (final option in _backupOptions)
                              option.key: option.isSelected,
                          }),
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(50.r),
                            ),
                            child: Center(
                              child: Texts(
                                S.of(context).done,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                fontFamily: AppFonts.inter,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showComingSoonSnack() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Coming soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Texts(
          "Backup & Restore",
          fontSize: 18.sp,
          fontWeight: AppFontWeights.medium,
          fontFamily: AppFonts.inter,
          color: AppColors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              _ActionTile(
                iconAsset: Assets.svgLocalBackup,
                title: "Select backup items",
                subtitle: _selectedItemsSummary,
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.primaryOrange,
                ),
                onTap: _showSelectionSheet,
              ),
              SizedBox(height: 12.h),
              _ActionTile(
                iconAsset: Assets.svgRestore,
                title: "Backup",
                subtitle: "Last backup: 2025-08-25 13:52:14",
                trailing: Center(
                  child: SvgPicture.asset(
                    Assets.svgClockRestore,
                    colorFilter: ColorFilter.mode(AppColors.primaryOrange, BlendMode.srcIn),
                  ),
                ),
                onTap: _showComingSoonSnack,
              ),
              SizedBox(height: 12.h),
              _ActionTile(
                iconAsset: Assets.svgCloudBackup,
                title: "Restore",
                subtitle: "Tap to start restoring",
                trailing: Center(
                  child: SvgPicture.asset(
                    Assets.svgClockRestore,
                    colorFilter: ColorFilter.mode(AppColors.primaryOrange, BlendMode.srcIn),
                  ),
                ),
                onTap: _showComingSoonSnack,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkTag({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Texts(
            label,
            fontSize: 16.sp,
            fontWeight: AppFontWeights.regular,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          const Spacer(),
          Checkbox(
            value: value,
            onChanged: onChanged,
            shape: const CircleBorder(),
            activeColor: AppColors.primaryOrange,
            checkColor: AppColors.textColor,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: AppColors.musicTileBackgroundColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Center(
              child: SvgPicture.asset(
                iconAsset,
                height: 24,
                width: 24,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Texts(
                    title,
                    fontSize: 16.sp,
                    fontWeight: AppFontWeights.medium,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  SizedBox(height: 6.h),
                  Texts(
                    subtitle,
                    fontSize: 12.sp,
                    fontWeight: AppFontWeights.regular,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 32,
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        Assets.svgClockRestore,
      ),
    );
  }
}


