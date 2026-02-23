import 'dart:developer';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/features/songs/presentation/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/features/playlists/presentation/bloc/playlist_bloc.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/core/widgets/MusicListTile.dart';
import 'package:music_app/core/widgets/app_bar_with_icon_title.dart';
import 'package:music_app/core/widgets/common_functions.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/core/utils/globals.dart';
import 'package:music_app/core/utils/snack_bar.dart';
import 'package:music_app/core/widgets/common_modal_bottom_sheet.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_event.dart';

class SelectSongScreen extends StatefulWidget {
  final dynamic playlist;
  final dynamic album;
  final dynamic artist;
  final dynamic genre;
  final dynamic folder;
  final List<SongsModel>? playlistSongs;
  final bool? isSystemPlaylist;

  const SelectSongScreen({
    super.key,
    this.playlist,
    this.album,
    this.artist,
    this.genre,
    this.folder,
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
  Set<int> searchSelectedIds = {}; // Store selected song IDs
  String searchQuery = '';
  MusicPlayerBloc get _bloc => context.read<MusicPlayerBloc>();
  List<SongsModel>? _playlistSongs;

  List<String> musicIcons = [
    Assets.pngBand2,
    Assets.svgMusicIcon,
    Assets.pngBand,
  ];

  @override
  void initState() {
    super.initState();
     _playlistSongs = widget.playlistSongs != null
         ? List<SongsModel>.from(widget.playlistSongs!)
         : null;
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
    log('Filtering songs with query: $searchQuery');

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
      showSnackBar(
        context,
        () {},
        message: "Playing ${selectedSongs.length} songs",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      // context.pop();
      _bloc.add(SetPlaylistEvent(selectedSongs.map((m) => m.toDomain()).toList(), startIndex: 0));
      _bloc.add(const PlayEvent());
      // Navigate back or stay, depending on your preference
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

    final songCount = selectedSongs.length;
    // If we're in playlist context, remove from playlist instead of deleting completely
    if (widget.playlist != null) {
      showCommonConfirmationBottomSheet(
        context: context,
        title: 'Remove from Playlist',
        message:
            'Are you sure you want to remove these $songCount songs from the playlist?',
        confirmButtonText: 'Remove',
        onConfirm: (sheetContext) async {
          Navigator.pop(sheetContext);
          _performRemoveFromPlaylist(allSongs, songCount);
        },
      );
    } else if (widget.album != null ||
        widget.artist != null ||
        widget.folder != null ||
        widget.genre != null) {
      final entityType = widget.album != null
          ? 'album'
          : widget.artist != null
          ? 'artist'
          : widget.folder != null
          ? 'folder'
          : 'genre';
      final entityName = widget.album != null
          ? widget.album.name
          : widget.artist != null
          ? widget.artist.name
          : widget.folder != null
          ? widget.folder.name
          : widget.genre.name;
      showCommonConfirmationBottomSheet(
        context: context,
        title: 'Delete Songs',
        message:
            'Are you sure you want to delete these $songCount songs from the $entityType "$entityName"? This will remove them from your library.',
        onConfirm: (sheetContext) async {
          Navigator.pop(sheetContext);
          await _performDeleteFromEntity(allSongs, songCount);
        },
      );
    } else {
      showCommonConfirmationBottomSheet(
        context: context,
        title: 'Delete Song',
        message: 'Are you sure you want to delete these $songCount songs?',
        onConfirm: (sheetContext) async {
          Navigator.pop(sheetContext);
          await _performDeleteSongs(allSongs, songCount);
        },
      );
    }
  }

  void _performRemoveFromPlaylist(List<SongsModel> allSongs, int songCount) {
    final selectedSongs = _getSelectedSongs(allSongs);
    final songIds = selectedSongs.map((song) => song.id!).toList();
    int? playlistId;
    if (widget.playlist != null) {
      if (widget.isSystemPlaylist == true) {
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
        PlaylistEvent.removeMultipleSongsFromPlaylist(playlistId, songIds),
      );
    }
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
  }

  Future<void> _performDeleteFromEntity(
    List<SongsModel> allSongs,
    int songCount,
  ) async {
    final selectedSongs = _getSelectedSongs(allSongs);
    for (var song in selectedSongs) {
      bool hasPermission = await _checkAndRequestPermission();
      if (!hasPermission) {
        showSnackBar(
          context,
          () {},
          message: 'Storage permission denied',
          backgroundColor: Colors.red,
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }
      final file = File(song.filePath);
      if (await file.exists()) {
        await file.delete();
        log('File deleted: ${song.filePath}');
      }
      context.read<SongsBloc>().add(SongsEvent.removeSong(song.id!));
      final currentSongs = List<SongsModel>.from(_bloc.state.songs);
      currentSongs.removeWhere((element) => element.id == song.id);
      if (currentSongs.isNotEmpty) {
        _bloc.add(RemoveDeletedSongFromQueueEvent(song.id!));
      } else {
        _bloc.add(ResetPlaylistEvent(currentSongs.map((m) => m.toDomain()).toList()));
      }
    }
    setState(() {
      selectedSongIds.clear();
      isSelectedAll = false;
    });
    Navigator.pop(context);
    showSnackBar(
      context,
      () {},
      message: "$songCount songs deleted successfully!",
      alertBannerLocation: AlertBannerLocation.bottom,
    );
  }

  Future<void> _performDeleteSongs(
    List<SongsModel> allSongs,
    int songCount,
  ) async {
    final selectedSongs = _getSelectedSongs(allSongs);
    for (var song in selectedSongs) {
      bool hasPermission = await _checkAndRequestPermission();
      if (!hasPermission) {
        showSnackBar(
          context,
          () {},
          message: 'Storage permission denied',
          backgroundColor: Colors.red,
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }
      final file = File(song.filePath);
      if (await file.exists()) {
        await file.delete();
        log('File deleted: ${song.filePath}');
      }
      context.read<SongsBloc>().add(SongsEvent.removeSong(song.id!));
      final currentSongs = List<SongsModel>.from(_bloc.state.songs);
      currentSongs.removeWhere((element) => element.id == song.id);
      if (currentSongs.isNotEmpty) {
        _bloc.add(RemoveDeletedSongFromQueueEvent(song.id!));
      } else {
        _bloc.add(ResetPlaylistEvent(currentSongs.map((m) => m.toDomain()).toList()));
      }
    }
    setState(() {
      selectedSongIds.clear();
      isSelectedAll = false;
    });
    Navigator.pop(context);
    showSnackBar(
      context,
      () {},
      message: "$songCount songs deleted successfully!",
      alertBannerLocation: AlertBannerLocation.bottom,
    );
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

    showCommonAddToPlaylistBottomSheet(context, songsList: selectedSongs);
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
      if (_bloc.state.songs.isEmpty) {
        // No songs in queue - add all selected songs and start playing
        if (mounted) {
          showSnackBar(
            context,
            () {},
            message: "${selectedSongs.length} songs added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }

        // if (Navigator.canPop(context)) {
        //   Navigator.pop(context, true);
        // }
        _bloc.add(SetPlaylistEvent(
          selectedSongs.map((m) => m.toDomain()).toList(),
          startIndex: 0,
          autoPlay: true,
        ));
        // await musicService.play();
      } else {
        _bloc.add(PlayNextMultipleSongsEvent(selectedSongs.map((m) => m.toDomain()).toList()));

        if (mounted) {
          showSnackBar(
            context,
            () {},
            message: "${selectedSongs.length} songs added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }

        // if (Navigator.canPop(context)) {
        //   Navigator.pop(context, true);
        // }
      }

      // if (mounted) {
      // showSnackBar(context, () {}, message: "${selectedSongs.length} songs added to play next", alertBannerLocation: AlertBannerLocation.bottom);
      // context.pop();
      // }
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

    _bloc.add(AddMultipleSongsToQueueEvent(selectedSongs.map((m) => m.toDomain()).toList()));

    if (mounted) {
      showSnackBar(
        context,
        () {},
        message: "${selectedSongs.length} songs added to queue",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }

    // if (Navigator.canPop(context)) {
    //   Navigator.pop(context, true);
    // }
  }

  // Hide selected songs
  Future<void> _hideSelectedSongs() async {
    final selectedSongs = _getSelectedSongs(
      _playlistSongs ??
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

    for (final song in selectedSongs) {
      if (song.id == null) {
      } else {
        try {
          context.read<SongsBloc>().add(SongsEvent.hideSong(song.id!));
          // await musicService.removeDeletedSongFromQueue(song.id!);
        } catch (e) {
          showSnackBar(
            context,
            () {},
            message: 'Failed to hide song: $e',
            backgroundColor: Colors.red,
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
      }
    }

    setState(() {
      selectedSongIds.removeWhere(
        (id) => selectedSongs.any((song) => song.id == id),
      );
      if (_playlistSongs != null) {
        final selectedIds = selectedSongs
            .where((song) => song.id != null)
            .map((song) => song.id!)
            .toSet();
        _playlistSongs!.removeWhere((song) => selectedIds.contains(song.id));
      }
      updateSelectAllState(
        _playlistSongs ??
            context.read<SongsBloc>().state.maybeWhen(
              loaded: (songs) => songs,
              orElse: () => <SongsModel>[],
            ),
      );
    });

    _bloc.add(RemoveDeletedSongsFromQueueEvent(
      selectedSongs.map((song) => song.id!).toSet(),
    ));

    if (mounted) {
      showSnackBar(
        context,
        () {},
        message: '${selectedSongs.length} songs hidden',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }

    // if (anyHidden && Navigator.canPop(context)) {
    //   Navigator.pop(context, true);
    // }
  }

  // Helper method to build content for playlist songs
  Widget _buildPlaylistSongsContent() {
    final filteredSongs = _filterSongs(_playlistSongs!);
    updateSelectAllState(filteredSongs);

    if (_playlistSongs!.isEmpty) {
      return const Center(
        child: Text(
          "No songs in this playlist",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return _buildSongsContent(_playlistSongs!, filteredSongs);
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
                  color: AppColors.textColor.withValues(alpha: 0.40),
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
        if (filteredSongs.isEmpty && searchQuery.isNotEmpty)
          Expanded(
            child: Center(
              child: Texts(
                "No songs match your search",
                fontSize: 16.sp,
                color: AppColors.textColor,
              ),
            ),
          )
        else ...[
          // Selected count and Select All
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
            child: Row(
              children: [
                Expanded(
                  child: Texts(
                    "${selectedItemsCount(filteredSongs, selectedSongIds) != 0 ? "${selectedItemsCount(filteredSongs, selectedSongIds)} ${S.of(context).selected}" : ''} ",
                    // selectedCount != 0 ? "$selectedCount ${S.of(context).selected}" : "",
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
                  onTap: () => toggleSelectAll(filteredSongs),
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: S.of(context).selectSongs,
        isActionBtnDisplay: true,
        onTapAction: () => _showPopupMenu(context),
      ),
      body: _playlistSongs != null
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
                    log('loaded again: ${allSongs.length} songs');
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
      bottomNavigationBar: _playlistSongs != null
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
                onTap: () => _playSelectedSongs(_playlistSongs!),
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
                onTap: () => _addToPlaylist(_playlistSongs!),
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
                onTap: () => _deleteSelectedSongs(_playlistSongs!),
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

  Future<bool> _checkAndRequestPermission() async {
    if (Platform.isAndroid) {
      // Check if we have manage external storage permission (Android 11+)
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // Request manage external storage permission
      PermissionStatus status = await Permission.manageExternalStorage
          .request();
      if (status.isGranted) {
        return true;
      }

      // Fallback to storage permission (for older Android versions)
      if (await Permission.storage.isGranted) {
        return true;
      }

      status = await Permission.storage.request();
      return status.isGranted;
    }

    // For iOS and other platforms
    return true;
  }
}
