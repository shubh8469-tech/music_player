import 'dart:developer';

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:music_app/core/widgets/app_bar_with_icon_title.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/features/folders/presentation/bloc/folder_bloc.dart';
import 'package:music_app/features/folders/domain/entities/folder.dart' as domain;
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

class ScanSelectFoldersScreen extends StatefulWidget {
  const ScanSelectFoldersScreen({super.key});

  @override
  State<ScanSelectFoldersScreen> createState() =>
      _ScanSelectFoldersScreenState();
}

class _ScanSelectFoldersScreenState extends State<ScanSelectFoldersScreen> {
  Set<String> _selectedFolders = {};
  Set<String> _selectedFoldersInital = {};
  bool _initializedFromArgs = false;

  @override
  void initState() {
    super.initState();
    // Fetch folders from database
    context.read<FolderBloc>().add(const FolderEvent.fetchAllFolders());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFromArgs) {
      final state = GoRouterState.of(context);
      final extra = state.extra;
      if (extra is Set<String>) {
        _selectedFolders = {...extra};
        log('_selectedFolders $_selectedFolders');
      }
      _initializedFromArgs = true;
    }
  }

  void _toggleFolder(String folderName, List<domain.Folder> allFolders) {
    setState(() {
      log('_selectedFolders $_selectedFolders');
      if (_selectedFolders.contains(folderName)) {
        _selectedFolders.remove(folderName);
      } else {
        log('_selectedFolders $_selectedFolders');
        _selectedFolders.add(folderName);
      }
      log('_selectedFolders $_selectedFolders');
    });
  }

  bool _isAllSelected(List<domain.Folder> folders) {
    log('_selectedFolders check $_selectedFolders');
    if (folders.isEmpty) return false;
    return _selectedFolders.length == folders.length &&
        folders.every((f) => _selectedFolders.contains(f.name));
  }

  void _toggleSelectAll(List<domain.Folder> allFolders) {
    setState(() {
      log('_selectedFolders ${_selectedFolders.length} ${allFolders.length}');
      if (_selectedFolders.length == allFolders.length) {
        _selectedFolders.clear();
      } else {
        _selectedFolders = allFolders.map((f) => f.name).toSet();
      }
    });
  }

  void _confirmSelection() {
    context.pop(_selectedFolders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: "Select Folders",
        backgroundColor: AppColors.primaryOrange,
        titleColor: AppColors.white,
        centerTitle: false,
        onBack: () => context.pop(),
      ),
      body: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(
              child: Texts(
                'Error: $message',
                fontSize: 16.sp,
                color: Colors.red,
              ),
            ),
            loaded: (folders, _) {
              // Initialize selection to all folders on first load
              if (_selectedFoldersInital.isEmpty && folders.isNotEmpty) {
                log('_selectedFolders check again $_selectedFolders');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _selectedFolders = folders.map((f) => f.name).toSet();
                    _selectedFoldersInital = folders.map((f) => f.name).toSet();
                  });
                });
                log('_selectedFolders check again 2 $_selectedFolders');
              }

              if (folders.isEmpty) {
                return Center(
                  child: Texts(
                    'No folders found',
                    fontSize: 16.sp,
                    color: AppColors.textColor,
                  ),
                );
              }

              final isAllSelected = _isAllSelected(folders);

              return Column(
                children: [
                  // "All" option at the top
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: InkWell(
                      onTap: () => _toggleSelectAll(folders),
                      child: Row(
                        children: [
                          Container(
                            width: 24.w,
                            height: 24.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAllSelected
                                  ? AppColors.primaryOrange
                                  : Colors.transparent,
                              border: Border.all(
                                color: isAllSelected
                                    ? AppColors.primaryOrange
                                    : Colors.grey,
                                width: 2.w,
                              ),
                            ),
                            child: isAllSelected
                                ? Icon(
                              Icons.check,
                              size: 16.sp,
                              color: AppColors.black,
                            )
                                : null,
                          ),
                          SizedBox(width: 16.w),
                          Texts(
                            "All",
                            fontSize: 16.sp,
                            fontWeight: AppFontWeights.medium,
                            fontFamily: AppFonts.inter,
                            color: AppColors.textColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Folder list
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        final isSelected = _selectedFolders.contains(
                          folder.name,
                        );

                        return InkWell(
                          onTap: () => _toggleFolder(folder.name, folders),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            child: Row(
                              children: [
                                // Checkbox
                                Container(
                                  width: 24.w,
                                  height: 24.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppColors.primaryOrange
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryOrange
                                          : Colors.grey,
                                      width: 2.w,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                    Icons.check,
                                    size: 16.sp,
                                    color: AppColors.black,
                                  )
                                      : null,
                                ),
                                SizedBox(width: 16.w),
                                // Folder info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Texts(
                                        folder.name,
                                        fontSize: 16.sp,
                                        fontWeight: AppFontWeights.medium,
                                        fontFamily: AppFonts.inter,
                                        color: AppColors.textColor,
                                      ),
                                      SizedBox(height: 4.h),
                                      Texts(
                                        "${folder.path}/filename.mp3",
                                        fontSize: 12.sp,
                                        fontWeight: AppFontWeights.regular,
                                        fontFamily: AppFonts.inter,
                                        color: AppColors.textColor.withOpacity(0.6),
                                      ),
                                    ],
                                  ),
                                ),
                                // Song count
                                Texts(
                                  "${folder.songCount}",
                                  fontSize: 18.sp,
                                  fontWeight: AppFontWeights.regular,
                                  fontFamily: AppFonts.inter,
                                  color: AppColors.primaryOrange,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: ElevatedButton(
            onPressed: _confirmSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.r),
              ),
            ),
            child: Texts(
              "Select",
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
}

class _FolderBadge extends StatelessWidget {
  const _FolderBadge({required this.label, required this.isSelected});  final String label;
  final bool isSelected;  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32.w,
      height: 32.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? AppColors.primaryOrange
            : AppColors.primaryOrange.withOpacity(0.12),
        border: Border.all(color: AppColors.primaryOrange, width: 2.w),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? Icon(Icons.check, size: 18.sp, color: AppColors.white)
          : Texts(
              label,
              fontSize: 14.sp,
              fontWeight: AppFontWeights.medium,
              fontFamily: AppFonts.inter,
              color: AppColors.primaryOrange,
            ),
    );
  }
}