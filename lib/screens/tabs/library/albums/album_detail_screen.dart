import 'dart:developer' as logS;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/albums/domain/entities/album.dart';
import 'package:music_app/features/albums/bloc/album_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/song_menu_screen.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../features/albums/domain/repositories/album_repository.dart';
import '../../../../generated/assets.dart';
import '../../../../core/di/injection.dart';
import '../../../../utills/globals.dart';
import '../../../../utills/snack_bar.dart';
import '../widgets/mini_player_bar.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album album;
  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final _repo = locator<AlbumRepository>();
  final _player = MusicPlayerService();

  List<SongsModel> _songs = [];
  List<SongsModel> _baseSongs = [];
  late Album _currentAlbum;

  @override
  void initState() {
    super.initState();
    _currentAlbum = widget.album;
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await _repo.getSongsForAlbum(_currentAlbum.id!);
    if (mounted) {
      setState(() {
        _songs = songs.cast<SongsModel>();
        _baseSongs = List<SongsModel>.from(_songs);
      });
    }
  }

  Future<void> _refreshAlbumData() async {
    // Refresh album data to get updated song count
    final albumBloc = context.read<AlbumBloc>();
    albumBloc.add(const AlbumEvent.fetchAllAlbums());
  }

  Widget _songTile(List<SongsModel> list, int index) {
    final song = list[index];
    return StreamBuilder<int?>(
      stream: _player.currentSongIdStream,
      initialData: _player.currentSongId,
      builder: (context, idSnap) {
        final currentId = idSnap.data;
        final isCurrent = song.id == currentId;
        return Material(
          key: ValueKey(song.id),
          color: Colors.transparent,
          child: Column(
            children: [
              MusicListTile(
                margin: 7.w,
                height: 66.h,
                borderRadius: 10.r,
                backgroundColor: AppColors.musicTileBackgroundColor,
                cardHeight: 50.h,
                cardWidth: 50.w,
                cardRadius: 7.r,
                cardIconAsset: song.artwork_path ?? Assets.svgMusicIcon,
                cardIconSize: 32.r,
                isSvgCardIcon:
                    (song.artwork_path ?? '').contains('.svg') ||
                    song.artwork_path == null,
                title: song.title,
                subtitle: song.artist,
                trailingIconAsset: Assets.svgMenuIcon,
                trailingIconHeight: 19.5.h,
                trailingIconWidth: 3.w,
                trailingMargin: 10.w,
                isGifLoad: isCurrent,
                onTap: () async {
                  await _player.setPlaylist(list, startIndex: index);
                  await _player.play();
                },
                onPlayTap: () async {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(40.r),
                      ),
                    ),
                    isScrollControlled: true,
                    builder: (_) => SongMenuScreen(
                      songMenuList: songMenuItems,
                      isPlaying: false,
                      currentSong: song,
                      songIndex: index,
                      songsList: list,
                      maxHeight: 0.87.sh,
                      systemKeyOrId: _currentAlbum.id.toString(),
                      isSystemPlaylist: false,
                      from: 'album_in',
                      onSongDeleted: () {
                        // Immediately remove the song from local list for instant UI update
                        final songId = song.id;
                        setState(() {
                          _songs.removeWhere((s) => s.id == songId);
                          _baseSongs.removeWhere((s) => s.id == songId);
                          // Decrement album count temporarily (will be synced from DB)
                          _currentAlbum = Album(
                            id: _currentAlbum.id,
                            name: _currentAlbum.name,
                            artist: _currentAlbum.artist,
                            songCount: _currentAlbum.songCount - 1,
                            year: _currentAlbum.year,
                            artworkPath: _currentAlbum.artworkPath,
                            createdTime: _currentAlbum.createdTime,
                            updatedTime: _currentAlbum.updatedTime,
                          );
                        });

                        // Wait for database operations and triggers to complete, then sync with DB
                        Future.delayed(
                          const Duration(milliseconds: 800),
                          () async {
                            if (mounted) {
                              await _loadSongs();
                              _refreshAlbumData();
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Custom delete album confirmation bottom sheet
  Widget _buildDeleteAlbumConfirmationDialog() {
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
            'Delete Album',
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          SizedBox(height: 30.h),

          // Message
          Texts(
            'Are you sure you want to delete this album?',
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
                        'Cancel',
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
                  onTap: () async {
                    Navigator.pop(context); // Close bottom sheet

                    // Show success message
                    showSnackBar(
                      context,
                      () {},
                      message: 'Album deleted successfully',
                      alertBannerLocation: AlertBannerLocation.bottom,
                    );

                    // Navigate back to previous screen
                    context.pop();

                    // Refresh album list
                    _refreshAlbumData();
                  },
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Texts(
                        'Delete',
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
    return MultiBlocListener(
      listeners: [
        BlocListener<AlbumBloc, AlbumState>(
          listener: (context, state) {
            // Update current album when albums are refreshed
            state.maybeWhen(
              loaded: (albums, albumSongs) {
                // Find the updated album with new song count
                final updatedAlbum = albums.firstWhere(
                  (album) => album.id == _currentAlbum.id,
                  orElse: () => _currentAlbum,
                );
                // Update album if it exists and has changed
                if (updatedAlbum.id == _currentAlbum.id) {
                  final oldSongCount = _currentAlbum.songCount;
                  final newSongCount = updatedAlbum.songCount;
                  final songCountChanged = newSongCount != oldSongCount;
                  final hasChanged =
                      songCountChanged ||
                      updatedAlbum.name != _currentAlbum.name;

                  if (hasChanged && mounted) {
                    setState(() {
                      _currentAlbum = updatedAlbum;
                    });
                    // Only reload songs if the count actually decreased (song was deleted)
                    // This prevents unnecessary reloads when album is just refreshed
                    if (songCountChanged && newSongCount < oldSongCount) {
                      _loadSongs();
                    }
                  }
                }
              },
              orElse: () {},
            );
          },
        ),
        BlocListener<SongsBloc, SongsState>(
          listener: (context, state) {
            // When a song is successfully removed, refresh album data
            state.maybeWhen(
              loaded: (songs) {
                // Wait a bit for database trigger to update album count, then refresh
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _refreshAlbumData();
                  }
                });
              },
              orElse: () {},
            );
          },
        ),
      ],
      child: Scaffold(
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
          title: Texts(
            _currentAlbum.name,
            fontSize: 18.sp,
            fontWeight: AppFontWeights.medium,
            fontFamily: AppFonts.inter,
            color: AppColors.white,
          ),
          actions: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(40.r),
                    ),
                  ),
                  isScrollControlled: true,
                  builder: (_) => _buildDeleteAlbumConfirmationDialog(),
                );
              },
              child: Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: SvgPicture.asset(
                  Assets.svgIcDelete,
                  colorFilter: const ColorFilter.mode(
                    AppColors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            StreamBuilder<List<SongsModel>>(
              stream: _player.songsChanged,
              initialData: _player.songs,
              builder: (context, snapshot) {
                // Always check the current state, not just the snapshot
                final hasAny = _player.songs.isNotEmpty;
                final showMiniPlayer = hasAny;

                return Padding(
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    top: 10.h,
                    bottom: showMiniPlayer
                        ? 74.h
                        : 10.h, // Space for MiniPlayerBar (which includes system nav bar padding)
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 15.h),
                      GradientCard(
                        height: 150.h,
                        width: 150.w,
                        colors: [
                          AppColors.mildOrange.withValues(alpha: 0.21),
                          AppColors.primaryOrange,
                        ],
                        borderRadius: 13.r,
                        iconAsset: Assets.svgAlbum,
                        iconSize: 60.r,
                        margin: 10.w,
                      ),
                      SizedBox(height: 14.h),
                      Texts(
                        _currentAlbum.name,
                        fontSize: 20.sp,
                        fontWeight: AppFontWeights.medium,
                        fontFamily: AppFonts.inter,
                        color: AppColors.textColor,
                        align: TextAlign.center,
                      ),
                      if (_currentAlbum.artist != null) ...[
                        SizedBox(height: 4.h),
                        Texts(
                          _currentAlbum.artist!,
                          fontSize: 14.sp,
                          fontWeight: AppFontWeights.regular,
                          fontFamily: AppFonts.inter,
                          color: AppColors.mediumDarkGrey,
                          align: TextAlign.center,
                        ),
                      ],
                      SizedBox(height: 25.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (_songs.isEmpty) return;

                              await _player.setPlaylist(
                                _songs,
                                autoPlay: false,
                              );
                              await _player
                                  .ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();

                              // Wait until the player has fully updated its index
                              await _player.player.currentIndexStream
                                  .firstWhere((idx) => idx != null && idx != 0);

                              // Now play
                              await _player.play();

                              logS.log("Shuffle Play started");
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: 40.h,
                              width: 165.w,
                              decoration: BoxDecoration(
                                color: AppColors.shuffleBackground,
                                borderRadius: BorderRadius.circular(100.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    Assets.svgShuffle,
                                    height: 16.79.h,
                                    width: 17.77.w,
                                  ),
                                  SizedBox(width: 10.w),
                                  Texts(
                                    'Shuffle',
                                    fontWeight: AppFontWeights.medium,
                                    fontSize: 14.sp,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (_baseSongs.isEmpty) return;
                              await _player.ensureShuffleOff();

                              // Start from the first song of the album
                              await _player.setPlaylist(
                                List<SongsModel>.from(_baseSongs),
                                startIndex: 0,
                                autoPlay: true,
                              );
                              await _player.play();
                            },
                            child: Container(
                              height: 40.h,
                              width: 165.w,
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange,
                                borderRadius: BorderRadius.circular(100.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    Assets.svgPlay,
                                    height: 16.79.h,
                                    width: 17.77.w,
                                  ),
                                  SizedBox(width: 10.w),
                                  Texts(
                                    'Play',
                                    fontWeight: AppFontWeights.medium,
                                    fontSize: 14.sp,
                                    color: AppColors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25.h),

                      // Song count header
                      Row(
                        children: [
                          // Bullets icon and song count
                          GestureDetector(
                            onTap: () {
                              // Navigate to select album screen for album management
                              context.push(
                                '/dashboard/select-albums',
                                extra: {
                                  'album': _currentAlbum,
                                  'songs': _songs,
                                },
                              );
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(Assets.svgSongsCount),
                                SizedBox(width: 8.w),
                                Texts(
                                  '${_currentAlbum.songCount} songs',
                                  fontSize: 16.sp,
                                  fontWeight: AppFontWeights.medium,
                                  fontFamily: AppFonts.inter,
                                  color: AppColors.textColor,
                                ),
                                if (_currentAlbum.year != null) ...[
                                  SizedBox(width: 10.w),
                                  Texts(
                                    '• ${_currentAlbum.year}',
                                    fontSize: 14.sp,
                                    fontWeight: AppFontWeights.regular,
                                    fontFamily: AppFonts.inter,
                                    color: AppColors.mediumDarkGrey,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 37.h),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            if (_songs.isEmpty) {
                              return Center(
                                child: Texts(
                                  'No songs available',
                                  fontSize: 16,
                                  fontWeight: AppFontWeights.regular,
                                  fontFamily: AppFonts.inter,
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _songs.length,
                              itemBuilder: (context, index) {
                                return _songTile(_songs, index);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayerBar()),
          ],
        ),
      ),
    );
  }
}
