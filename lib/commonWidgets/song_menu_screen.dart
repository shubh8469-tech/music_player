import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';
import '../core/di/injection.dart';
import '../features/playlists/bloc/playlist_bloc.dart';
import '../features/playlists/domain/repositories/playlist_repository.dart';
import '../features/songs/bloc/songs_bloc.dart';
import '../generated/assets.dart';
import '../l10n/l10n.dart';
import '../model/song_menu_model.dart';
import '../screens/play_song/widget/playlist_bottomsheet.dart';
import '../screens/tabs/music_service.dart';
import '../themes/color.dart';
import 'MusicListTile.dart';
import 'common_functions.dart';

class SongMenuScreen extends StatefulWidget {
  final List<SongMenuItem> songMenuList;
  final bool isPlaying;
  List<SongsModel>? songsList;
  SongsModel? currentSong;
  int? songIndex;
  bool isSystemPlaylist;
  String? systemKeyOrId;
  String? from;
  double maxHeight;

  SongMenuScreen({
    super.key,
    required this.songMenuList,
    required this.isPlaying,
    this.songsList,
    this.currentSong,
    this.songIndex,
    this.maxHeight = 0.87,
    this.isSystemPlaylist = true,
    this.systemKeyOrId,
    this.from,
  });

  @override
  State<SongMenuScreen> createState() => _SongMenuScreenState();
}

class _SongMenuScreenState extends State<SongMenuScreen> {
  bool keepScreenOn = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      padding: EdgeInsets.only(
        top: 10.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 10.h),
          Flexible(
            child: Column(
              children: [
                if (widget.currentSong != null)
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
                      cardWidth: 50.w,
                      cardRadius: 7.r,
                      noLogoGradientColor: [
                        AppColors.mildOrange.withValues(alpha: 0.21),
                        AppColors.primaryOrange,
                      ],
                      cardIconAsset: widget.currentSong?.artwork_path ?? '',
                      cardIconSize: 32.r,
                      title: widget.currentSong?.title ?? '',
                      subtitle: formatDuration(
                        widget.currentSong?.duration ?? 0,
                      ),
                      trailingIconAsset: Assets.svgIcShare,
                      trailingIconHeight: 25.h,
                      trailingIconWidth: 25.w,
                      trailingMargin: 2.w,
                      onTap: () => setState(() {}),
                      onPlayTap: () => setState(() {}),
                      onInfoTap: () => {},
                      leadingIconAsset: Assets.svgIcInfo,
                      leadingIconHeight: 25.h,
                      leadingIconWidth: 25.w,
                      isLeading: true,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.songMenuList.length,
                    itemBuilder: (context, index) {
                      final songItem = widget.songMenuList[index];

                      List<String> dividerAfterTitles = [];
                      if (widget.isPlaying) {
                        dividerAfterTitles = [
                          S.of(context).goToArtist,
                          S.of(context).keepScreenOn,
                          S.of(context).changeCover,
                        ];
                      } else {
                        dividerAfterTitles = [
                          S.of(context).addToPlaylist,
                          S.of(context).goToArtist,
                          S.of(context).changeCover,
                        ];
                      }
                      final showDivider = dividerAfterTitles.contains(
                        songItem.title,
                      );
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(
                              horizontal: 0.w,
                              vertical: 0.h,
                            ),
                            leading: SvgPicture.asset(
                              songItem.icon,
                              height: 24,
                              width: 24,
                            ),
                            title: Texts(
                              songItem.title,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppFonts.inter,
                            ),
                            trailing:
                                songItem.title == S.of(context).keepScreenOn
                                ? IconButton(
                                    icon: SvgPicture.asset(
                                      keepScreenOn
                                          ? Assets.svgIcSwitchOn
                                          : Assets.svgIcSwitchOff,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        keepScreenOn = !keepScreenOn;
                                      });
                                    },
                                  )
                                : null,
                            onTap: () async {
                              var musicService = MusicPlayerService();
                              if (songItem.title ==
                                  S.of(context).keepScreenOn) {
                                if (songItem.title == 'Edit details') {
                                  context.push('/dashboard/edit-song');
                                } else {
                                  context.push('/dashboard/playing');
                                }
                              } else if (songItem.title ==
                                  S.of(context).playNext) {
                                // Add song to play next (insert after current song)
                                final currentIndex = musicService.currentIndex;
                                final insertIndex = currentIndex + 1;

                                // Create a new list with the song inserted at the correct position
                                final newSongsList = List<SongsModel>.from(
                                  musicService.songs,
                                );

                                // Check if song is already in the queue
                                final existingIndex = newSongsList.indexWhere(
                                  (song) => song.id == widget.currentSong!.id,
                                );

                                if (existingIndex != -1) {
                                  // Song already exists, move it to the correct position
                                  final songToMove = newSongsList.removeAt(
                                    existingIndex,
                                  );
                                  final adjustedInsertIndex =
                                      existingIndex < insertIndex
                                      ? insertIndex - 1
                                      : insertIndex;
                                  newSongsList.insert(
                                    adjustedInsertIndex,
                                    songToMove,
                                  );
                                } else {
                                  // Song doesn't exist, insert it
                                  newSongsList.insert(
                                    insertIndex,
                                    widget.currentSong!,
                                  );
                                }

                                // Update the music service with the new playlist

                                musicService.setPlaylist(
                                  newSongsList,
                                  autoPlay: false,
                                  startIndex:
                                      !(existingIndex >
                                          musicService.currentIndex)
                                      ? musicService.currentIndex - 1
                                      : musicService.currentIndex,
                                );
                                Navigator.pop(context);
                              } else if (songItem.title ==
                                  S.of(context).addToQueue) {
                                if (widget.from == 'playlist') {
                                  List<SongsModel> _songs = [];
                                  final _repo = locator<PlaylistRepository>();
                                  if (widget.isSystemPlaylist) {
                                    log(
                                      'Fetching songs for system playlist ${widget.systemKeyOrId}',
                                    );
                                    _songs = await _repo
                                        .getSongsForSystemPlaylist(
                                          widget.systemKeyOrId ?? '',
                                        );
                                  } else {
                                    log(
                                      'Fetching songs for system playlist ${widget.systemKeyOrId}',
                                    );
                                    _songs = await _repo.getSongsForPlaylist(
                                      int.parse(widget.systemKeyOrId!),
                                    );
                                  }
                                  // Add entire songs list to queue
                                  final newSongsList = List<SongsModel>.from(
                                    musicService.songs,
                                  );

                                  for (var song in _songs) {
                                    final existingIndex = newSongsList
                                        .indexWhere((s) => s.id == song.id);
                                    if (existingIndex == -1) {
                                      newSongsList.add(song);
                                    }
                                  }

                                  musicService.setPlaylist(
                                    newSongsList,
                                    autoPlay: false,
                                  );
                                } else {
                                  final newSongsList = List<SongsModel>.from(
                                    musicService.songs,
                                  );

                                  final existingIndex = newSongsList.indexWhere(
                                    (song) => song.id == widget.currentSong!.id,
                                  );

                                  if (existingIndex == -1) {
                                    newSongsList.add(widget.currentSong!);
                                    musicService.setPlaylist(
                                      newSongsList,
                                      autoPlay: false,
                                    );
                                  }
                                }

                                Navigator.pop(context);
                              } else if (songItem.title ==
                                  S.of(context).addToPlaylist) {
                                if (widget.from == 'playlist') {
                                  List<SongsModel> _songs = [];
                                  final _repo = locator<PlaylistRepository>();
                                  if (widget.isSystemPlaylist) {
                                    log(
                                      'Fetching songs for system playlist ${widget.systemKeyOrId}',
                                    );
                                    _songs = await _repo
                                        .getSongsForSystemPlaylist(
                                          widget.systemKeyOrId ?? '',
                                        );
                                  } else {
                                    log(
                                      'Fetching songs for system playlist ${widget.systemKeyOrId}',
                                    );
                                    _songs = await _repo.getSongsForPlaylist(
                                      int.parse(widget.systemKeyOrId!),
                                    );
                                  }
                                  // Show playlist bottom sheet with entire songs list
                                  if (mounted) {
                                    _showPlaylistBottomSheetWithSongs(
                                      context,
                                      _songs,
                                    );
                                  }
                                } else {
                                  _showPlaylistBottomSheet(
                                    context,
                                    widget.currentSong,
                                  );
                                }
                              } else if (songItem.title ==
                                  S.of(context).deleteSong) {
                                if (widget.from == 'playlist') {
                                  // Remove song from current playlist
                                  if (widget.currentSong != null) {
                                    try {
                                      // Use PlaylistBloc event instead of direct repository call
                                      // This automatically handles state updates
                                      final playlistBloc = context
                                          .read<PlaylistBloc>();
                                      playlistBloc.add(
                                        PlaylistEvent.removeSongFromPlaylist(
                                          int.parse(widget.systemKeyOrId!),
                                          widget.currentSong!.id!,
                                        ),
                                      );

                                      // Show success message
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Song removed from playlist',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      // Show error message
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to remove song: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }

                                    // Close the menu to refresh the view
                                    Navigator.pop(context);
                                  }
                                } else {
                                  // Handle delete song from library
                                  // Show confirmation dialog and delete song file
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete Song'),
                                      content: Text(
                                        'Are you sure you want to delete "${widget.currentSong?.title}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {

                                            Navigator.pop(
                                              context,
                                            ); // Close dialog

                                            // Remove song from app database only
                                            if (widget.currentSong != null) {
                                              try {
                                                final songsBloc = context
                                                    .read<SongsBloc>();

                                                // Remove from database only (not from device storage)
                                                songsBloc.add(
                                                  SongsEvent.removeSong(
                                                    widget.currentSong!.id!,
                                                  ),
                                                );

                                                // Show success message
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Song removed from library',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              } catch (e) {
                                                // Show error message
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Failed to remove song: $e',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }

                                            Navigator.pop(
                                              context,
                                            ); // Close menu
                                          },
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          if (showDivider)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15.w,
                                vertical: 10.h,
                              ),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.black.withValues(alpha: .1),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
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
                    margin: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 8.h,
                    ),
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
          SizedBox(height: 25.h),
        ],
      ),
    );
  }

  void _showPlaylistBottomSheet(BuildContext context, SongsModel? currentSong) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      isScrollControlled: true,
      builder: (_) => PlaylistBottomSheet(songId: currentSong!.id!),
    );
  }

  void _showPlaylistBottomSheetWithSongs(
    BuildContext context,
    List<SongsModel> songs,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      isScrollControlled: true,
      builder: (_) => PlaylistBottomSheet(songsList: songs),
    );
  }
}
