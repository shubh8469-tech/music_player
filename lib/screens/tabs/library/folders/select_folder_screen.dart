import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/folders/bloc/folder_bloc.dart';
import 'package:music_app/features/folders/domain/entities/folder.dart'
    as domain;
import 'package:music_app/features/folders/domain/repositories/folder_repository.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/app_bar_with_icon_title.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../themes/color.dart';
import '../../../../utills/snack_bar.dart';
import '../../music_service.dart';
import 'package:go_router/go_router.dart';
import '../../../play_song/widget/playlist_bottomsheet.dart';

class SelectFolderScreen extends StatefulWidget {
  const SelectFolderScreen({super.key});

  @override
  State<SelectFolderScreen> createState() => _SelectFolderScreenState();
}

class _SelectFolderScreenState extends State<SelectFolderScreen> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool isSelectedAll = false;
  Set<int> selectedFolderIds = {}; // Store selected folder IDs
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim();
      });
    });

    // Load all folders
    context.read<FolderBloc>().add(const FolderEvent.fetchAllFolders());
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  // Filter folders based on search query
  List<domain.Folder> _filterFolders(List<domain.Folder> allFolders) {
    if (searchQuery.isEmpty) return allFolders;

    return allFolders.where((folder) {
      return folder.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  // Get selected count
  int get selectedCount => selectedFolderIds.length;

  // Update select all state based on current filtered list
  void updateSelectAllState(List<domain.Folder> filteredFolders) {
    if (filteredFolders.isEmpty) {
      isSelectedAll = false;
      return;
    }

    final allIds = filteredFolders.map((f) => f.id!).toSet();
    // Only show select all as checked if ALL folders are selected
    isSelectedAll = allIds.every((id) => selectedFolderIds.contains(id));
  }

  // Toggle select all
  void toggleSelectAll(List<domain.Folder> filteredFolders) {
    setState(() {
      if (isSelectedAll) {
        // Deselect all from current filtered list
        final filteredIds = filteredFolders.map((f) => f.id!).toSet();
        selectedFolderIds.removeAll(filteredIds);
      } else {
        // Select all from current filtered list
        selectedFolderIds.addAll(filteredFolders.map((f) => f.id!));
      }
      updateSelectAllState(filteredFolders);
    });
  }

  // Toggle individual selection
  void toggleSelection(int folderId, List<domain.Folder> filteredFolders) {
    setState(() {
      if (selectedFolderIds.contains(folderId)) {
        selectedFolderIds.remove(folderId);
      } else {
        selectedFolderIds.add(folderId);
      }
      updateSelectAllState(filteredFolders);
    });
  }

  // Get selected folders from IDs
  List<domain.Folder> _getSelectedFolders(List<domain.Folder> allFolders) {
    return allFolders
        .where((folder) => selectedFolderIds.contains(folder.id))
        .toList();
  }

  // Delete selected folders
  void _deleteSelectedFolders(List<domain.Folder> allFolders) {
    final selectedFolders = _getSelectedFolders(allFolders);

    if (selectedFolders.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No folders selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      isScrollControlled: true,
      builder: (_) => _buildDeleteConfirmationDialog(
        selectedFolders.length,
        selectedFolders,
      ),
    );
  }

  // Show popup menu for folder actions
  void _showPopupMenu(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // Position the menu in the top right corner below the app bar
    final RelativeRect position = RelativeRect.fromLTRB(
      overlay.size.width - 200.w, // Left (200px from right edge)
      100.h, // Top (below app bar)
      0, // Right
      overlay.size.height - 100.h, // Bottom
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      color: AppColors.white,
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'play_next',
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            child: Texts(
              'Play Next',
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              fontFamily: AppFonts.inter,
              color: AppColors.textColor,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'add_to_queue',
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            child: Texts(
              'Add To Queue',
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              fontFamily: AppFonts.inter,
              color: AppColors.textColor,
            ),
          ),
        ),
      ],
    ).then((String? value) {
      if (value != null) {
        _handlePopupMenuAction(value);
      }
    });
  }

  // Handle popup menu actions
  void _handlePopupMenuAction(String action) {
    switch (action) {
      case 'play_next':
        _playNextSelectedSongs();
        break;
      case 'add_to_queue':
        _addSelectedSongsToQueue();
        break;
    }
  }

  // Play next selected folders
  void _playNextSelectedSongs() async {
    final selectedFolders = _getSelectedFolders(
      context.read<FolderBloc>().state.maybeWhen(
        loaded: (folders, folderSongs) => folders,
        orElse: () => <domain.Folder>[],
      ),
    );

    if (selectedFolders.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No folders selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final musicService = MusicPlayerService();
      final _repo = locator<FolderRepository>();
      List<SongsModel> allSongsFromFolders = [];

      // Fetch all songs from selected folders
      for (var folder in selectedFolders) {
        List<SongsModel> folderSongs = (await _repo.getSongsForFolder(
          folder.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in folderSongs) {
          if (!allSongsFromFolders.any((s) => s.id == song.id)) {
            allSongsFromFolders.add(song);
          }
        }
      }

      if (allSongsFromFolders.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected folders contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Check if there are existing songs in the queue
      if (musicService.songs.isEmpty) {
        // No songs in queue - add all selected songs and start playing
        await musicService.setPlaylist(allSongsFromFolders, startIndex: 0);
        await musicService.play();
      } else {
        // Songs exist in queue - insert selected songs after current playing song
        final currentIndex = musicService.currentIndex;
        final insertIndex = currentIndex + 1;

        // Create a new list with selected songs inserted at the right position
        final newSongsList = List<SongsModel>.from(musicService.songs);

        // Filter out songs that are already in the list to avoid duplicates
        final songsToAdd = allSongsFromFolders.where((song) {
          return !newSongsList.any(
            (existingSong) => existingSong.id == song.id,
          );
        }).toList();

        // Insert songs at the position after current playing song
        newSongsList.insertAll(insertIndex, songsToAdd);

        // Update the playlist, keeping the current song playing
        await musicService.setPlaylist(
          newSongsList,
          startIndex: currentIndex >= 0 ? currentIndex : 0,
          autoPlay: false,
        );
      }

      if (mounted) {
        showSnackBar(
          context,
          () {},
          message:
              "${allSongsFromFolders.length} songs from ${selectedFolders.length} folders added to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding folders to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Add selected folders to queue
  void _addSelectedSongsToQueue() async {
    final selectedFolders = _getSelectedFolders(
      context.read<FolderBloc>().state.maybeWhen(
        loaded: (folders, folderSongs) => folders,
        orElse: () => <domain.Folder>[],
      ),
    );

    if (selectedFolders.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No folders selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final musicService = MusicPlayerService();
      final _repo = locator<FolderRepository>();
      List<SongsModel> allSongsFromFolders = [];

      // Fetch all songs from selected folders
      for (var folder in selectedFolders) {
        List<SongsModel> folderSongs = (await _repo.getSongsForFolder(
          folder.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in folderSongs) {
          if (!allSongsFromFolders.any((s) => s.id == song.id)) {
            allSongsFromFolders.add(song);
          }
        }
      }

      if (allSongsFromFolders.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected folders contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Create a copy of the existing songs list
      final newSongsList = List<SongsModel>.from(musicService.songs);

      // Add each selected song to the queue if it's not already there
      int addedCount = 0;
      for (final song in allSongsFromFolders) {
        final existingIndex = newSongsList.indexWhere(
          (existingSong) => existingSong.id == song.id,
        );

        if (existingIndex == -1) {
          newSongsList.add(song);
          addedCount++;
        }
      }

      // Update the playlist with the new songs list
      await musicService.setPlaylist(newSongsList);

      if (mounted) {
        showSnackBar(
          context,
          () {},
          message:
              "$addedCount songs from ${selectedFolders.length} folders added to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding folders to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Play selected folders
  void _playSelectedFolders(List<domain.Folder> allFolders) async {
    final selectedFolders = _getSelectedFolders(allFolders);

    if (selectedFolders.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No folders selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final musicService = MusicPlayerService();
      final _repo = locator<FolderRepository>();
      List<SongsModel> allSongsFromFolders = [];

      // Fetch all songs from selected folders
      for (var folder in selectedFolders) {
        List<SongsModel> folderSongs = (await _repo.getSongsForFolder(
          folder.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in folderSongs) {
          if (!allSongsFromFolders.any((s) => s.id == song.id)) {
            allSongsFromFolders.add(song);
          }
        }
      }

      if (allSongsFromFolders.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected folders contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Set the combined playlist and start playing
      await musicService.setPlaylist(allSongsFromFolders, startIndex: 0);
      await musicService.play();

      showSnackBar(
        context,
        () {},
        message:
            "Playing ${allSongsFromFolders.length} songs from ${selectedFolders.length} folders",
        alertBannerLocation: AlertBannerLocation.bottom,
      );

      // Navigate back
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error playing folders: $e",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add songs from selected folders to playlist
  void _addSongsToSelectedFolders(List<domain.Folder> allFolders) async {
    final selectedFolders = _getSelectedFolders(allFolders);

    if (selectedFolders.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No folders selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final _repo = locator<FolderRepository>();
      List<SongsModel> allSongsFromFolders = [];

      // Fetch all songs from selected folders
      for (var folder in selectedFolders) {
        List<SongsModel> folderSongs = (await _repo.getSongsForFolder(
          folder.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in folderSongs) {
          if (!allSongsFromFolders.any((s) => s.id == song.id)) {
            allSongsFromFolders.add(song);
          }
        }
      }

      if (allSongsFromFolders.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected folders contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Show playlist bottom sheet with all songs from selected folders
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
          ),
          isScrollControlled: true,
          builder: (_) => PlaylistBottomSheet(songsList: allSongsFromFolders),
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error fetching songs from folders: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Build folder section with header and items
  List<Widget> _buildFolderSection(String title, List<domain.Folder> folders) {
    if (folders.isEmpty) return [];

    return [
      // Section header
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        child: Row(
          children: [
            Texts(
              title,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.inter,
              color: AppColors.textColor,
            ),
          ],
        ),
      ),

      // Folder items
      ...folders.map((folder) {
        final isSelected = selectedFolderIds.contains(folder.id);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: MusicListTile(
            margin: 7.w,
            height: 66.h,
            borderRadius: 10.r,
            backgroundColor: AppColors.musicTileBackgroundColor,
            cardHeight: 50.h,
            cardWidth: 50.w,
            cardRadius: 7.r,
            cardIconAsset: Assets.svgDirectory,
            cardIconSize: 32.r,
            isSvgCardIcon: true,
            title: folder.name,
            subtitle: '${folder.songCount} Songs',
            trailingIconAsset: isSelected
                ? Assets.svgIcCheck
                : Assets.svgIcUncheck,
            trailingIconHeight: 20.h,
            trailingIconWidth: 10.w,
            trailingMargin: 2.w,
            onTap: () => toggleSelection(folder.id!, folders),
            onPlayTap: () => toggleSelection(folder.id!, folders),
          ),
        );
      }).toList(),
    ];
  }

  // Custom delete confirmation dialog matching the design
  Widget _buildDeleteConfirmationDialog(
    int folderCount,
    List<domain.Folder> deletableFolders,
  ) {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 10.h,
        bottom: bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 30.h),

          // Title
          Texts(
            'Delete Folders',
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          SizedBox(height: 30.h),

          // Message
          Texts(
            'Are you sure you want to delete ${folderCount == 1 ? 'this folder' : 'these $folderCount folders'}?',
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
            align: TextAlign.center,
          ),
          SizedBox(height: 25.h),

          // Action buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.r),
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
              SizedBox(width: 12.w),

              // Delete button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Delete all deletable folders
                    for (var folder in deletableFolders) {
                      context.read<FolderBloc>().add(
                        FolderEvent.deleteFolder(folder.id!),
                      );
                    }

                    Navigator.pop(context);
                    setState(() {
                      selectedFolderIds.clear();
                      isSelectedAll = false;
                    });

                    showSnackBar(
                      context,
                      () {},
                      message:
                          "$folderCount ${folderCount == 1 ? 'folder' : 'folders'} deleted successfully!",
                      alertBannerLocation: AlertBannerLocation.bottom,
                    );
                  },
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Texts(
                        S.of(context).delete,
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
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: 'Select Folders',
        isActionBtnDisplay: true,
        onTapAction: () => _showPopupMenu(context),
      ),
      body: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text("Initializing...")),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
            loaded: (allFolders, folderSongs) {
              final filteredFolders = _filterFolders(allFolders);

              // Update select all state based on current filtered results
              updateSelectAllState(filteredFolders);

              if (allFolders.isEmpty) {
                return const Center(
                  child: Text(
                    "No folders available",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: [
                  // Search bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 20.h,
                    ),
                    child: Container(
                      height: 48.h,
                      width: 343.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        color: AppColors.black.withValues(alpha: .14),
                      ),
                      child: TextFormField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 14.w, right: 10.w),
                            child: SvgPicture.asset(Assets.svgIcSerach),
                          ),
                          hintText: 'Search Folders',
                          hintStyle: TextStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFonts.inter,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // If searching and no results, show only the message
                  if (filteredFolders.isEmpty && searchQuery.isNotEmpty)
                    Expanded(
                      child: Center(
                        child: Texts(
                          "No folders match your search",
                          fontSize: 16.sp,
                          color: AppColors.textColor,
                        ),
                      ),
                    )
                  else ...[
                    // Selected count and Select All
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 5.h,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Texts(
                              selectedCount != 0
                                  ? "$selectedCount ${S.of(context).selected}"
                                  : "",
                              fontSize: 14.sp,
                              fontFamily: AppFonts.inter,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textColor,
                            ),
                          ),
                          Texts(
                            S.of(context).selectAll,
                            fontSize: 14.sp,
                            fontFamily: AppFonts.inter,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textColor,
                          ),
                          SizedBox(width: 10.w),
                          GestureDetector(
                            onTap: () => toggleSelectAll(filteredFolders),
                            child: SvgPicture.asset(
                              isSelectedAll
                                  ? Assets.svgIcRadioCheckl
                                  : Assets.svgIcRadioUncheck,
                              height: 20.h,
                              width: 20.w,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Folders list
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Folders Section
                            ..._buildFolderSection(
                              'My Folders (${filteredFolders.length})',
                              filteredFolders,
                            ),
                            SizedBox(height: 90.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<FolderBloc, FolderState>(
        builder: (context, state) {
          return state.maybeWhen(
            loaded: (allFolders, folderSongs) {
              return Visibility(
                visible: selectedCount > 0,
                child: SafeArea(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    margin: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () => _playSelectedFolders(allFolders),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(Assets.svgIcNavPlay),
                              SizedBox(height: 3.h),
                              Texts(
                                S.of(context).play,
                                fontSize: 12.sp,
                                fontFamily: AppFonts.inter,
                                fontWeight: FontWeight.w400,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _addSongsToSelectedFolders(allFolders),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(Assets.svgIcNavPlaylist),
                              SizedBox(height: 3.h),
                              Texts(
                                S.of(context).addToPlaylist,
                                fontSize: 12.sp,
                                fontFamily: AppFonts.inter,
                                fontWeight: FontWeight.w400,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _deleteSelectedFolders(allFolders),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(Assets.svgIcNavDelete),
                              SizedBox(height: 3.h),
                              Texts(
                                S.of(context).delete,
                                fontSize: 12.sp,
                                fontFamily: AppFonts.inter,
                                fontWeight: FontWeight.w400,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
