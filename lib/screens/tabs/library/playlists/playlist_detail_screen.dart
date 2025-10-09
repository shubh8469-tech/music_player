import 'dart:developer' as logS;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/features/playlists/domain/entities/playlist.dart'
    as domain;
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import '../../../../commonWidgets/song_menu_screen.dart';
import '../../../../utills/globals.dart';
import '../widgets/mini_player_bar.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../features/playlists/bloc/playlist_bloc.dart';
import '../../../../features/playlists/domain/repositories/playlist_repository.dart';
import '../../../../generated/assets.dart';
import '../../../../core/di/injection.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final domain.Playlist playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  final _repo = locator<PlaylistRepository>();
  final _player = MusicPlayerService();

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
      _songs = await _repo.getSongsForSystemPlaylist(
        widget.playlist.systemKey ?? '',
      );
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
    await locator<PlaylistRepository>().reorderPlaylistSongs(
      widget.playlist.id!,
      _songs.map((s) => s.id!).toList(),
    );
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
    final currentId = _player.currentSongId;
    setState(() => _songs = List<SongsModel>.from(newOrder));
    int startIndex = 0;
    if (currentId != null) {
      final idx = newOrder.indexWhere((s) => s.id == currentId);
      if (idx >= 0) startIndex = idx;
    }
    final shouldAutoplay = _player.isPlaying;
    await _player.setPlaylist(
      newOrder,
      startIndex: startIndex,
      autoPlay: shouldAutoplay,
    );
    if (shouldAutoplay) {
      await _player.play();
    }
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
          child: MusicListTile(
            margin: 7.w,
            height: 66.h,
            borderRadius: 10.r,
            backgroundColor: AppColors.musicTileBackgroundColor,
            cardHeight: 50.h,
            cardWidth: 50.w,
            cardRadius: 7.r,
            cardIconAsset: song.artwork_path!,
            cardIconSize: 32.r,
            isSvgCardIcon: true,
            title: song.title,
            subtitle: song.artist,
            trailingIconAsset: Assets.svgMenuIcon,
            trailingIconHeight: 22.5.h,
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
                  systemKeyOrId: widget.playlist.id.toString(),
                  isSystemPlaylist: _isSystem,
                  from: 'playlist',
                ),
              );
            },
          ),
        );
      },
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
          backgroundColor: AppColors.white,
          elevation: 0,
          title: Texts(
            widget.playlist.name,
            fontSize: 18.sp,
            fontWeight: AppFontWeights.medium,
            fontFamily: AppFonts.inter,
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: SvgPicture.asset(Assets.svgMenuIcon),
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 10.h,
                bottom: _player.isPlaying ? 80.h : 10.h,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (_songs.isEmpty) return;

                          // Get current playing song info before shuffling
                          final currentSongId = _player.currentSongId;
                          final wasPlaying = _player.isPlaying;

                          // Create shuffled list for UI
                          final shuffledSongs = List<SongsModel>.from(_songs);
                          shuffledSongs.shuffle();

                          // Find the position of the currently playing song in the shuffled list
                          int startIndex = 0;
                          if (currentSongId != null) {
                            final currentIndex = shuffledSongs.indexWhere(
                              (song) => song.id == currentSongId,
                            );
                            if (currentIndex >= 0) {
                              startIndex = currentIndex;
                            } else {
                              // If current song not found, pick a random index
                              startIndex = Random().nextInt(
                                shuffledSongs.length,
                              );
                            }
                          } else {
                            // If no current song, pick a random index
                            startIndex = Random().nextInt(shuffledSongs.length);
                          }

                          // Update UI with shuffled order
                          setState(() {
                            _songs = shuffledSongs;
                          });

                          // Enable shuffle mode and set playlist with shuffled order
                          await _player.ensureShuffleOnAndReshuffle();
                          await _player.setPlaylist(
                            shuffledSongs,
                            startIndex: 0,
                            autoPlay: wasPlaying,
                          );
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
                                width: 17.77,
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
                          await _applyOrderAndKeepCurrent(
                            List<SongsModel>.from(_baseSongs),
                          );
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
                                width: 17.77,
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
                  SizedBox(height: 15.h),
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

                        if (_isSystem) {
                          // Enable manual drag for system playlists (session-only order)
                          return ReorderableListView.builder(
                            itemCount: _songs.length,
                            onReorder: _reorderSystemSong,
                            buildDefaultDragHandles: false,
                            itemBuilder: (context, index) {
                              final song = _songs[index];
                              return ReorderableDelayedDragStartListener(
                                key: ValueKey(song.id),
                                index: index,
                                child: _songTile(_songs, index),
                              );
                            },
                          );
                        }

                        return ReorderableListView.builder(
                          itemCount: _songs.length,
                          onReorder: _reorderSong,
                          buildDefaultDragHandles: false,
                          itemBuilder: (context, index) {
                            final song = _songs[index];
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey(song.id),
                              index: index,
                              child: _songTile(_songs, index),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayerBar()),
          ],
        ),
      ),
    );
  }
}
