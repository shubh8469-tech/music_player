import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/commonWidgets/app_bar_with_icon_title.dart';
import 'package:music_app/commonWidgets/common_modal_bottom_sheet.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

class SelectQueueScreen extends StatefulWidget {
  const SelectQueueScreen({super.key});

  @override
  State<SelectQueueScreen> createState() => _SelectQueueScreenState();
}

class _SelectQueueScreenState extends State<SelectQueueScreen> {
  List<SongsModel> allSongs = [];
  Set<int> selectedSongs = {};
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllSongs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAllSongs() {
    // Load all available songs - this would typically come from your database
    // For now, using a sample list
    setState(() {
      allSongs = [
        SongsModel(
          id: 1,
          title: "As It Was",
          artist: "Harry Styles",
          album: "Harry's House",
          genre: "Pop",
          filePath: "/path/to/song1.mp3",
          folder: "Download",
          duration: 167,
        ),
        SongsModel(
          id: 2,
          title: "Memories",
          artist: "Maroon 5",
          album: "Memories",
          genre: "Pop",
          filePath: "/path/to/song2.mp3",
          folder: "Download",
          duration: 189,
        ),
        SongsModel(
          id: 3,
          title: "Baby",
          artist: "Justin Bieber",
          album: "My World 2.0",
          genre: "Pop",
          filePath: "/path/to/song3.mp3",
          folder: "Folder",
          duration: 210,
        ),
      ];
    });
  }

  void _toggleSongSelection(int index) {
    setState(() {
      if (selectedSongs.contains(index)) {
        selectedSongs.remove(index);
      } else {
        selectedSongs.add(index);
      }
    });
  }

  void _selectAllSongs() {
    setState(() {
      if (selectedSongs.length == allSongs.length) {
        selectedSongs.clear();
      } else {
        selectedSongs = Set.from(
          List.generate(allSongs.length, (index) => index),
        );
      }
    });
  }

  List<SongsModel> get _filteredSongs {
    if (searchQuery.isEmpty) return allSongs;
    return allSongs
        .where(
          (song) =>
              song.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              song.artist.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _playNext() {
    if (selectedSongs.isEmpty) return;

    final selectedSongList = selectedSongs
        .map((index) => _filteredSongs[index])
        .toList();
    final musicService = MusicPlayerService();
    musicService.setPlaylist(selectedSongList);

    Navigator.of(context).pop();
  }

  void _addToPlaylist() {
    if (selectedSongs.isEmpty) return;

    final selectedSongList = selectedSongs
        .map((index) => _filteredSongs[index])
        .toList();
    showCommonAddToPlaylistBottomSheet(context, songsList: selectedSongList);
  }

  void _deleteSelected() {
    if (selectedSongs.isEmpty) return;

    showCommonConfirmationBottomSheet(
      context: context,
      title: 'Delete Songs',
      message:
          'Are you sure you want to delete ${selectedSongs.length} song(s)?',
      onConfirm: (sheetContext) async {
        Navigator.pop(sheetContext);
        setState(() {
          final indicesToRemove = selectedSongs.toList()
            ..sort((a, b) => b.compareTo(a));
          for (int index in indicesToRemove) {
            allSongs.removeAt(index);
          }
          selectedSongs.clear();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSongs = _filteredSongs;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: "Select Queue",
        backgroundColor: AppColors.primaryOrange,
        titleColor: AppColors.white,
        centerTitle: false,
        onBack: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: () {
              // Show more options
            },
            icon: SvgPicture.asset(
              Assets.svgIcDots,
              height: 26.h,
              width: 26.w,
              colorFilter: const ColorFilter.mode(
                AppColors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16.w),
            child: Container(
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.musicTileBackgroundColor,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search Songs",
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.mediumDarkGrey,
                    fontFamily: AppFonts.inter,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SvgPicture.asset(
                      Assets.svgIcSerach,
                      width: 16.w,
                      height: 16.h,
                      colorFilter: const ColorFilter.mode(
                        AppColors.mediumDarkGrey,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                ),
              ),
            ),
          ),

          // Selection Summary
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Texts(
                  "${selectedSongs.length} Selected",
                  fontSize: 14.sp,
                  color: AppColors.textColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFonts.inter,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _selectAllSongs,
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        selectedSongs.length == filteredSongs.length
                            ? Assets.svgIcCheck
                            : Assets.svgIcUncheck,
                        width: 20.w,
                        height: 20.h,
                        colorFilter: ColorFilter.mode(
                          selectedSongs.length == filteredSongs.length
                              ? AppColors.primaryOrange
                              : AppColors.mediumDarkGrey,
                          BlendMode.srcIn,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Texts(
                        "Select All",
                        fontSize: 14.sp,
                        color: AppColors.textColor,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.inter,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Songs List
          Expanded(
            child: filteredSongs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          Assets.svgIcSerach,
                          width: 60.w,
                          height: 60.h,
                          colorFilter: const ColorFilter.mode(
                            AppColors.mediumDarkGrey,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Texts(
                          searchQuery.isEmpty
                              ? "No songs available"
                              : "No songs found",
                          fontSize: 16.sp,
                          color: AppColors.mediumDarkGrey,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.inter,
                        ),
                        if (searchQuery.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Texts(
                            "Try a different search term",
                            fontSize: 14.sp,
                            color: AppColors.mediumDarkGrey,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFonts.inter,
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = filteredSongs[index];
                      final isSelected = selectedSongs.contains(index);

                      return Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        child: _buildSongItem(song, index, isSelected),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomAction(
              icon: Assets.svgIcMenuPlaynext,
              label: "Play Next",
              onTap: _playNext,
            ),
            _buildBottomAction(
              icon: Assets.svgIcMenuPlaylist,
              label: "Add to playlist",
              onTap: _addToPlaylist,
            ),
            _buildBottomAction(
              icon: Assets.svgIcDelete,
              label: "Delete",
              onTap: _deleteSelected,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem(SongsModel song, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleSongSelection(index),
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.1)
              : AppColors.musicTileBackgroundColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            SizedBox(width: 16.w),

            // Song artwork or icon
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: song.artwork_path != null && song.artwork_path!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: (song.artwork_path!.endsWith('.svg'))
                          ? SvgPicture.asset(
                              song.artwork_path!,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(song.artwork_path!),
                              fit: BoxFit.cover,
                            ),
                    )
                  : SvgPicture.asset(
                      Assets.svgMusicIcon,
                      width: 24.w,
                      height: 24.h,
                      colorFilter: const ColorFilter.mode(
                        AppColors.white,
                        BlendMode.srcIn,
                      ),
                    ),
            ),

            SizedBox(width: 12.w),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Texts(
                    song.title,
                    fontSize: 14.sp,
                    color: AppColors.black,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.inter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Texts(
                    "${song.artist} - ${song.folder ?? 'Unknown'}",
                    fontSize: 12.sp,
                    color: AppColors.textColor,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.inter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Selection checkbox
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryOrange
                        : AppColors.mediumDarkGrey,
                    width: 2,
                  ),
                  color: isSelected
                      ? AppColors.primaryOrange
                      : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(Icons.check, color: AppColors.white, size: 16.sp)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              icon,
              width: 24.w,
              height: 24.h,
              colorFilter: ColorFilter.mode(
                isDestructive ? Colors.red : AppColors.primaryOrange,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: 4.h),
            Texts(
              label,
              fontSize: 12.sp,
              color: isDestructive ? Colors.red : AppColors.textColor,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.inter,
            ),
          ],
        ),
      ),
    );
  }
}
