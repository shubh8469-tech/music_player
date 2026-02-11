import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/artists/bloc/artist_bloc.dart';
import 'package:music_app/features/artists/domain/entities/artist.dart';
import 'package:music_app/features/artists/domain/repositories/artist_repository.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/app_bar_with_icon_title.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../themes/color.dart';
import '../../../../utills/globals.dart';
import '../../../../utills/snack_bar.dart';
import '../../music_service.dart';
import 'package:go_router/go_router.dart';
import '../../../../commonWidgets/common_modal_bottom_sheet.dart';

class SelectArtistScreen extends StatefulWidget {
  const SelectArtistScreen({super.key});

  @override
  State<SelectArtistScreen> createState() => _SelectArtistScreenState();
}

class _SelectArtistScreenState extends State<SelectArtistScreen> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool isSelectedAll = false;
  Set<int> selectedArtistIds = {}; // Store selected artist IDs
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim();
      });
    });

    // Load all artists
    context.read<ArtistBloc>().add(const ArtistEvent.fetchAllArtists());
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  // Filter artists based on search query
  List<Artist> _filterArtists(List<Artist> allArtists) {
    if (searchQuery.isEmpty) return allArtists;

    return allArtists.where((artist) {
      return artist.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  // Get selected count
  int get selectedCount => selectedArtistIds.length;

  // Update select all state based on current filtered list
  void updateSelectAllState(List<Artist> filteredArtists) {
    if (filteredArtists.isEmpty) {
      isSelectedAll = false;
      return;
    }

    final allIds = filteredArtists.map((a) => a.id!).toSet();
    // Only show select all as checked if ALL artists are selected
    isSelectedAll = allIds.every((id) => selectedArtistIds.contains(id));
  }

  // Toggle select all
  void toggleSelectAll(List<Artist> filteredArtists) {
    setState(() {
      if (isSelectedAll) {
        // Deselect all from current filtered list
        final filteredIds = filteredArtists.map((a) => a.id!).toSet();
        selectedArtistIds.removeAll(filteredIds);
      } else {
        // Select all from current filtered list
        selectedArtistIds.addAll(filteredArtists.map((a) => a.id!));
      }
      updateSelectAllState(filteredArtists);
    });
  }

  // Toggle individual selection
  void toggleSelection(int artistId, List<Artist> filteredArtists) {
    setState(() {
      if (selectedArtistIds.contains(artistId)) {
        selectedArtistIds.remove(artistId);
      } else {
        selectedArtistIds.add(artistId);
      }
      updateSelectAllState(filteredArtists);
    });
  }

  // Get selected artists from IDs
  List<Artist> _getSelectedArtists(List<Artist> allArtists) {
    return allArtists
        .where((artist) => selectedArtistIds.contains(artist.id))
        .toList();
  }

  // Delete selected artists
  void _deleteSelectedArtists(List<Artist> allArtists) {
    final selectedArtists = _getSelectedArtists(allArtists);

    if (selectedArtists.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No artists selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    final artistCount = selectedArtists.length;
    showCommonConfirmationBottomSheet(
      context: context,
      title: 'Delete Artists',
      message:
          'Are you sure you want to delete ${artistCount == 1 ? 'this artist' : 'these $artistCount artists'}?',
      onConfirm: (sheetContext) async {
        Navigator.pop(sheetContext);
        setState(() {
          selectedArtistIds.clear();
          isSelectedAll = false;
        });
        showSnackBar(
          context,
          () {},
          message:
              "$artistCount ${artistCount == 1 ? 'artist' : 'artists'} deleted successfully!",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      },
    );
  }

  // Show popup menu for artist actions
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

  // Play next selected artists
  void _playNextSelectedSongs() async {
    final selectedArtists = _getSelectedArtists(
      context.read<ArtistBloc>().state.maybeWhen(
        loaded: (artists, _) => artists,
        orElse: () => <Artist>[],
      ),
    );

    if (selectedArtists.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No artists selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final musicService = MusicPlayerService();
      final _repo = locator<ArtistRepository>();
      List<SongsModel> allSongsFromArtists = [];

      // Fetch all songs from selected artists
      for (var artist in selectedArtists) {
        List<SongsModel> artistSongs = (await _repo.getSongsForArtist(
          artist.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in artistSongs) {
          if (!allSongsFromArtists.any((s) => s.id == song.id)) {
            allSongsFromArtists.add(song);
          }
        }
      }

      if (allSongsFromArtists.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected artists contain no songs",
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
          message: "${allSongsFromArtists.length} songs added to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );

        await musicService.setPlaylist(allSongsFromArtists, startIndex: 0);
        await musicService.play();
      } else {
        final updateCount = await musicService.playNextMultipleSongs(
          allSongsFromArtists,
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
        // final songsToAdd = allSongsFromArtists.where((song) {
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

      // if (mounted) {
      //   context.pop();
      // }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding artists to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Add selected artists to queue
  void _addSelectedSongsToQueue() async {
    final selectedArtists = _getSelectedArtists(
      context.read<ArtistBloc>().state.maybeWhen(
        loaded: (artists, _) => artists,
        orElse: () => <Artist>[],
      ),
    );

    if (selectedArtists.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No artists selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final musicService = MusicPlayerService();
      final _repo = locator<ArtistRepository>();
      List<SongsModel> allSongsFromArtists = [];

      // Fetch all songs from selected artists
      for (var artist in selectedArtists) {
        List<SongsModel> artistSongs = (await _repo.getSongsForArtist(
          artist.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in artistSongs) {
          if (!allSongsFromArtists.any((s) => s.id == song.id)) {
            allSongsFromArtists.add(song);
          }
        }
      }

      if (allSongsFromArtists.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected artists contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final addedSong = await musicService.addMultipleSongsToQueue(
        allSongsFromArtists,
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
      // for (final song in allSongsFromArtists) {
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
      //       "$addedCount songs from ${selectedArtists.length} artists added to queue",
      //       alertBannerLocation: AlertBannerLocation.bottom,
      //     );
      //   }
      //
      // }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding artists to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Play selected artists
  void _playSelectedArtists(List<Artist> allArtists) async {
    final selectedArtists = _getSelectedArtists(allArtists);

    if (selectedArtists.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No artists selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final musicService = MusicPlayerService();
      final _repo = locator<ArtistRepository>();
      List<SongsModel> allSongsFromArtists = [];

      // Fetch all songs from selected artists
      for (var artist in selectedArtists) {
        List<SongsModel> artistSongs = (await _repo.getSongsForArtist(
          artist.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in artistSongs) {
          if (!allSongsFromArtists.any((s) => s.id == song.id)) {
            allSongsFromArtists.add(song);
          }
        }
      }

      if (allSongsFromArtists.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected artists contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      showSnackBar(
        context,
        () {},
        message:
            "Playing ${allSongsFromArtists.length} songs from ${selectedArtists.length} artists",
        alertBannerLocation: AlertBannerLocation.bottom,
      );

      // Navigate back
      // if (mounted) {
      //   context.pop();
      // }

      // Set the combined playlist and start playing
      await musicService.setPlaylist(allSongsFromArtists, startIndex: 0);
      await musicService.play();
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error playing artists: $e",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add songs from selected artists to playlist
  void _addSongsToSelectedArtists(List<Artist> allArtists) async {
    final selectedArtists = _getSelectedArtists(allArtists);

    if (selectedArtists.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No artists selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final _repo = locator<ArtistRepository>();
      List<SongsModel> allSongsFromArtists = [];

      // Fetch all songs from selected artists
      for (var artist in selectedArtists) {
        List<SongsModel> artistSongs = (await _repo.getSongsForArtist(
          artist.id!,
        )).cast<SongsModel>();

        // Add songs to the combined list, avoiding duplicates
        for (var song in artistSongs) {
          if (!allSongsFromArtists.any((s) => s.id == song.id)) {
            allSongsFromArtists.add(song);
          }
        }
      }

      if (allSongsFromArtists.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected artists contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Show playlist bottom sheet with all songs from selected artists
      if (mounted) {
        showCommonAddToPlaylistBottomSheet(
          context,
          songsList: allSongsFromArtists,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error fetching songs from artists: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Build artist section with header and items
  List<Widget> _buildArtistSection(String title, List<Artist> artists) {
    if (artists.isEmpty) return [];

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

      // Artist items
      ...artists.map((artist) {
        final isSelected = selectedArtistIds.contains(artist.id);
        final hasArtwork = artist.artworkPath?.isNotEmpty ?? false;
        final artistArtworkPath = hasArtwork
            ? artist.artworkPath!
            : Assets.svgMusicIcon;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: MusicListTile(
            margin: 7.w,
            height: 66.h,
            borderRadius: 10.r,
            backgroundColor: AppColors.musicTileBackgroundColor,
            cardHeight: 50.h,
            cardWidth: 50.h,
            cardRadius: 100.r,
            cardIconAsset: artistArtworkPath,
            cardIconSize: 32.r,
            isSvgCardIcon: !hasArtwork,
            isSvgColorNeeded: false,
            title: artist.name,
            subtitle:
                '${artist.albumCount} Album${artist.albumCount != 1 ? 's' : ''} - ${artist.songCount} Songs',
            trailingIconAsset: isSelected
                ? Assets.svgIcCheck
                : Assets.svgIcUncheck,
            trailingIconHeight: 20.h,
            trailingIconWidth: 10.w,
            trailingMargin: 2.w,
            onTap: () => toggleSelection(artist.id!, artists),
            onPlayTap: () => toggleSelection(artist.id!, artists),
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
        title: 'Select Artists',
        isActionBtnDisplay: true,
        onTapAction: () => _showPopupMenu(context),
      ),
      body: BlocBuilder<ArtistBloc, ArtistState>(
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
            loaded: (allArtists, _) {
              final filteredArtists = _filterArtists(allArtists);

              // Update select all state based on current filtered results
              updateSelectAllState(filteredArtists);

              if (allArtists.isEmpty) {
                return const Center(
                  child: Text(
                    "No artists available",
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
                          hintText: 'Search Artists',
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
                  if (filteredArtists.isEmpty && searchQuery.isNotEmpty)
                    Expanded(
                      child: Center(
                        child: Texts(
                          "No artists match your search",
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
                              "${selectedItemsCount(filteredArtists, selectedArtistIds) != 0 ? "${selectedItemsCount(filteredArtists, selectedArtistIds)} ${S.of(context).selected}" : ''} ",
                              // selectedCount != 0
                              //     ? "$selectedCount ${S.of(context).selected}"
                              //     : "",
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
                            onTap: () => toggleSelectAll(filteredArtists),
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

                    // Artists list
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Artists Section
                            ..._buildArtistSection(
                              'My Artists (${filteredArtists.length})',
                              filteredArtists,
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
      bottomNavigationBar: BlocBuilder<ArtistBloc, ArtistState>(
        builder: (context, state) {
          return state.maybeWhen(
            loaded: (allArtists, _) {
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
                          onTap: () => _playSelectedArtists(allArtists),
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
                          onTap: () => _addSongsToSelectedArtists(allArtists),
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
                        //   onTap: () => _deleteSelectedArtists(allArtists),
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
