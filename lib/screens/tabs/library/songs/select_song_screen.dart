import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/features/playlists/bloc/playlist_bloc.dart';
import 'package:music_app/themes/font.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/app_bar_with_icon_title.dart';
import '../../../../commonWidgets/common_functions.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../themes/color.dart';
import '../../../../utills/snack_bar.dart';
import '../../../play_song/widget/playlist_bottomsheet.dart';
import '../../music_service.dart';

class SelectSongScreen extends StatefulWidget {
  final dynamic playlist;
  final List<SongsModel>? playlistSongs;
  final bool? isSystemPlaylist;

  const SelectSongScreen({
    super.key,
    this.playlist,
    this.playlistSongs,
    this.isSystemPlaylist,
  });

  @override
  State<SelectSongScreen> createState() => _SelectSongScreenState();
}

class _SelectSongScreenState extends State<SelectSongScreen> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool isSelectedAll = false;
  Set<int> selectedSongIds = {}; // Store selected song IDs
  String searchQuery = '';
  final musicService = MusicPlayerService();

  List<String> musicIcons = [
    Assets.pngBand2,
    Assets.svgMusicIcon,
    Assets.pngBand,
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim();
      });
    });

    // Load songs based on context
    if (widget.playlistSongs != null) {
      // We have playlist songs, no need to load from bloc
      // The songs will be passed directly
    } else {
      // Load all songs
      context.read<SongsBloc>().add(const SongsEvent.getAllSongs());
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  // Filter songs based on search query
  List<SongsModel> _filterSongs(List<SongsModel> allSongs) {
    if (searchQuery.isEmpty) return allSongs;

    return allSongs.where((song) {
      return song.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          song.artist.toLowerCase().contains(searchQuery.toLowerCase()) ||
          song.album.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  // Get selected count
  int get selectedCount => selectedSongIds.length;

  // Update select all state based on current filtered list
  void updateSelectAllState(List<SongsModel> filteredSongs) {
    if (filteredSongs.isEmpty) {
      isSelectedAll = false;
      return;
    }

    final allFilteredIds = filteredSongs.map((s) => s.id!).toSet();
    // Only show select all as checked if ALL filtered songs are selected
    isSelectedAll = allFilteredIds.every((id) => selectedSongIds.contains(id));
  }

  // Toggle select all
  void toggleSelectAll(List<SongsModel> filteredSongs) {
    setState(() {
      if (isSelectedAll) {
        // Deselect all from current filtered list
        final filteredIds = filteredSongs.map((s) => s.id!).toSet();
        selectedSongIds.removeAll(filteredIds);
      } else {
        // Select all from current filtered list
        selectedSongIds.addAll(filteredSongs.map((s) => s.id!));
      }
      updateSelectAllState(filteredSongs);
    });
  }

  // Toggle individual selection
  void toggleSelection(int songId, List<SongsModel> filteredSongs) {
    setState(() {
      if (selectedSongIds.contains(songId)) {
        selectedSongIds.remove(songId);
      } else {
        selectedSongIds.add(songId);
      }
      updateSelectAllState(filteredSongs);
    });
  }

  // Get selected songs from IDs
  List<SongsModel> _getSelectedSongs(List<SongsModel> allSongs) {
    return allSongs.where((song) => selectedSongIds.contains(song.id)).toList();
  }

  // Play selected songs
  void _playSelectedSongs(List<SongsModel> allSongs) async {
    final selectedSongs = _getSelectedSongs(allSongs);

    if (selectedSongs.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No songs selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      // Set playlist with selected songs and start playing
      await musicService.setPlaylist(selectedSongs, startIndex: 0);
      await musicService.play();

      showSnackBar(
        context,
        () {},
        message: "Playing ${selectedSongs.length} songs",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      // Navigate back or stay, depending on your preference
      context.pop();
    } catch (e) {
      log('Error playing selected songs: $e');
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error playing songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Delete selected songs from playlist
  void _deleteSelectedSongs(List<SongsModel> allSongs) {
    final selectedSongs = _getSelectedSongs(allSongs);

    if (selectedSongs.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No songs selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    // If we're in playlist context, remove from playlist instead of deleting completely
    if (widget.playlist != null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        isScrollControlled: true,
        builder: (_) => _buildRemoveFromPlaylistConfirmationDialog(
          selectedSongs.length,
          allSongs,
        ),
      );
    } else {
      // Original behavior for library songs (complete deletion)
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        isScrollControlled: true,
        builder: (_) =>
            _buildDeleteConfirmationDialog(selectedSongs.length, allSongs),
      );
    }
  }

  // Add to playlist
  void _addToPlaylist(List<SongsModel> allSongs) {
    final selectedSongs = _getSelectedSongs(allSongs);

    if (selectedSongs.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No songs selected",
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
      builder: (_) => PlaylistBottomSheet(songsList: selectedSongs),
    );
  }

  // Show popup menu for song actions
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
        PopupMenuItem<String>(
          value: 'hide_song',
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            child: Texts(
              'Hide Song',
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
      case 'hide_song':
        _hideSelectedSongs();
        break;
    }
  }

  // Play next selected songs
  void _playNextSelectedSongs() async {
    final selectedSongs = _getSelectedSongs(
      widget.playlistSongs ??
          context.read<SongsBloc>().state.maybeWhen(
            loaded: (songs) => songs,
            orElse: () => <SongsModel>[],
          ),
    );

    if (selectedSongs.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No songs selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      // Check if there are existing songs in the queue
      if (musicService.songs.isEmpty) {
        // No songs in queue - add all selected songs and start playing
        await musicService.setPlaylist(selectedSongs, startIndex: 0);
        await musicService.play();
      } else {
        // Songs exist in queue - insert selected songs after current playing song
        final currentIndex = musicService.currentIndex;
        final insertIndex = currentIndex + 1;

        // Create a new list with selected songs inserted at the right position
        final newSongsList = List<SongsModel>.from(musicService.songs);

        // Filter out songs that are already in the list to avoid duplicates
        final songsToAdd = selectedSongs.where((song) {
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
          message: "${selectedSongs.length} songs added to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        context.pop();
      }
    } catch (e) {
      log('Error adding songs to play next: $e');
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding songs to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Add selected songs to queue
  void _addSelectedSongsToQueue() async {
    final selectedSongs = _getSelectedSongs(
      widget.playlistSongs ??
          context.read<SongsBloc>().state.maybeWhen(
            loaded: (songs) => songs,
            orElse: () => <SongsModel>[],
          ),
    );

    log('Selected songs to add to queue: ${selectedSongs.length}');

    if (selectedSongs.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No songs selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      // Create a copy of the existing songs list
      final newSongsList = List<SongsModel>.from(musicService.songs);

      // Add each selected song to the queue if it's not already there
      int addedCount = 0;
      for (final song in selectedSongs) {
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
          message: "$addedCount songs added to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    } catch (e) {
      log('Error adding songs to queue: $e');
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding songs to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Hide selected songs
  void _hideSelectedSongs() {
    final selectedSongs = _getSelectedSongs(
      widget.playlistSongs ??
          context.read<SongsBloc>().state.maybeWhen(
            loaded: (songs) => songs,
            orElse: () => <SongsModel>[],
          ),
    );

    if (selectedSongs.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No songs selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    // For now, we'll just show a message since hide functionality needs to be implemented
    showSnackBar(
      context,
      () {},
      message: "Hide song functionality will be implemented",
      alertBannerLocation: AlertBannerLocation.bottom,
    );
  }

  // Custom remove from playlist confirmation dialog
  Widget _buildRemoveFromPlaylistConfirmationDialog(
    int songCount,
    List<SongsModel> allSongs,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 10.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
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
            'Remove from Playlist',
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          SizedBox(height: 30.h),

          // Message
          Texts(
            'Are you sure you want to remove these $songCount songs from the playlist?',
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

              // Remove button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Remove selected songs from playlist
                    final selectedSongs = _getSelectedSongs(allSongs);
                    final songIds = selectedSongs
                        .map((song) => song.id!)
                        .toList();

                    // Get playlist ID - handle both regular and system playlists
                    int? playlistId;
                    if (widget.playlist != null) {
                      if (widget.isSystemPlaylist == true) {
                        // For system playlists, we can't remove songs using the regular method
                        // This should not happen as system playlists are read-only
                        Navigator.pop(context);
                        showSnackBar(
                          context,
                          () {},
                          message: "Cannot remove songs from system playlists",
                          alertBannerLocation: AlertBannerLocation.bottom,
                        );
                        return;
                      } else {
                        playlistId = widget.playlist.id;
                      }
                    }

                    if (playlistId != null) {
                      context.read<PlaylistBloc>().add(
                        PlaylistEvent.removeMultipleSongsFromPlaylist(
                          playlistId,
                          songIds,
                        ),
                      );
                    }

                    Navigator.pop(context);
                    setState(() {
                      selectedSongIds.clear();
                      isSelectedAll = false;
                    });

                    showSnackBar(
                      context,
                      () {},
                      message: "$songCount songs removed from playlist!",
                      alertBannerLocation: AlertBannerLocation.bottom,
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Texts(
                        'Remove',
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

  // Custom delete confirmation dialog matching the design
  Widget _buildDeleteConfirmationDialog(
    int songCount,
    List<SongsModel> allSongs,
  ) {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 10.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
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
            'Delete Song',
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          SizedBox(height: 30.h),

          // Message
          Texts(
            'Are you sure you want to delete these $songCount songs?',
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
                    // Delete all selected songs
                    final selectedSongs = _getSelectedSongs(allSongs);
                    for (var song in selectedSongs) {
                      context.read<SongsBloc>().add(
                        SongsEvent.removeSong(song.id!),
                      );
                    }

                    Navigator.pop(context);
                    setState(() {
                      selectedSongIds.clear();
                      isSelectedAll = false;
                    });

                    showSnackBar(
                      context,
                      () {},
                      message: "$songCount songs deleted successfully!",
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

  // Helper method to build content for playlist songs
  Widget _buildPlaylistSongsContent() {
    final filteredSongs = _filterSongs(widget.playlistSongs!);
    updateSelectAllState(filteredSongs);

    if (widget.playlistSongs!.isEmpty) {
      return const Center(
        child: Text(
          "No songs in this playlist",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return _buildSongsContent(widget.playlistSongs!, filteredSongs);
  }

  // Helper method to build the songs content
  Widget _buildSongsContent(
    List<SongsModel> allSongs,
    List<SongsModel> filteredSongs,
  ) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
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
                hintText: S.of(context).searchSongs,
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

        // Selected count and Select All
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
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
              GestureDetector(
                onTap: () => toggleSelectAll(filteredSongs),
                child: SvgPicture.asset(
                  isSelectedAll
                      ? Assets.svgIcRadioCheckl
                      : Assets.svgIcRadioUncheck,
                  height: 20.h,
                  width: 20.w,
                ),
              ),
              SizedBox(width: 10.w),
              Texts(
                S.of(context).selectAll,
                fontSize: 14.sp,
                fontFamily: AppFonts.inter,
                fontWeight: FontWeight.w400,
                color: AppColors.textColor,
              ),
            ],
          ),
        ),

        // Songs list
        Expanded(
          child: filteredSongs.isEmpty
              ? Center(
                  child: Texts(
                    "No songs match your search",
                    fontSize: 16.sp,
                    color: AppColors.textColor,
                  ),
                )
              : ListView.builder(
                  itemCount: filteredSongs.length,
                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                  itemBuilder: (context, index) {
                    final song = filteredSongs[index];
                    final isSelected = selectedSongIds.contains(song.id);

                    final image = (index % 2 == 0)
                        ? musicIcons[0]
                        : (index % 3 == 0)
                        ? musicIcons[1]
                        : musicIcons[2];

                    return MusicListTile(
                      margin: 7.w,
                      height: 66.h,
                      borderRadius: 10.r,
                      backgroundColor: AppColors.musicTileBackgroundColor,
                      cardHeight: 50.h,
                      cardWidth: 50.w,
                      cardRadius: 7.r,
                      cardIconAsset: song.artwork_path ?? image,
                      cardIconSize: 32.r,
                      isSvgCardIcon: image.contains('.svg'),
                      title: song.title,
                      subtitle: song.artist,
                      songLength: formatDuration(song.duration),
                      songLengthRequired: true,
                      trailingIconAsset: isSelected
                          ? Assets.svgIcCheck
                          : Assets.svgIcUncheck,
                      trailingIconHeight: 20.h,
                      trailingIconWidth: 10.w,
                      trailingMargin: 2.w,
                      onTap: () => toggleSelection(song.id!, filteredSongs),
                      onPlayTap: () => toggleSelection(song.id!, filteredSongs),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithIconTitle(
        title: S.of(context).selectSongs,
        isActionBtnDisplay: true,
        onTapAction: () => _showPopupMenu(context),
      ),
      body: widget.playlistSongs != null
          ? _buildPlaylistSongsContent()
          : BlocBuilder<SongsBloc, SongsState>(
              builder: (context, state) {
                return state.when(
                  initial: () => const Center(child: Text("Initializing...")),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (message) => Center(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                  loaded: (allSongs) {
                    final filteredSongs = _filterSongs(allSongs);

                    // Update select all state based on current filtered results
                    updateSelectAllState(filteredSongs);

                    if (allSongs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No songs available",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    return _buildSongsContent(allSongs, filteredSongs);
                  },
                );
              },
            ),
      bottomNavigationBar: widget.playlistSongs != null
          ? _buildPlaylistBottomBar()
          : BlocBuilder<SongsBloc, SongsState>(
              builder: (context, state) {
                return state.maybeWhen(
                  loaded: (allSongs) {
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
                                onTap: () => _playSelectedSongs(allSongs),
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
                                onTap: () => _addToPlaylist(allSongs),
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
                                onTap: () => _deleteSelectedSongs(allSongs),
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

  // Build bottom bar for playlist songs
  Widget _buildPlaylistBottomBar() {
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
                onTap: () => _playSelectedSongs(widget.playlistSongs!),
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
                onTap: () => _addToPlaylist(widget.playlistSongs!),
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
                onTap: () => _deleteSelectedSongs(widget.playlistSongs!),
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
  }
}
