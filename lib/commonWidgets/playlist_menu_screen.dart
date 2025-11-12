import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';
import '../app_router.dart';
import '../core/di/injection.dart';
import '../features/playlists/bloc/playlist_bloc.dart';
import '../features/playlists/domain/entities/playlist.dart' as domain;
import '../features/playlists/domain/repositories/playlist_repository.dart';
import '../generated/assets.dart';
import '../l10n/l10n.dart';
import '../screens/play_song/widget/playlist_bottomsheet.dart';
import '../screens/tabs/music_service.dart';
import '../themes/color.dart';
import '../utills/snack_bar.dart';
import 'MusicListTile.dart';

class PlaylistMenuScreen extends StatefulWidget {
  final domain.Playlist playlist;
  final String playlistIconAsset;
  final List<Color> playlistGradientColors;
  final bool isSystemPlaylist;
  final String systemKeyOrId;
  final Future<void> Function()? onRename;

  const PlaylistMenuScreen({
    super.key,
    required this.playlist,
    required this.playlistIconAsset,
    required this.playlistGradientColors,
    required this.isSystemPlaylist,
    required this.systemKeyOrId,
    this.onRename,
  });

  @override
  State<PlaylistMenuScreen> createState() => _PlaylistMenuScreenState();
}

class _PlaylistMenuScreenState extends State<PlaylistMenuScreen> {
  final musicService = MusicPlayerService();

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.red,
      // constraints: BoxConstraints(maxHeight: 0.66.sh),
      // padding: EdgeInsets.only(top: 10.h, bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 10.h),
          Column(
            children: [
              // Playlist Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: MusicListTile(
                  margin: 7.w,
                  height: 66.h,
                  borderRadius: 10.r,
                  backgroundColor: AppColors.musicTileBackgroundColor,
                  cardHeight: 50.h,
                  cardWidth: 50.w,
                  cardRadius: 7.r,
                  noLogoGradientColor: widget.playlistGradientColors,
                  cardIconAsset: widget.playlistIconAsset,
                  cardIconSize: 32.r,
                  isSvgCardIcon: widget.playlistIconAsset.contains('.svg'),
                  title: widget.playlist.name,
                  subtitle: '${widget.playlist.songCount} Songs',
                  trailingIconAsset: Assets.svgIcShare,
                  trailingIconHeight: 25.h,
                  trailingIconWidth: 25.w,
                  trailingMargin: 2.w,
                  onTap: () {
                    showSnackBar(
                      context,
                      () {},
                      message: 'Share playlist feature coming soon',
                      alertBannerLocation: AlertBannerLocation.bottom,
                    );
                  },
                  onPlayTap: () {
                    showSnackBar(
                      context,
                      () {},
                      message: 'Play playlist feature coming soon',
                      alertBannerLocation: AlertBannerLocation.bottom,
                    );
                  },
                ),
              ),
              // Menu Items
              Column(
                children: [
                  _buildMenuItem(
                    icon: Assets.svgPlayBlackBorder,
                    title: S.of(context).play,
                    onTap: _handlePlay,
                  ),
                  _buildMenuItem(
                    icon: Assets.svgIcMenuPlaynext,
                    title: S.of(context).playNext,
                    onTap: _handlePlayNext,
                  ),
                  _buildMenuItem(
                    icon: Assets.svgIcMenuQueue,
                    title: S.of(context).addToQueue,
                    onTap: _handleAddToQueue,
                  ),
                  _buildMenuItem(
                    icon: Assets.svgIcMenuPlaylist,
                    title: S.of(context).addToPlaylist,
                    onTap: _handleAddToPlaylist,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Assets.svgIcEdit,
                    title: S.of(context).rename,
                    onTap: _handleRename,
                  ),
                  _buildMenuItem(
                    icon: Assets.svgIcCover,
                    title: S.of(context).changeCover,
                    onTap: _handleChangeCover,
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Assets.svgIcDelete,
                    title: S.of(context).deletePlaylist,
                    onTap: _handleDeletePlaylist,
                  ),
                ],
              ),
              // Cancel Button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(80.r),
                    border: Border.all(
                      color: AppColors.black.withValues(alpha: 0.10),
                      width: 1,
                    ),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                  height: 50.w,
                  child: Texts(
                    S.of(context).cancel,
                    fontSize: 14.sp,
                    align: TextAlign.center,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColor,
                    fontFamily: AppFonts.medium,
                  ),
                ),
              ),

              SizedBox(height: 25.h),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity(horizontal: 0.w, vertical: 0.h),
      leading: SvgPicture.asset(icon, height: 24, width: 24),
      title: Texts(
        title,
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        fontFamily: AppFonts.inter,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.black.withValues(alpha: .1),
      ),
    );
  }

  // Handle Play
  void _handlePlay() async {
    // Close the bottom sheet first
    Navigator.pop(context);

    List<SongsModel> _songs = [];
    final _repo = locator<PlaylistRepository>();
    try {
      if (widget.isSystemPlaylist) {
        log('Playing songs from system playlist ${widget.systemKeyOrId}');
        _songs = await _repo.getSongsForSystemPlaylist(widget.systemKeyOrId);
      } else {
        log('Playing songs from playlist ${widget.systemKeyOrId}');
        _songs = await _repo.getSongsForPlaylist(
          int.parse(widget.systemKeyOrId),
        );
      }

      if (_songs.isEmpty) {
        if (mounted) {
          showSnackBar(
            context,
            () {},
            message: "Playlist contains no songs",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
        return;
      }

      // Set playlist and play
      await musicService.setPlaylist(_songs, startIndex: 0);
      await musicService.play();

      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Playing ${_songs.length} songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error playing playlist: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Handle Play Next
  void _handlePlayNext() async {
    // Close the bottom sheet first
    Navigator.pop(context);

    List<SongsModel> _songs = [];
    final _repo = locator<PlaylistRepository>();
    try {
      if (widget.isSystemPlaylist) {
        log('Playing next songs from system playlist ${widget.systemKeyOrId}');
        _songs = await _repo.getSongsForSystemPlaylist(widget.systemKeyOrId);
      } else {
        log('Playing next songs from playlist ${widget.systemKeyOrId}');
        _songs = await _repo.getSongsForPlaylist(
          int.parse(widget.systemKeyOrId),
        );
      }

      if (_songs.isEmpty) {
        if (mounted) {
          showSnackBar(
            context,
            () {},
            message: "Playlist contains no songs",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
        return;
      }

      // Insert playlist songs after current song
      if (musicService.songs.isEmpty) {
        // No songs playing, start playing the playlist
        await musicService.setPlaylist(_songs, startIndex: 0);
        await musicService.play();
      } else {
        final currentIndex = musicService.currentIndex;
        final insertIndex = currentIndex + 1;
        final newSongsList = List<SongsModel>.from(musicService.songs);

        // Filter out songs that are already in the queue
        final songsToAdd = _songs.where((song) {
          return !newSongsList.any(
            (existingSong) => existingSong.id == song.id,
          );
        }).toList();

        // Insert the new songs after the current song
        newSongsList.insertAll(insertIndex, songsToAdd);

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
          message: "${_songs.length} songs added to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding to play next: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Handle Add to Queue
  void _handleAddToQueue() async {
    List<SongsModel> _songs = [];
    final _repo = locator<PlaylistRepository>();
    try {
      if (widget.isSystemPlaylist) {
        log('Fetching songs for system playlist ${widget.systemKeyOrId}');
        _songs = await _repo.getSongsForSystemPlaylist(widget.systemKeyOrId);
      } else {
        log('Fetching songs for playlist ${widget.systemKeyOrId}');
        _songs = await _repo.getSongsForPlaylist(
          int.parse(widget.systemKeyOrId),
        );
      }

      if (_songs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Playlist contains no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        Navigator.pop(context);
        return;
      }

      // Add entire songs list to queue
      final newSongsList = List<SongsModel>.from(musicService.songs);
      int addedCount = 0;

      for (var song in _songs) {
        final existingIndex = newSongsList.indexWhere((s) => s.id == song.id);
        if (existingIndex == -1) {
          newSongsList.add(song);
          addedCount++;
        }
      }

      await musicService.setPlaylist(newSongsList, autoPlay: false);

      showSnackBar(
        context,
        () {},
        message: "$addedCount songs added to queue",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error adding to queue: $e",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }

    Navigator.pop(context);
  }

  // Handle Add to Playlist
  void _handleAddToPlaylist() async {
    List<SongsModel> _songs = [];
    final _repo = locator<PlaylistRepository>();
    try {
      if (widget.isSystemPlaylist) {
        log('Fetching songs for system playlist ${widget.systemKeyOrId}');
        _songs = await _repo.getSongsForSystemPlaylist(widget.systemKeyOrId);
      } else {
        log('Fetching songs for playlist ${widget.systemKeyOrId}');
        _songs = await _repo.getSongsForPlaylist(
          int.parse(widget.systemKeyOrId),
        );
      }

      if (_songs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Playlist contains no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Show playlist bottom sheet with entire songs list
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
          ),
          isScrollControlled: true,
          builder: (_) => BlocProvider.value(
            value: context.read<PlaylistBloc>(),
            child: PlaylistBottomSheet(songsList: _songs),
          ),
        );
      }
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error fetching playlist songs: $e",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Handle Rename
  void _handleRename() {
    final renameCallback = widget.onRename;
    final isSystemPlaylist = widget.isSystemPlaylist;
    Navigator.pop(context);
    Future.microtask(() {
      if (isSystemPlaylist) {
        final rootContext = rootNavigatorKey.currentContext;
        if (rootContext != null) {
          showSnackBar(
            rootContext,
            () {},
            message: "System playlist cannot be renamed",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
        return;
      }
      renameCallback?.call();
    });
  }

  // Handle Change Cover
  void _handleChangeCover() {
    Navigator.pop(context);
    // TODO: Implement change cover functionality
    showSnackBar(
      context,
      () {},
      message: "Change cover feature coming soon",
      alertBannerLocation: AlertBannerLocation.bottom,
    );
  }

  // Handle Delete Playlist
  void _handleDeletePlaylist() {
    if (widget.isSystemPlaylist) {
      Navigator.pop(context);
      showSnackBar(
        context,
        () {},
        message: "System playlist cannot be deleted",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    _showDeletePlaylistBottomSheet();
  }

  void _showDeletePlaylistBottomSheet() {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 10.h,
          bottom: bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 30.h),
            Texts(
              S.of(context).deletePlaylist,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.inter,
              color: AppColors.textColor,
            ),
            SizedBox(height: 30.h),
            Texts(
              'Are you sure you want to delete "${widget.playlist.name}"?',
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              fontFamily: AppFonts.inter,
              color: AppColors.textColor,
              align: TextAlign.center,
            ),
            SizedBox(height: 25.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
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
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.pop(context);

                      final playlistBloc = context.read<PlaylistBloc>();
                      playlistBloc.add(
                        PlaylistEvent.deletePlaylist(
                          int.parse(widget.systemKeyOrId),
                        ),
                      );

                      showSnackBar(
                        context,
                        () {},
                        message: 'Playlist deleted successfully',
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
      ),
    );
  }
}
