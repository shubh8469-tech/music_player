import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../app_router.dart';
import '../core/di/injection.dart';
import '../features/playlists/bloc/playlist_bloc.dart';
import '../features/playlists/domain/entities/playlist.dart' as domain;
import '../features/playlists/domain/repositories/playlist_repository.dart';
import '../generated/assets.dart';
import '../l10n/l10n.dart';
import '../screens/common/image_crop_screen.dart';
import 'common_modal_bottom_sheet.dart';
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
  String? _coverPath;

  @override
  void initState() {
    super.initState();
    _coverPath = widget.playlist.coverPath;
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomCover = (_coverPath?.isNotEmpty ?? false);
    final headerIcon = hasCustomCover ? _coverPath! : widget.playlistIconAsset;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final isSvgHeader = headerIcon.contains('.svg');
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return SafeArea(
      child: Padding(
        // constraints: BoxConstraints(maxHeight: 0.74.sh),
        padding: EdgeInsets.only(top: 10.h, bottom: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(Assets.svgIcLineBottom),
            SizedBox(height: 10.h),
            Column(
              children: [
                // Playlist Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: MusicListTile(
                    margin: 7.w,
                    height: 66.h,
                    borderRadius: 10.r,
                    backgroundColor: AppColors.musicTileBackgroundColor,
                    cardHeight: 50.h,
                    cardWidth: 50.h,
                    cardRadius: 7.r,
                    noLogoGradientColor: widget.playlistGradientColors,
                    cardIconAsset: headerIcon,
                    cardIconSize: 32.r,
                    isSvgCardIcon: isSvgHeader,
                    isSvgColorNeeded: isSvgHeader,
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
                if (!widget.isSystemPlaylist) ...[
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
                margin: EdgeInsets.only(top: 8.h, left: 15.w, right: 15.w),
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
          ],
        ),
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

    List<SongsModel> _songs = [];
    final _repo = locator<PlaylistRepository>();
    int updateCount = 0;
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
        updateCount = await musicService.playNextMultipleSongs(_songs);
        log('Not Added $updateCount songs to play next');
        showSnackBar(
          context,
          () {},
          message: "$updateCount songs added to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        // final currentIndex = musicService.currentIndex;
        // final insertIndex = currentIndex + 1;
        // final newSongsList = List<SongsModel>.from(musicService.songs);
        //
        // // Filter out songs that are already in the queue
        // final songsToAdd = _songs.where((song) {
        //   return !newSongsList.any(
        //     (existingSong) => existingSong.id == song.id,
        //   );
        // }).toList();
        //
        // // Insert the new songs after the current song
        // newSongsList.insertAll(insertIndex, songsToAdd);
        //
        // await musicService.setPlaylist(
        //   newSongsList,
        //   startIndex: currentIndex >= 0 ? currentIndex : 0,
        //   autoPlay: false,
        // );
      }
      if (mounted) {
        if (updateCount < 1) {
          log('Not Added $updateCount songs to play next');
          showSnackBar(
            context,
            () {},
            message: "Songs already added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        } else {
          log('Added $updateCount songs to play next');
          showSnackBar(
            context,
            () {},
            message: "$updateCount songs added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding to play next: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
      Navigator.pop(context);
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

      final addedSong = await musicService.addMultipleSongsToQueue(_songs);

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

      // if (_songs.isEmpty) {
      //   showSnackBar(
      //     context,
      //     () {},
      //     message: "Playlist contains no songs",
      //     alertBannerLocation: AlertBannerLocation.bottom,
      //   );
      //   Navigator.pop(context);
      //   return;
      // }
      //
      // // Add entire songs list to queue
      // final newSongsList = List<SongsModel>.from(musicService.songs);
      // int addedCount = 0;
      //
      // for (var song in _songs) {
      //   final existingIndex = newSongsList.indexWhere((s) => s.id == song.id);
      //   if (existingIndex == -1) {
      //     newSongsList.add(song);
      //     addedCount++;
      //   }
      // }
      //
      // await musicService.setPlaylist(newSongsList, autoPlay: false);
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
      //       message: "$addedCount songs added to queue",
      //       alertBannerLocation: AlertBannerLocation.bottom,
      //     );
      //   }
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
        showCommonAddToPlaylistBottomSheet(
          context,
          songsList: _songs,
          playlistBloc: context.read<PlaylistBloc>(),
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
    if (widget.isSystemPlaylist) {
      Navigator.pop(context);
      showSnackBar(
        context,
        () {},
        message: "System playlist cover cannot be changed",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    _handleChangeCoverFlow();
  }

  Future<void> _handleChangeCoverFlow() async {
    final action = await _showChangeCoverSelectionSheet();
    if (!mounted || action == null) {
      return;
    }

    if (action == _ChangeCoverAction.localGallery) {
      await _handleLocalGalleryCover();
    } else if (action == _ChangeCoverAction.searchOnline) {
      showSnackBar(
        context,
        () {},
        message: 'Search online feature coming soon',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  Future<_ChangeCoverAction?> _showChangeCoverSelectionSheet() {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return showModalBottomSheet<_ChangeCoverAction>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            bottom: bottomPadding,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Center(
                  child: Texts(
                    'Select cover from',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                ),
                SizedBox(height: 24.h),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 21.w,
                    height: 21.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: SvgPicture.asset(
                      Assets.svgLocalGallery,
                      colorFilter: const ColorFilter.mode(
                        AppColors.black,
                        BlendMode.srcIn,
                      ),
                      height: 16.h,
                      width: 16.h,
                    ),
                  ),
                  title: Texts(
                    'Local gallery',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      _ChangeCoverAction.localGallery,
                    );
                  },
                ),
                Divider(
                  color: Colors.black.withOpacity(0.08),
                  height: 12.h,
                  thickness: 0.8,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 23.w,
                    height: 23.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: SvgPicture.asset(
                      Assets.svgSearch,
                      colorFilter: const ColorFilter.mode(
                        AppColors.black,
                        BlendMode.srcIn,
                      ),
                      height: 16.h,
                      width: 16.h,
                    ),
                  ),
                  title: Texts(
                    'Search online',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      _ChangeCoverAction.searchOnline,
                    );
                  },
                ),
                SizedBox(height: 24.h),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(sheetContext);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Texts(
                      'Close',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFonts.inter,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLocalGalleryCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      Uint8List? bytes = file.bytes;

      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        if (!mounted) return;
        showSnackBar(
          context,
          () {},
          message: 'Unable to read selected image',
          backgroundColor: Colors.red,
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => ImageCropScreen(imageBytes: bytes!),
          fullscreenDialog: true,
        ),
      );

      if (croppedBytes == null) {
        return;
      }

      final optimizedBytes = await _optimizeImage(croppedBytes);
      final savedFile = await _persistCustomCover(optimizedBytes);

      final previousCoverPath = _coverPath;
      await _cleanupPreviousCover(previousCoverPath);
      await _updatePlaylistCover(savedFile.path);

      if (!mounted) return;

      setState(() {
        _coverPath = savedFile.path;
      });

      showSnackBar(
        context,
        () {},
        message: 'Cover updated successfully',
        alertBannerLocation: AlertBannerLocation.bottom,
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        context,
        () {},
        message: 'Failed to update cover: $e',
        backgroundColor: Colors.red,
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  Future<Uint8List> _optimizeImage(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unsupported image format');
    }

    final maxDimension = 720;
    img.Image processed = decoded;
    final largestSide = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;

    if (largestSide > maxDimension) {
      if (decoded.width >= decoded.height) {
        processed = img.copyResize(
          decoded,
          width: maxDimension,
          height: (decoded.height * maxDimension / decoded.width).round(),
        );
      } else {
        processed = img.copyResize(
          decoded,
          height: maxDimension,
          width: (decoded.width * maxDimension / decoded.height).round(),
        );
      }
    }

    final optimizedBytes = img.encodeJpg(processed, quality: 85);

    return Uint8List.fromList(optimizedBytes);
  }

  Future<File> _persistCustomCover(Uint8List bytes) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(
      p.join(documentsDir.path, 'covers', 'playlists'),
    );

    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    final playlistId = widget.playlist.id;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'playlist_${playlistId ?? timestamp}_$timestamp.jpg';
    final filePath = p.join(coversDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _cleanupPreviousCover(String? existingPath) async {
    if (existingPath == null || existingPath.isEmpty) {
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final coversDirPath = p.join(documentsDir.path, 'covers', 'playlists');

      if (p.isWithin(coversDirPath, existingPath)) {
        final existingFile = File(existingPath);
        if (await existingFile.exists()) {
          await existingFile.delete();
        }
      }
    } catch (e) {
      log('Failed to remove previous playlist cover: $e');
    }
  }

  Future<void> _updatePlaylistCover(String newPath) async {
    final playlistId = widget.playlist.id;
    if (playlistId == null) {
      return;
    }

    context.read<PlaylistBloc>().add(
      PlaylistEvent.updatePlaylistCover(playlistId, newPath),
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

    showCommonConfirmationBottomSheet(
      context: context,
      title: S.of(context).deletePlaylist,
      message: 'Are you sure you want to delete "${widget.playlist.name}"?',
      onConfirm: (sheetContext) async {
        Navigator.pop(sheetContext);
        Navigator.pop(context);
        final playlistBloc = context.read<PlaylistBloc>();
        playlistBloc.add(
          PlaylistEvent.deletePlaylist(int.parse(widget.systemKeyOrId)),
        );
        showSnackBar(
          context,
          () {},
          message: 'Playlist deleted successfully',
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      },
    );
  }
}

enum _ChangeCoverAction { localGallery, searchOnline }
