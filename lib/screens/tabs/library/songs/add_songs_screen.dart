import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/common_functions.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/playlists/bloc/playlist_bloc.dart';
import '../../../../features/playlists/domain/repositories/playlist_repository.dart';
import '../../../../generated/assets.dart';
import '../../../../themes/color.dart';
import '../../../../utills/snack_bar.dart';
import '../../music_service.dart';

/// AddSongsScreen - A screen for adding songs to a playlist
///
/// Usage:
/// ```dart
/// // Navigate to AddSongsScreen with a playlist
/// context.push('/dashboard/add-songs', extra: playlistObject);
/// ```
class AddSongsScreen extends StatefulWidget {
  final dynamic playlist; // The playlist to add songs to

  const AddSongsScreen({super.key, required this.playlist});

  @override
  State<AddSongsScreen> createState() => _AddSongsScreenState();
}

class _AddSongsScreenState extends State<AddSongsScreen> {
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

    // Load all songs
    context.read<SongsBloc>().add(const SongsEvent.getAllSongs());
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

  // Add selected songs to playlist
  Future<void> _addSelectedSongsToPlaylist(List<SongsModel> allSongs) async {
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

    final playlistBloc = context.read<PlaylistBloc>();

    final repoPlaylist = locator<PlaylistRepository>();
    final repoSongs = await repoPlaylist.getSongsForPlaylist(widget.playlist.id);
    List<int> songIds = [];

    for (var song in selectedSongs) {
      final existingIndex = repoSongs.indexWhere((s) => s.id == song.id);
      log('existingIndex $existingIndex');
      if (existingIndex == -1) {
        songIds.add(song.id!);
      }
    }

    // final songIds = selectedSongs.map((song) => song.id!).toList();

    if(songIds.isNotEmpty){
      playlistBloc.add(
        PlaylistEvent.addMultipleSongsToPlaylist(widget.playlist.id, songIds),
      );
      showSnackBar(
        context,
            () {},
        message: "${songIds.length} songs added to playlist",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
    else{
      showSnackBar(
        context,
            () {},
        message: "Already added to playlist",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }


    // Navigate back to previous screen
    context.pop();
  }

  // Cancel action
  void _cancel() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Songs',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: AppFonts.inter,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SongsBloc, SongsState>(
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

              return Column(
                children: [
                  // Search bar
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 20.h,
                    ),
                    height: 48.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      color: Colors.grey[200],
                    ),
                    child: TextFormField(
                      controller: searchController,
                      focusNode: searchFocusNode,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 14.w, right: 10.w),
                          child: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        hintText: 'Search Songs',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFonts.inter,
                          fontSize: 16.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ),

                  // If searching and no results, show only the message
                  if (filteredSongs.isEmpty && searchQuery.isNotEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          "No songs match your search",
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColors.textColor,
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // Selected count and Select All
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 5.h,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedCount != 0
                                  ? "$selectedCount Selected"
                                  : "",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontFamily: AppFonts.inter,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textColor,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => toggleSelectAll(filteredSongs),
                            child: Container(
                              margin: EdgeInsets.only(right: 10.w),
                              child: Row(
                                children: [
                                  Text(
                                    'Select All',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontFamily: AppFonts.inter,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textColor,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Container(
                                    width: 20.w,
                                    height: 20.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelectedAll
                                            ? AppColors.primaryOrange
                                            : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                      color: isSelectedAll
                                          ? AppColors.primaryOrange
                                          : Colors.transparent,
                                    ),
                                    child: isSelectedAll
                                        ? const Icon(
                                            Icons.check,
                                            color: AppColors.white,
                                            size: 12,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Songs list
                    Expanded(
                      child: ListView.builder(
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
                            cardWidth: 50.h,
                            cardRadius: 7.r,
                            cardIconAsset: song.artwork_path ?? image,
                            cardIconSize: 32.r,
                            isSvgCardIcon: image.contains('.svg'),
                            title: song.title,
                            subtitle: song.artist,
                            trailingIconAsset: isSelected
                                ? Assets.svgIcCheck
                                : Assets.svgIcUncheck,
                            trailingIconHeight: 20.h,
                            trailingIconWidth: 20.w,
                            trailingMargin: 10.w,
                            songLength: formatDuration(song.duration),
                            songLengthRequired: true,
                            onTap: () =>
                                toggleSelection(song.id!, filteredSongs),
                            onPlayTap: () =>
                                toggleSelection(song.id!, filteredSongs),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<SongsBloc, SongsState>(
        builder: (context, state) {
          return state.maybeWhen(
            loaded: (allSongs) {
              return SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 16.h,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: GestureDetector(
                          onTap: _cancel,
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFonts.inter,
                                  color: AppColors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),

                      // Add button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _addSelectedSongsToPlaylist(allSongs),
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFonts.inter,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
