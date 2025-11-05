import 'dart:developer' as logS;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/playlists/domain/entities/playlist.dart' as domain;
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/song_menu_screen.dart';
import '../../../../utills/globals.dart';
import '../../../../utills/snack_bar.dart';
import '../../../play_song/playing_song_screen.dart';
import '../widgets/mini_player_bar.dart';
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../features/playlists/bloc/playlist_bloc.dart';
import '../../../../features/playlists/domain/repositories/playlist_repository.dart';
import '../../../../generated/assets.dart';
import '../../../../core/di/injection.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final domain.Playlist playlist;
  final String assetIcon;
  final List<Color>? colors;
  const PlaylistDetailScreen({super.key, required this.playlist, required this.assetIcon, this.colors});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final _repo = locator<PlaylistRepository>();
  final musicService = MusicPlayerService();

  List<SongsModel> _songs = [];
  List<SongsModel> _baseSongs = [];
  late final bool _isSystem;

  @override
  void initState() {
    super.initState();
    _isSystem = widget.playlist.isSystem == true;
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    if (_isSystem) {
      _songs = await _repo.getSongsForSystemPlaylist(widget.playlist.systemKey ?? '');
    } else {
      _songs = await _repo.getSongsForPlaylist(widget.playlist.id!);
    }
    _baseSongs = List<SongsModel>.from(_songs);
    if (mounted) setState(() {});
  }

  Future<void> _reorderSong(int oldIndex, int newIndex) async {
    if (_isSystem) return; // system playlists are not manually reorderable
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _songs.removeAt(oldIndex);
    _songs.insert(newIndex, item);
    _baseSongs = List<SongsModel>.from(_songs);
    setState(() {});
    await locator<PlaylistRepository>().reorderPlaylistSongs(widget.playlist.id!, _songs.map((s) => s.id!).toList());
    // Keep current song playing after reorder
    await _applyOrderAndKeepCurrent(_songs);
  }

  Future<void> _reorderSystemSong(int oldIndex, int newIndex) async {
    if (!_isSystem) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _songs.removeAt(oldIndex);
    _songs.insert(newIndex, item);
    setState(() {});
    await _applyOrderAndKeepCurrent(_songs);
  }

  Future<void> _applyOrderAndKeepCurrent(List<SongsModel> newOrder) async {
    final currentId = musicService.currentSongId;
    setState(() => _songs = List<SongsModel>.from(newOrder));
    int startIndex = 0;
    if (currentId != null) {
      final idx = newOrder.indexWhere((s) => s.id == currentId);
      if (idx >= 0) startIndex = idx;
    }
    final shouldAutoplay = musicService.isPlaying;
    await musicService.setPlaylist(newOrder, startIndex: startIndex, autoPlay: shouldAutoplay);
    if (shouldAutoplay) {
      await musicService.play();
    }
  }

  Widget _songTile(List<SongsModel> list, int index) {
    final song = list[index];
    return StreamBuilder<int?>(
      stream: musicService.currentSongIdStream,
      initialData: musicService.currentSongId,
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
                isSvgCardIcon: (song.artwork_path ?? '').contains('.svg') || song.artwork_path == null,
                title: song.title,
                subtitle: song.artist,
                trailingIconAsset: Assets.svgMenuIcon,
                trailingIconHeight: 19.5.h,
                trailingIconWidth: 3.w,
                trailingMargin: 10.w,
                isGifLoad: isCurrent,
                onTap: () async {
                  if (musicService.songs.isNotEmpty && musicService.songs[musicService.currentIndex].id == song.id && musicService.isPlaying) {
                    context.push('/dashboard/playing', extra: PlayingSongArgs(songs: musicService.songs));
                  } else {
                    await musicService.setPlaylist(list, startIndex: index);
                    await musicService.play();
                  }
                },
                onPlayTap: () async {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
                    isScrollControlled: true,
                    builder: (_) => SongMenuScreen(
                      songMenuList: songMenuItems,
                      isPlaying: false,
                      currentSong: song,
                      songIndex: index,
                      songsList: list,
                      maxHeight: 0.87.sh,
                      systemKeyOrId: widget.playlist.isSystem! ? widget.playlist.systemKey : widget.playlist.id.toString(),
                      isSystemPlaylist: _isSystem,
                      from: 'playlist_in',
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

  // Custom delete playlist confirmation bottom sheet
  Widget _buildDeletePlaylistConfirmationDialog() {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Container(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 10.h, bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.r)),
          ),
          SizedBox(height: 30.h),

          // Title
          Texts('Delete Playlist', fontSize: 18.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.textColor),
          SizedBox(height: 30.h),

          // Message
          Texts(
            'Are you sure you want to delete this playlist?',
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
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8.r)),
                    child: Center(
                      child: Texts('Cancel', fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.black),
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

                    // Delete playlist
                    final playlistBloc = context.read<PlaylistBloc>();
                    playlistBloc.add(PlaylistEvent.deletePlaylist(widget.playlist.id!));

                    // Show success message
                    showSnackBar(context, () {}, message: 'Playlist deleted successfully', alertBannerLocation: AlertBannerLocation.bottom);

                    // Navigate back to previous screen
                    context.pop();
                  },
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(8.r)),
                    child: Center(
                      child: Texts('Delete', fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.white),
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
    return BlocListener<PlaylistBloc, PlaylistState>(
      listener: (context, state) {
        // Reload songs when playlist state changes (e.g., song removed)
        state.maybeWhen(
          loaded: (playlists, systemPlaylistSongs) {
            // Reload songs to reflect any changes
            _loadSongs();
          },
          orElse: () {},
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryOrange,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Texts(widget.playlist.name, fontSize: 18.sp, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter, color: AppColors.white),
          actions: [
            GestureDetector(
              onTap: () {
                if (_isSystem) {
                  showSnackBar(context, () {}, message: 'System playlist cannot be deleted', alertBannerLocation: AlertBannerLocation.bottom);
                } else {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
                    isScrollControlled: true,
                    builder: (_) => _buildDeletePlaylistConfirmationDialog(),
                  );
                }
              },
              child: Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: SvgPicture.asset(Assets.svgIcDelete, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            StreamBuilder<List<SongsModel>>(
              stream: musicService.songsChanged,
              initialData: musicService.songs,
              builder: (context, snapshot) {
                // Always check the current state, not just the snapshot
                final hasAny = musicService.songs.isNotEmpty;
                final showMiniPlayer = hasAny;

                return Padding(
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    top: 10.h,
                    // bottom: showMiniPlayer
                    //     ? 74.h
                    //     : 10.h, // Space for MiniPlayerBar (which includes system nav bar padding)
                  ),
                  child: SizedBox(
                    height: double.infinity,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 15.h),
                          GradientCard(
                            height: 150.h,
                            width: 150.w,
                            colors: [widget.colors![0].withValues(alpha: 0.21), widget.colors![1]],
                            borderRadius: 13.r,
                            iconAsset: widget.assetIcon,
                            iconSize: 60.r,
                            margin: 10.w,
                          ),
                          SizedBox(height: 14.h),
                          Texts(widget.playlist.name, fontSize: 20.sp, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter, color: AppColors.textColor),

                          SizedBox(height: 25.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  if (_songs.isEmpty) return;

                                  if (musicService.currentIndex < 0) {
                                    await musicService.setPlaylist(_songs, autoPlay: false, startIndex: 0);
                                    await musicService.play();
                                    context.push('/dashboard/playing', extra: PlayingSongArgs(songs: _songs));
                                  } else {
                                    await musicService.setShufflePlaylist(
                                      _songs,
                                      autoPlay: false,
                                    );
                                    context.push('/dashboard/playing', extra: PlayingSongArgs(songs: _songs));
                                    await musicService.ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();
                                    await musicService.player.currentIndexStream.firstWhere((idx) => idx != null && idx != 0);
                                    await musicService.play();
                                  }

                                  // if (_songs.isEmpty) return;
                                  //
                                  // await musicService.setPlaylist(
                                  //   _songs,
                                  //   autoPlay: false,
                                  // );
                                  // await musicService
                                  //     .ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();
                                  //
                                  // // Wait until the player has fully updated its index
                                  // await musicService.player.currentIndexStream
                                  //     .firstWhere((idx) => idx != null && idx != 0);
                                  //
                                  // // Now play
                                  // await musicService.play();
                                  //
                                  // logS.log("Shuffle Play started");
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  height: 40.h,
                                  width: 165.w,
                                  decoration: BoxDecoration(color: AppColors.shuffleBackground, borderRadius: BorderRadius.circular(100.r)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(Assets.svgShuffle, height: 16.79.h, width: 17.77.w),
                                      SizedBox(width: 10.w),
                                      Texts('Shuffle', fontWeight: AppFontWeights.medium, fontSize: 14.sp, color: AppColors.black),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  if (_baseSongs.isEmpty) return;
                                  await musicService.ensureShuffleOff();

                                  // Start from the first song of the playlist
                                  await musicService.setPlaylist(List<SongsModel>.from(_baseSongs), startIndex: 0, autoPlay: true);
                                  await musicService.play();
                                },
                                child: Container(
                                  height: 40.h,
                                  width: 165.w,
                                  decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(100.r)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset(Assets.svgPlay, height: 16.79.h, width: 17.77.w),
                                      SizedBox(width: 10.w),
                                      Texts('Play', fontWeight: AppFontWeights.medium, fontSize: 14.sp, color: AppColors.white),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 25.h),

                          // Song count header with bullets and add icons
                          Row(
                            children: [
                              // Bullets icon and song count
                              GestureDetector(
                                onTap: () {
                                  // Navigate to select song screen for playlist management
                                  context.push('/dashboard/select-song', extra: {'playlist': widget.playlist, 'songs': _songs, 'isSystemPlaylist': _isSystem});
                                },
                                child: Row(
                                  children: [
                                    SvgPicture.asset(Assets.svgSongsCount),
                                    SizedBox(width: 8.w),
                                    Texts(
                                      '${_songs.length} songs',
                                      fontSize: 16.sp,
                                      fontWeight: AppFontWeights.medium,
                                      fontFamily: AppFonts.inter,
                                      color: AppColors.textColor,
                                    ),
                                  ],
                                ),
                              ),

                              Spacer(),

                              // Add songs icon (only for non-system playlists)
                              if (!_isSystem)
                                GestureDetector(
                                  onTap: () {
                                    context.push('/dashboard/add-songs', extra: widget.playlist);
                                  },
                                  child: Container(
                                    height: 32.h,
                                    width: 32.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.mediumDarkGrey.withAlpha(100),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Icon(Icons.add),
                                  ),
                                ),
                            ],
                          ),

                          SizedBox(height: 37.h),

                          if (_songs.isEmpty) ...{
                            Center(
                              child: Texts('No songs available', fontSize: 16, fontWeight: AppFontWeights.regular, fontFamily: AppFonts.inter),
                            ),
                          },
                          Column(
                            children: List.generate(_songs.length, (index) {
                              return _songTile(_songs, index);
                            }),
                          ),

                          SizedBox(height: 200.h),
                        ],
                      ),
                    ),
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
