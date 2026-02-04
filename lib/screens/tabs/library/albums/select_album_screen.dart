import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/albums/bloc/album_bloc.dart';
import 'package:music_app/features/albums/domain/entities/album.dart';
import 'package:music_app/features/albums/domain/repositories/album_repository.dart';
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
import '../../../../commonWidgets/common_modal_bottom_sheet.dart';

class SelectAlbumScreen extends StatefulWidget {
  const SelectAlbumScreen({super.key});

  @override
  State<SelectAlbumScreen> createState() => _SelectAlbumScreenState();
}

class _SelectAlbumScreenState extends State<SelectAlbumScreen> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool isSelectedAll = false;
  Set<int> selectedAlbumIds = {}; // Store selected album IDs
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim();
      });
    });

    // Load all albums
    context.read<AlbumBloc>().add(const AlbumEvent.fetchAllAlbums());
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  // Filter albums based on search query
  List<Album> _filterAlbums(List<Album> allAlbums) {
    if (searchQuery.isEmpty) return allAlbums;

    return allAlbums.where((album) {
      return album.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (album.artist?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false);
    }).toList();
  }

  // Get selected count
  int get selectedCount => selectedAlbumIds.length;

  // Update select all state based on current filtered list
  void updateSelectAllState(List<Album> filteredAlbums) {
    if (filteredAlbums.isEmpty) {
      isSelectedAll = false;
      return;
    }

    final allIds = filteredAlbums.map((a) => a.id!).toSet();
    // Only show select all as checked if ALL albums are selected
    isSelectedAll = allIds.every((id) => selectedAlbumIds.contains(id));
  }

  // Toggle select all
  void toggleSelectAll(List<Album> filteredAlbums) {
    setState(() {
      if (isSelectedAll) {
        // Deselect all from current filtered list
        final filteredIds = filteredAlbums.map((a) => a.id!).toSet();
        selectedAlbumIds.removeAll(filteredIds);
      } else {
        // Select all from current filtered list
        selectedAlbumIds.addAll(filteredAlbums.map((a) => a.id!));
      }
      updateSelectAllState(filteredAlbums);
    });
  }

  // Toggle individual selection
  void toggleSelection(int albumId, List<Album> filteredAlbums) {
    setState(() {
      if (selectedAlbumIds.contains(albumId)) {
        selectedAlbumIds.remove(albumId);
      } else {
        selectedAlbumIds.add(albumId);
      }
      updateSelectAllState(filteredAlbums);
    });
  }

  // Get selected albums from IDs
  List<Album> _getSelectedAlbums(List<Album> allAlbums) {
    return allAlbums
        .where((album) => selectedAlbumIds.contains(album.id))
        .toList();
  }

  // Delete selected albums
  void _deleteSelectedAlbums(List<Album> allAlbums) {
    final selectedAlbums = _getSelectedAlbums(allAlbums);

    if (selectedAlbums.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No albums selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    final albumCount = selectedAlbums.length;
    showCommonConfirmationBottomSheet(
      context: context,
      title: 'Delete Albums',
      message:
          'Are you sure you want to delete ${albumCount == 1 ? 'this album' : 'these $albumCount albums'}?',
      onConfirm: (sheetContext) async {
        Navigator.pop(sheetContext);
        setState(() {
          selectedAlbumIds.clear();
          isSelectedAll = false;
        });
        showSnackBar(
          context,
          () {},
          message:
              "$albumCount ${albumCount == 1 ? 'album' : 'albums'} deleted successfully!",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      },
    );
  }

  // Show popup menu for album actions
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

  // Play next selected albums
  void _playNextSelectedSongs() async {
    final selectedAlbums = _getSelectedAlbums(
      context.read<AlbumBloc>().state.maybeWhen(
        loaded: (albums, albumSongs) => albums,
        orElse: () => <Album>[],
      ),
    );

    if (selectedAlbums.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No albums selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final musicService = MusicPlayerService();
      final _repo = locator<AlbumRepository>();
      List<SongsModel> allSongsFromAlbums = [];

      // Fetch all songs from selected albums
      for (var album in selectedAlbums) {
        List<SongsModel> albumSongs = (await _repo.getSongsForAlbum(
          album.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in albumSongs) {
          if (!allSongsFromAlbums.any((s) => s.id == song.id)) {
            allSongsFromAlbums.add(song);
          }
        }
      }

      if (allSongsFromAlbums.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected albums contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Check if there are existing songs in the queue
      if (musicService.songs.isEmpty) {
        // No songs in queue - add all selected songs and start playing

        // context.pop();
        showSnackBar(
          context,
          () {},
          message: "${allSongsFromAlbums.length} songs added to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );

        await musicService.setPlaylist(allSongsFromAlbums, startIndex: 0);
        await musicService.play();
      } else {
        final updateCount = await musicService.playNextMultipleSongs(
          allSongsFromAlbums,
        );
        if (updateCount < 1) {
          showSnackBar(
            context,
            () {},
            message: "Songs already added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        } else {
          showSnackBar(
            context,
            () {},
            message: "$updateCount songs added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
        // Songs exist in queue - insert selected songs after current playing song
        // final currentIndex = musicService.currentIndex;
        // final insertIndex = currentIndex + 1;
        //
        // // Create a new list with selected songs inserted at the right position
        // final newSongsList = List<SongsModel>.from(musicService.songs);
        //
        // // Filter out songs that are already in the list to avoid duplicates
        // final songsToAdd = allSongsFromAlbums.where((song) {
        //   return !newSongsList.any(
        //     (existingSong) => existingSong.id == song.id,
        //   );
        // }).toList();
        //
        // // Insert songs at the position after current playing song
        // newSongsList.insertAll(insertIndex, songsToAdd);
        //
        // // Update the playlist, keeping the current song playing
        // await musicService.setPlaylist(
        //   newSongsList,
        //   startIndex: currentIndex >= 0 ? currentIndex : 0,
        //   autoPlay: false,
        // );
      }

      if (mounted) {
        // showSnackBar(
        //   context,
        //   () {},
        //   message:
        //       "${allSongsFromAlbums.length} songs from ${selectedAlbums.length} albums added to play next",
        //   alertBannerLocation: AlertBannerLocation.bottom,
        // );
        // context.pop();
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding albums to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Add selected albums to queue
  void _addSelectedSongsToQueue() async {
    final selectedAlbums = _getSelectedAlbums(
      context.read<AlbumBloc>().state.maybeWhen(
        loaded: (albums, albumSongs) => albums,
        orElse: () => <Album>[],
      ),
    );

    if (selectedAlbums.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No albums selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final musicService = MusicPlayerService();
      final _repo = locator<AlbumRepository>();
      List<SongsModel> allSongsFromAlbums = [];

      // Fetch all songs from selected albums
      for (var album in selectedAlbums) {
        List<SongsModel> albumSongs = (await _repo.getSongsForAlbum(
          album.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in albumSongs) {
          if (!allSongsFromAlbums.any((s) => s.id == song.id)) {
            allSongsFromAlbums.add(song);
          }
        }
      }

      if (allSongsFromAlbums.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected albums contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final addedSong = await musicService.addMultipleSongsToQueue(
        allSongsFromAlbums,
      );

      if (mounted) {
        if (addedSong < 1) {
          showSnackBar(
            context,
            () {},
            message: "Songs already added to queue",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        } else {
          showSnackBar(
            context,
            () {},
            message: "$addedSong songs added to queue",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
      }

      // context.pop();

      // Create a copy of the existing songs list
      // final newSongsList = List<SongsModel>.from(musicService.songs);
      //
      // // Add each selected song to the queue if it's not already there
      // int addedCount = 0;
      // for (final song in allSongsFromAlbums) {
      //   final existingIndex = newSongsList.indexWhere(
      //     (existingSong) => existingSong.id == song.id,
      //   );
      //
      //   if (existingIndex == -1) {
      //     newSongsList.add(song);
      //     addedCount++;
      //   }
      // }
      //
      // // Update the playlist with the new songs list
      // await musicService.setPlaylist(newSongsList);
      //
      // if (mounted) {
      //
      //   if(addedCount < 1){
      //     showSnackBar(
      //       context,
      //           () {},
      //       message: "Songs already added to queue",
      //       alertBannerLocation: AlertBannerLocation.bottom,
      //     );
      //   }
      //   else{
      //     showSnackBar(
      //       context,
      //           () {},
      //       message:
      //       "$addedCount songs from ${selectedAlbums.length} albums added to queue",
      //       alertBannerLocation: AlertBannerLocation.bottom,
      //     );
      //   }
      // }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding albums to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Play selected albums
  void _playSelectedAlbums(List<Album> allAlbums) async {
    final selectedAlbums = _getSelectedAlbums(allAlbums);

    if (selectedAlbums.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No albums selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final musicService = MusicPlayerService();
      final _repo = locator<AlbumRepository>();
      List<SongsModel> allSongsFromAlbums = [];

      // Fetch all songs from selected albums
      for (var album in selectedAlbums) {
        List<SongsModel> albumSongs = (await _repo.getSongsForAlbum(
          album.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in albumSongs) {
          if (!allSongsFromAlbums.any((s) => s.id == song.id)) {
            allSongsFromAlbums.add(song);
          }
        }
      }

      if (allSongsFromAlbums.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected albums contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Set the combined playlist and start playing
      showSnackBar(
        context,
        () {},
        message:
            "Playing ${allSongsFromAlbums.length} songs from ${selectedAlbums.length} albums",
        alertBannerLocation: AlertBannerLocation.bottom,
      );

      // Navigate back
      // if (mounted) {
      //   context.pop();
      // }

      await musicService.setPlaylist(allSongsFromAlbums, startIndex: 0);
      await musicService.play();
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error playing albums: $e",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add songs from selected albums to playlist
  void _addSongsToSelectedAlbums(List<Album> allAlbums) async {
    final selectedAlbums = _getSelectedAlbums(allAlbums);

    if (selectedAlbums.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No albums selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final _repo = locator<AlbumRepository>();
      List<SongsModel> allSongsFromAlbums = [];

      // Fetch all songs from selected albums
      for (var album in selectedAlbums) {
        List<SongsModel> albumSongs = (await _repo.getSongsForAlbum(
          album.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in albumSongs) {
          if (!allSongsFromAlbums.any((s) => s.id == song.id)) {
            allSongsFromAlbums.add(song);
          }
        }
      }

      if (allSongsFromAlbums.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected albums contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Show playlist bottom sheet with all songs from selected albums
      if (mounted) {
        showCommonAddToPlaylistBottomSheet(
          context,
          songsList: allSongsFromAlbums,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error fetching songs from albums: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Build album section with header and items
  List<Widget> _buildAlbumSection(String title, List<Album> albums) {
    if (albums.isEmpty) return [];

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

      // Album items
      ...albums.map((album) {
        final isSelected = selectedAlbumIds.contains(album.id);
        final hasArtwork = album.artworkPath?.isNotEmpty ?? false;
        final albumArtworkPath = hasArtwork
            ? album.artworkPath!
            : Assets.svgAlbum;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: MusicListTile(
            margin: 7.w,
            height: 66.h,
            borderRadius: 10.r,
            backgroundColor: AppColors.musicTileBackgroundColor,
            cardHeight: 50.h,
            cardWidth: 50.h,
            cardRadius: 7.r,
            cardIconAsset: albumArtworkPath,
            cardIconSize: 32.r,
            isSvgCardIcon: !hasArtwork,
            isSvgColorNeeded: !hasArtwork,
            title: album.name,
            subtitle:
                '${album.songCount} Songs${album.artist != null ? " • ${album.artist}" : ""}',
            trailingIconAsset: isSelected
                ? Assets.svgIcCheck
                : Assets.svgIcUncheck,
            trailingIconHeight: 20.h,
            trailingIconWidth: 10.w,
            trailingMargin: 2.w,
            onTap: () => toggleSelection(album.id!, albums),
            onPlayTap: () => toggleSelection(album.id!, albums),
          ),
        );
      }).toList(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: 'Select Albums',
        isActionBtnDisplay: true,
        onTapAction: () => _showPopupMenu(context),
      ),
      body: BlocBuilder<AlbumBloc, AlbumState>(
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
            loaded: (allAlbums, albumSongs) {
              final filteredAlbums = _filterAlbums(allAlbums);

              // Update select all state based on current filtered results
              updateSelectAllState(filteredAlbums);

              if (allAlbums.isEmpty) {
                return const Center(
                  child: Text(
                    "No albums available",
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
                          hintText: 'Search Albums',
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
                  if (filteredAlbums.isEmpty && searchQuery.isNotEmpty)
                    Expanded(
                      child: Center(
                        child: Texts(
                          "No albums match your search",
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
                            onTap: () => toggleSelectAll(filteredAlbums),
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

                    // Albums list
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Albums Section
                            ..._buildAlbumSection(
                              'My Albums (${filteredAlbums.length})',
                              filteredAlbums,
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
      bottomNavigationBar: BlocBuilder<AlbumBloc, AlbumState>(
        builder: (context, state) {
          return state.maybeWhen(
            loaded: (allAlbums, albumSongs) {
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
                          onTap: () => _playSelectedAlbums(allAlbums),
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
                          onTap: () => _addSongsToSelectedAlbums(allAlbums),
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
                        // GestureDetector(
                        //   onTap: () => _deleteSelectedAlbums(allAlbums),
                        //   child: Column(
                        //     mainAxisSize: MainAxisSize.min,
                        //     children: [
                        //       SvgPicture.asset(Assets.svgIcNavDelete),
                        //       SizedBox(height: 3.h),
                        //       Texts(
                        //         S.of(context).delete,
                        //         fontSize: 12.sp,
                        //         fontFamily: AppFonts.inter,
                        //         fontWeight: FontWeight.w400,
                        //       ),
                        //     ],
                        //   ),
                        // ),
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
