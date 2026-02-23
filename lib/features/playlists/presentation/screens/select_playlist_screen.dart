import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/playlists/presentation/bloc/playlist_bloc.dart';
import 'package:music_app/features/playlists/domain/entities/playlist.dart'
    as domain;
import 'package:music_app/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';

import 'package:music_app/core/widgets/MusicListTile.dart';
import 'package:music_app/core/widgets/app_bar_with_icon_title.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/core/utils/globals.dart';
import 'package:music_app/core/utils/snack_bar.dart';
import 'package:music_app/core/widgets/common_modal_bottom_sheet.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_event.dart';
import 'package:go_router/go_router.dart';

class SelectPlaylistScreen extends StatefulWidget {
  const SelectPlaylistScreen({super.key});

  @override
  State<SelectPlaylistScreen> createState() => _SelectPlaylistScreenState();
}

class _SelectPlaylistScreenState extends State<SelectPlaylistScreen> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool isSelectedAll = false;
  Set<int> selectedPlaylistIds = {}; // Store selected playlist IDs
  String searchQuery = '';

  final List<String> systemOrder = [
    'most_played',
    'recently_added',
    'recently_played',
    'favorites',
  ];
  final Map<String, String> systemIcon = {
    'most_played': Assets.svgMostPlayed,
    'recently_added': Assets.svgRecentlyAdded,
    'recently_played': Assets.svgRecentlyAdded,
    'favorites': Assets.svgFavorites,
  };
  final Map<String, Color> systemColor = {
    'most_played': AppColors.mildOrange,
    'recently_added': AppColors.mildBlue,
    'recently_played': AppColors.mildYellow,
    'favorites': AppColors.mildPink,
  };

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim();
      });
    });

    // Load all playlists
    context.read<PlaylistBloc>().add(const PlaylistEvent.fetchAllPlaylists());
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  // Filter playlists based on search query
  List<domain.Playlist> _filterPlaylists(List<domain.Playlist> allPlaylists) {
    if (searchQuery.isEmpty) return allPlaylists;

    return allPlaylists.where((playlist) {
      return playlist.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  // int selectedPlaylistCount(List<domain.Playlist> filteredPlaylists) {
  //   return filteredPlaylists
  //       .where((song) => selectedPlaylistIds.contains(song.id))
  //       .length;
  // }

  // Get selected count
  int get selectedCount => selectedPlaylistIds.length;

  // Update select all state based on current filtered list
  void updateSelectAllState(List<domain.Playlist> filteredPlaylists) {
    if (filteredPlaylists.isEmpty) {
      isSelectedAll = false;
      return;
    }

    final allIds = filteredPlaylists.map((p) => p.id!).toSet();
    // Only show select all as checked if ALL playlists are selected
    isSelectedAll = allIds.every((id) => selectedPlaylistIds.contains(id));
  }

  // Toggle select all
  void toggleSelectAll(List<domain.Playlist> filteredPlaylists) {
    setState(() {
      if (isSelectedAll) {
        // Deselect all from current filtered list
        final filteredIds = filteredPlaylists.map((p) => p.id!).toSet();
        selectedPlaylistIds.removeAll(filteredIds);
      } else {
        // Select all from current filtered list
        selectedPlaylistIds.addAll(filteredPlaylists.map((p) => p.id!));
      }
      updateSelectAllState(filteredPlaylists);
    });
  }

  // Toggle individual selection
  void toggleSelection(
    int playlistId,
    List<domain.Playlist> filteredPlaylists, {
    bool isSystemPlaylist = false,
  }) {
    setState(() {
      if (selectedPlaylistIds.contains(playlistId)) {
        selectedPlaylistIds.remove(playlistId);
      } else {
        selectedPlaylistIds.add(playlistId);
      }
      updateSelectAllState(filteredPlaylists);
    });
  }

  // Get selected playlists from IDs
  List<domain.Playlist> _getSelectedPlaylists(
    List<domain.Playlist> allPlaylists,
  ) {
    return allPlaylists
        .where((playlist) => selectedPlaylistIds.contains(playlist.id))
        .toList();
  }

  // Delete selected playlists
  void _deleteSelectedPlaylists(List<domain.Playlist> allPlaylists) {
    final selectedPlaylists = _getSelectedPlaylists(allPlaylists);

    if (selectedPlaylists.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No playlists selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    // Filter out system playlists from deletion
    final deletablePlaylists = selectedPlaylists
        .where((playlist) => playlist.isSystem != true)
        .toList();

    if (deletablePlaylists.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "System playlists cannot be deleted",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    final playlistCount = deletablePlaylists.length;
    showCommonConfirmationBottomSheet(
      context: context,
      title: S.of(context).deletePlaylist,
      message:
          'Are you sure you want to delete ${playlistCount == 1 ? 'this playlist' : 'these $playlistCount playlists'}?',
      onConfirm: (sheetContext) async {
        Navigator.pop(sheetContext);
        for (var playlist in deletablePlaylists) {
          context.read<PlaylistBloc>().add(
            PlaylistEvent.deletePlaylist(playlist.id!),
          );
        }
        setState(() {
          selectedPlaylistIds.clear();
          isSelectedAll = false;
        });
        showSnackBar(
          context,
          () {},
          message:
              "$playlistCount ${playlistCount == 1 ? 'playlist' : 'playlists'} deleted successfully!",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      },
    );
  }

  // Show popup menu for playlist actions
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

  // Play next selected playlists
  void _playNextSelectedSongs() async {
    final selectedPlaylists = _getSelectedPlaylists(
      context.read<PlaylistBloc>().state.maybeWhen(
        loaded: (playlists, systemPlaylistSongs) => playlists,
        orElse: () => <domain.Playlist>[],
      ),
    );

    if (selectedPlaylists.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No playlists selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final bloc = context.read<MusicPlayerBloc>();
      final _repo = locator<PlaylistRepository>();
      List<SongsModel> allSongsFromPlaylists = [];

      // Fetch all songs from selected playlists
      for (var playlist in selectedPlaylists) {
        List<SongsModel> playlistSongs = [];

        if (playlist.isSystem == true) {
          playlistSongs = await _repo.getSongsForSystemPlaylist(
            playlist.systemKey ?? '',
          );
        } else {
          playlistSongs = await _repo.getSongsForPlaylist(playlist.id!);
        }

        // Add songs to the combined list, avoiding duplicates
        for (var song in playlistSongs) {
          if (!allSongsFromPlaylists.any((s) => s.id == song.id)) {
            allSongsFromPlaylists.add(song);
          }
        }
      }

      if (allSongsFromPlaylists.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected playlists contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Check if there are existing songs in the queue
      if (bloc.state.songs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "${allSongsFromPlaylists.length} songs added to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        bloc.add(SetPlaylistEvent(allSongsFromPlaylists.map((m) => m.toDomain()).toList(), startIndex: 0));
        bloc.add(const PlayEvent());
      } else {
        bloc.add(PlayNextMultipleSongsEvent(allSongsFromPlaylists.map((m) => m.toDomain()).toList()));
        if (mounted) {
          showSnackBar(
            context,
            () {},
            message: "${allSongsFromPlaylists.length} songs added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
      }

      if (mounted) {
        // showSnackBar(
        //   context,
        //   () {},
        //   message:
        //       "${allSongsFromPlaylists.length} songs from ${selectedPlaylists.length} playlists added to play next",
        //   alertBannerLocation: AlertBannerLocation.bottom,
        // );
        // context.pop();
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding playlists to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Add selected playlists to queue
  void _addSelectedSongsToQueue() async {
    final selectedPlaylists = _getSelectedPlaylists(
      context.read<PlaylistBloc>().state.maybeWhen(
        loaded: (playlists, systemPlaylistSongs) => playlists,
        orElse: () => <domain.Playlist>[],
      ),
    );

    if (selectedPlaylists.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No playlists selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final bloc = context.read<MusicPlayerBloc>();
      final _repo = locator<PlaylistRepository>();
      List<SongsModel> allSongsFromPlaylists = [];

      // Fetch all songs from selected playlists
      for (var playlist in selectedPlaylists) {
        List<SongsModel> playlistSongs = [];

        if (playlist.isSystem == true) {
          playlistSongs = await _repo.getSongsForSystemPlaylist(
            playlist.systemKey ?? '',
          );
        } else {
          playlistSongs = await _repo.getSongsForPlaylist(playlist.id!);
        }

        // Add songs to the combined list, avoiding duplicates
        for (var song in playlistSongs) {
          if (!allSongsFromPlaylists.any((s) => s.id == song.id)) {
            allSongsFromPlaylists.add(song);
          }
        }
      }

      if (allSongsFromPlaylists.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected playlists contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      bloc.add(AddMultipleSongsToQueueEvent(allSongsFromPlaylists.map((m) => m.toDomain()).toList()));

      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "${allSongsFromPlaylists.length} songs from ${selectedPlaylists.length} playlists added to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }

      // context.pop();

      // // Create a copy of the existing songs list
      // final newSongsList = List<SongsModel>.from(musicService.songs);
      //
      // // Add each selected song to the queue if it's not already there
      // int addedCount = 0;
      // for (final song in allSongsFromPlaylists) {
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
      //       "$addedCount songs from ${selectedPlaylists.length} playlists added to queue",
      //       alertBannerLocation: AlertBannerLocation.bottom,
      //     );
      //   }
      // }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding playlists to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Play selected playlists
  void _playSelectedPlaylists(List<domain.Playlist> allPlaylists) async {
    final selectedPlaylists = _getSelectedPlaylists(allPlaylists);

    if (selectedPlaylists.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No playlists selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final bloc = context.read<MusicPlayerBloc>();
      final _repo = locator<PlaylistRepository>();
      List<SongsModel> allSongsFromPlaylists = [];

      // Fetch all songs from selected playlists
      for (var playlist in selectedPlaylists) {
        List<SongsModel> playlistSongs = [];

        if (playlist.isSystem == true) {
          // Fetch songs for system playlist
          playlistSongs = await _repo.getSongsForSystemPlaylist(
            playlist.systemKey ?? '',
          );
        } else {
          // Fetch songs for user playlist
          playlistSongs = await _repo.getSongsForPlaylist(playlist.id!);
        }

        // Add songs to the combined list, avoiding duplicates
        for (var song in playlistSongs) {
          if (!allSongsFromPlaylists.any((s) => s.id == song.id)) {
            allSongsFromPlaylists.add(song);
          }
        }
      }

      if (allSongsFromPlaylists.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected playlists contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Set the combined playlist and start playing
      // context.pop();
      showSnackBar(
        context,
        () {},
        message:
            "Playing ${allSongsFromPlaylists.length} songs from ${selectedPlaylists.length} playlists",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      bloc.add(SetPlaylistEvent(allSongsFromPlaylists.map((m) => m.toDomain()).toList(), startIndex: 0));
      bloc.add(const PlayEvent());
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error playing playlists: $e",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add songs to selected playlists
  void _addSongsToSelectedPlaylists(List<domain.Playlist> allPlaylists) async {
    final selectedPlaylists = _getSelectedPlaylists(allPlaylists);

    if (selectedPlaylists.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No playlists selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final _repo = locator<PlaylistRepository>();
      List<SongsModel> allSongsFromPlaylists = [];

      // Fetch all songs from selected playlists
      for (var playlist in selectedPlaylists) {
        List<SongsModel> playlistSongs = [];

        if (playlist.isSystem == true) {
          playlistSongs = await _repo.getSongsForSystemPlaylist(
            playlist.systemKey ?? '',
          );
        } else {
          playlistSongs = await _repo.getSongsForPlaylist(playlist.id!);
        }

        // Add songs to the combined list, avoiding duplicates
        for (var song in playlistSongs) {
          if (!allSongsFromPlaylists.any((s) => s.id == song.id)) {
            allSongsFromPlaylists.add(song);
          }
        }
      }

      if (allSongsFromPlaylists.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected playlists contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Show playlist bottom sheet with all songs from selected playlists
      if (mounted) {
        showCommonAddToPlaylistBottomSheet(
          context,
          songsList: allSongsFromPlaylists,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error fetching songs from playlists: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Build playlist section with header and items
  List<Widget> _buildPlaylistSection(
    String title,
    List<domain.Playlist> playlists,
  ) {
    if (playlists.isEmpty) return [];

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

      // Playlist items
      ...playlists.map((playlist) {
        final isSystem = playlist.isSystem == true;
        final isSelected = selectedPlaylistIds.contains(playlist.id);
        final hasCover = playlist.coverPath?.isNotEmpty ?? false;

        // Get icon and color for system playlists
        final icon = hasCover
            ? playlist.coverPath!
            : isSystem && playlist.systemKey != null
            ? (systemIcon[playlist.systemKey] ?? Assets.svgMusicIcon)
            : Assets.svgMusicIcon;
        final color = !hasCover && isSystem && playlist.systemKey != null
            ? (systemColor[playlist.systemKey] ?? AppColors.mildBlue)
            : null;
        final isSvgIcon = !hasCover && icon.contains('.svg');

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
            cardIconAsset: icon,
            cardIconSize: 32.r,
            isSvgCardIcon: isSvgIcon,
            isSvgColorNeeded: isSvgIcon,
            title: playlist.name,
            subtitle: '${playlist.songCount} Songs',
            noLogoGradientColor: color != null
                ? [color.withValues(alpha: 0.21), color]
                : null,
            trailingIconAsset: isSelected
                ? Assets.svgIcCheck
                : Assets.svgIcUncheck,
            trailingIconHeight: 20.h,
            trailingIconWidth: 10.w,
            trailingMargin: 2.w,
            onTap: () => toggleSelection(
              playlist.id!,
              playlists,
              isSystemPlaylist: isSystem,
            ),
            onPlayTap: () => toggleSelection(
              playlist.id!,
              playlists,
              isSystemPlaylist: isSystem,
            ),
          ),
        );
      }).toList(),
    ];
  }

  // Custom delete confirmation dialog matching the design
  Widget _buildDeleteConfirmationDialog(
    int playlistCount,
    List<domain.Playlist> deletablePlaylists,
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
            S.of(context).deletePlaylist,
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          SizedBox(height: 30.h),

          // Message
          Texts(
            'Are you sure you want to delete ${playlistCount == 1 ? 'this playlist' : 'these $playlistCount playlists'}?',
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
                    // Delete all deletable playlists
                    for (var playlist in deletablePlaylists) {
                      context.read<PlaylistBloc>().add(
                        PlaylistEvent.deletePlaylist(playlist.id!),
                      );
                    }

                    Navigator.pop(context);
                    setState(() {
                      selectedPlaylistIds.clear();
                      isSelectedAll = false;
                    });

                    showSnackBar(
                      context,
                      () {},
                      message:
                          "$playlistCount ${playlistCount == 1 ? 'playlist' : 'playlists'} deleted successfully!",
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
        title: 'Select Playlists',
        isActionBtnDisplay: true,
        onTapAction: () => _showPopupMenu(context),
      ),
      body: BlocBuilder<PlaylistBloc, PlaylistState>(
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
            loaded: (allPlaylists, systemPlaylistSongs) {
              final filteredPlaylists = _filterPlaylists(allPlaylists);

              // Update select all state based on current filtered results
              updateSelectAllState(filteredPlaylists);

              if (allPlaylists.isEmpty) {
                return const Center(
                  child: Text(
                    "No playlists available",
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
                          hintText: 'Search Playlists',
                          hintStyle: TextStyle(
                              color: AppColors.textColor.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFonts.inter,
                              fontSize: 15.sp
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
                  if (filteredPlaylists.isEmpty && searchQuery.isNotEmpty)
                    Expanded(
                      child: Center(
                        child: Texts(
                          "No playlists match your search",
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
                              "${selectedItemsCount(filteredPlaylists, selectedPlaylistIds) != 0 ? "${selectedItemsCount(filteredPlaylists, selectedPlaylistIds)} ${S.of(context).selected}" : ''} ",
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
                            onTap: () => toggleSelectAll(filteredPlaylists),
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

                    // Playlists list
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // System Playlists Section
                            ..._buildPlaylistSection(
                              'System Playlists',
                              filteredPlaylists
                                  .where((p) => p.isSystem == true)
                                  .toList(),
                            ),

                            // User Playlists Section
                            if (filteredPlaylists.any(
                              (p) => p.isSystem != true,
                            )) ...[
                              SizedBox(height: 20.h),
                              ..._buildPlaylistSection(
                                'My Playlists (${filteredPlaylists.where((p) => p.isSystem != true).length})',
                                filteredPlaylists
                                    .where((p) => p.isSystem != true)
                                    .toList(),
                              ),
                            ],
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
      bottomNavigationBar: BlocBuilder<PlaylistBloc, PlaylistState>(
        builder: (context, state) {
          return state.maybeWhen(
            loaded: (allPlaylists, systemPlaylistSongs) {
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
                          onTap: () => _playSelectedPlaylists(allPlaylists),
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
                          onTap: () =>
                              _addSongsToSelectedPlaylists(allPlaylists),
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
                          onTap: () => _deleteSelectedPlaylists(allPlaylists),
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
