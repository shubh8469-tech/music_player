import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:just_audio/just_audio.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

import '../app_router.dart';
import '../core/di/injection.dart';
import '../features/albums/domain/repositories/album_repository.dart';
import '../features/artists/domain/repositories/artist_repository.dart';
import '../features/playlists/bloc/playlist_bloc.dart';
import '../features/playlists/domain/entities/playlist.dart' as domain;
import '../features/playlists/domain/repositories/playlist_repository.dart';
import '../features/songs/bloc/songs_bloc.dart';
import '../generated/assets.dart';
import '../l10n/l10n.dart';
import '../model/song_menu_model.dart';
import '../screens/common/image_crop_screen.dart';
import '../screens/play_song/widget/playback_speed_bottom_sheet.dart';
import '../screens/play_song/widget/playlist_bottomsheet.dart';
import '../screens/tabs/music_service.dart';
import '../themes/color.dart';
import '../utills/snack_bar.dart';
import 'MusicListTile.dart';
import 'common_functions.dart';

class SongMenuScreen extends StatefulWidget {
  final List<SongMenuItem> songMenuList;
  final bool isPlaying;
  final List<SongsModel>? songsList;
  final SongsModel? currentSong;
  final int? songIndex;
  final bool isSystemPlaylist;
  final String? systemKeyOrId;
  final String? from;
  final double maxHeight;
  final VoidCallback? onSongDeleted;
  final domain.Playlist? playlist;
  final String? playlistIconAsset;
  final List<Color>? playlistGradientColors;

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
    this.onSongDeleted,
    this.playlist,
    this.playlistIconAsset,
    this.playlistGradientColors,
  });

  @override
  State<SongMenuScreen> createState() => _SongMenuScreenState();
}

class _SongMenuScreenState extends State<SongMenuScreen> {
  bool keepScreenOn = false;

  @override
  Widget build(BuildContext context) {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      padding: EdgeInsets.only(top: 10.h, bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 10.h),
          Flexible(
            child: Column(
              children: [
                if (widget.from == 'playlist' && widget.playlist != null)
                  // Display playlist information
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
                      noLogoGradientColor: widget.playlistGradientColors ?? [AppColors.primaryOrange.withValues(alpha: 0.21), AppColors.primaryOrange],
                      cardIconAsset: widget.playlistIconAsset ?? Assets.svgMusicIcon,
                      cardIconSize: 32.r,
                      isSvgCardIcon: (widget.playlistIconAsset ?? '').contains('.svg'),
                      title: widget.playlist!.name,
                      subtitle: '${widget.playlist!.songCount} Songs',
                      trailingIconAsset: Assets.svgIcShare,
                      trailingIconHeight: 25.h,
                      trailingIconWidth: 25.w,
                      trailingMargin: 2.w,
                      onTap: () {
                        showSnackBar(context, () {}, message: 'Share playlist feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
                      },
                      onPlayTap: () {
                        showSnackBar(context, () {}, message: 'Play playlist feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
                      },
                    ),
                  )
                else if (widget.currentSong != null)
                  // Display song information
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
                      noLogoGradientColor: [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.primaryOrange],
                      cardIconAsset: widget.currentSong?.artwork_path ?? '',
                      cardIconSize: 32.r,
                      title: widget.currentSong?.title ?? '',
                      subtitle: formatDuration(widget.currentSong?.duration ?? 0),
                      trailingIconAsset: Assets.svgIcShare,
                      trailingIconHeight: 25.h,
                      trailingIconWidth: 25.w,
                      trailingMargin: 2.w,
                      onTap: () {
                        showSnackBar(context, () {}, message: 'Share song feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
                      },
                      onPlayTap: () {
                        showSnackBar(context, () {}, message: 'Play song feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
                      },
                      onInfoTap: () {
                        showSnackBar(context, () {}, message: 'Song info feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
                      },
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
                      if (widget.from == 'playlist') {
                        // Dividers for playlist menu
                        dividerAfterTitles = [S.of(context).addToPlaylist, S.of(context).changeCover];
                      } else if (widget.isPlaying) {
                        dividerAfterTitles = [S.of(context).goToArtist, S.of(context).keepScreenOn, S.of(context).changeCover];
                      } else {
                        dividerAfterTitles = [S.of(context).addToPlaylist, S.of(context).goToArtist, S.of(context).changeCover];
                      }
                      final showDivider = dividerAfterTitles.contains(songItem.title);
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(horizontal: 0.w, vertical: 0.h),
                            leading: SvgPicture.asset(songItem.icon, height: 24, width: 24),
                            title: Texts(songItem.title, fontSize: 16.sp, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
                            trailing: songItem.title == S.of(context).keepScreenOn
                                ? IconButton(
                                    icon: SvgPicture.asset(keepScreenOn ? Assets.svgIcSwitchOn : Assets.svgIcSwitchOff),
                                    onPressed: () {
                                      setState(() {
                                        keepScreenOn = !keepScreenOn;
                                      });
                                    },
                                  )
                                : null,
                            onTap: () async {
                              final localization = S.of(context);
                              var musicService = MusicPlayerService();
                              if (songItem.title == localization.keepScreenOn) {
                                setState(() {
                                  keepScreenOn = !keepScreenOn;
                                });
                                return;
                              } else if (songItem.title == localization.editDetails) {
                                Navigator.pop(context);
                                final selectedSong =
                                    widget.currentSong ??
                                    ((widget.songsList != null && widget.songIndex != null && widget.songIndex! >= 0 && widget.songIndex! < widget.songsList!.length)
                                        ? widget.songsList![widget.songIndex!]
                                        : null);

                                if (selectedSong != null) {
                                  context.push('/dashboard/edit-song', extra: selectedSong);
                                } else {
                                  showSnackBar(context, () {}, message: 'Unable to edit this song right now', alertBannerLocation: AlertBannerLocation.bottom);
                                }
                                return;
                              } else if (songItem.title == localization.play) {
                                // Handle Play for playlist
                                if (widget.from == 'playlist') {
                                  // Close the bottom sheet first
                                  Navigator.pop(context);

                                  List<SongsModel> _songs = [];
                                  final _repo = locator<PlaylistRepository>();
                                  try {
                                    if (widget.isSystemPlaylist) {
                                      log('Playing songs from system playlist ${widget.systemKeyOrId}');
                                      _songs = await _repo.getSongsForSystemPlaylist(widget.systemKeyOrId ?? '');
                                    } else {
                                      log('Playing songs from playlist ${widget.systemKeyOrId}');
                                      _songs = await _repo.getSongsForPlaylist(int.parse(widget.systemKeyOrId!));
                                    }

                                    if (_songs.isEmpty) {
                                      if (mounted) {
                                        showSnackBar(context, () {}, message: "Playlist contains no songs", alertBannerLocation: AlertBannerLocation.bottom);
                                      }
                                      return;
                                    }

                                    // Set playlist and play
                                    await musicService.setPlaylist(_songs, startIndex: 0);
                                    await musicService.play();

                                    if (mounted) {
                                      showSnackBar(context, () {}, message: "Playing ${_songs.length} songs", alertBannerLocation: AlertBannerLocation.bottom);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      showSnackBar(context, () {}, message: "Error playing playlist: $e", alertBannerLocation: AlertBannerLocation.bottom);
                                    }
                                  }
                                }
                              } else if (songItem.title == localization.speed) {
                                final rootContext = rootNavigatorKey.currentContext;
                                Navigator.pop(context);
                                if (rootContext != null) {
                                  Future.microtask(() {
                                    showModalBottomSheet(
                                      context: rootContext,
                                      backgroundColor: AppColors.white,
                                      isScrollControlled: true,
                                      builder: (_) => const PlaybackSpeedBottomSheet(),
                                    );
                                  });
                                }
                                return;
                              } else if (songItem.title == S.of(context).playNext) {
                                // ✅ NEW: Check if we're in queue context

                                if (widget.from == 'queue') {
                                  Navigator.pop(context);

                                  if (musicService.songs.isEmpty || widget.songIndex == null) {
                                    showSnackBar(context, () {}, message: 'Unable to move song', alertBannerLocation: AlertBannerLocation.bottom);
                                    return;
                                  }

                                  final currentIndex = musicService.currentIndex;
                                  final songIndex = widget.songIndex!;

                                  print('🎵 Queue Play Next: currentIndex=$currentIndex, songIndex=$songIndex');

                                  // Don't move if it's the currently playing song
                                  if (songIndex == currentIndex) {
                                    showSnackBar(context, () {}, message: 'Song is already playing', alertBannerLocation: AlertBannerLocation.bottom);
                                    return;
                                  }

                                  // Don't move if it's already next
                                  if (songIndex == currentIndex + 1) {
                                    showSnackBar(context, () {}, message: 'Song is already next in queue', alertBannerLocation: AlertBannerLocation.bottom);
                                    return;
                                  }

                                  // // ✅ CRITICAL FIX: Create mutable copy and perform the move
                                  // final mutableSongs = List<SongsModel>.from(musicService.songs);
                                  // final songToMove = mutableSongs.removeAt(songIndex);
                                  //
                                  // // Calculate insert position (right after current song)
                                  // final insertIndex = currentIndex + 1;
                                  //
                                  // // ✅ KEY FIX: Adjust insert index if we removed before current position
                                  // final adjustedInsertIndex = songIndex < insertIndex ? insertIndex - 1 : insertIndex;
                                  //
                                  // mutableSongs.insert(adjustedInsertIndex, songToMove);
                                  //
                                  // print('  Moving: $songIndex → $adjustedInsertIndex');
                                  //
                                  // // ✅ CRITICAL: Calculate new current index
                                  // // If we moved a song from BEFORE current position, current index shifts down by 1
                                  // // If we moved from AFTER, current index stays the same
                                  // int newCurrentIndex = currentIndex;
                                  // if (songIndex < currentIndex) {
                                  //   newCurrentIndex = currentIndex - 1;
                                  //   print('  Current index adjusted: $currentIndex → $newCurrentIndex');
                                  // }
                                  //
                                  // print('  New queue order:');
                                  // for (int i = 0; i < mutableSongs.length; i++) {
                                  //   final marker = i == newCurrentIndex ? '▶️' : i == adjustedInsertIndex ? '⏭️' : '  ';
                                  //   print('    $marker [$i] ${mutableSongs[i].title}');
                                  // }
                                  //
                                  // // ✅ CRITICAL: Use reorderSongInQueue for seamless update
                                  // try {
                                  //   // Use the reorder method which handles both platforms correctly
                                  //   await musicService.reorderSongInQueue(songIndex, adjustedInsertIndex);
                                  //
                                  //   print('✅ Queue updated successfully');
                                  //
                                  //   if (mounted) {
                                  //     showSnackBar(
                                  //       context,
                                  //           () {},
                                  //       message: '${songToMove.title} will play next',
                                  //       alertBannerLocation: AlertBannerLocation.bottom,
                                  //     );
                                  //   }
                                  // } catch (e) {
                                  //   print('❌ Error updating queue: $e');
                                  //   if (mounted) {
                                  //     showSnackBar(
                                  //       context,
                                  //           () {},
                                  //       message: 'Failed to move song',
                                  //       backgroundColor: Colors.red,
                                  //       alertBannerLocation: AlertBannerLocation.bottom,
                                  //     );
                                  //   }
                                  // }

                                  try {
                                    // Calculate insert position (right after current song)
                                    final insertIndex = currentIndex + 1;

                                    // ✅ KEY FIX: Adjust insert index if we're moving from before current
                                    final adjustedInsertIndex = songIndex < insertIndex ? insertIndex - 1 : insertIndex;

                                    print('  Moving: $songIndex → $adjustedInsertIndex');

                                    // Use the reorder method which handles both platforms correctly
                                    await musicService.reorderSongInQueue(songIndex, adjustedInsertIndex);

                                    print('✅ Queue updated successfully');

                                    if (mounted) {
                                      final songToMove = musicService.songs[adjustedInsertIndex];
                                      showSnackBar(context, () {}, message: '${songToMove.title} will play next', alertBannerLocation: AlertBannerLocation.bottom);
                                    }
                                  } catch (e) {
                                    print('❌ Error updating queue: $e');
                                    if (mounted) {
                                      showSnackBar(
                                        context,
                                        () {},
                                        message: 'Failed to move song',
                                        backgroundColor: Colors.red,
                                        alertBannerLocation: AlertBannerLocation.bottom,
                                      );
                                    }
                                  }

                                  return;
                                }
                                /* if (widget.from == 'queue') {
                                  Navigator.pop(context);

                                  if (musicService.songs.isEmpty || widget.songIndex == null) {
                                    showSnackBar(
                                      context,
                                          () {},
                                      message: 'Unable to move song',
                                      alertBannerLocation: AlertBannerLocation.bottom,
                                    );
                                    return;
                                  }

                                  final currentIndex = musicService.currentIndex;
                                  final songIndex = widget.songIndex!;

                                  print('🎵 Queue Play Next: currentIndex=$currentIndex, songIndex=$songIndex');

                                  // Don't move if it's the currently playing song
                                  if (songIndex == currentIndex) {
                                    showSnackBar(
                                      context,
                                          () {},
                                      message: 'Song is already playing',
                                      alertBannerLocation: AlertBangerLocation.bottom,
                                    );
                                    return;
                                  }

                                  // Don't move if it's already next
                                  if (songIndex == currentIndex + 1) {
                                    showSnackBar(
                                      context,
                                          () {},
                                      message: 'Song is already next in queue',
                                      alertBannerLocation: AlertBannerLocation.bottom,
                                    );
                                    return;
                                  }

                                  // ✅ CRITICAL FIX: Create mutable copy and perform the move
                                  final mutableSongs = List<SongsModel>.from(musicService.songs);
                                  final songToMove = mutableSongs.removeAt(songIndex);

                                  // Calculate insert position (right after current song)
                                  final insertIndex = currentIndex + 1;

                                  // ✅ KEY FIX: Adjust insert index if we removed before current position
                                  final adjustedInsertIndex = songIndex < insertIndex ? insertIndex - 1 : insertIndex;

                                  mutableSongs.insert(adjustedInsertIndex, songToMove);

                                  print('  Moving: $songIndex → $adjustedInsertIndex');

                                  // ✅ CRITICAL: Calculate new current index
                                  // If we moved a song from BEFORE current position, current index shifts down by 1
                                  // If we moved from AFTER, current index stays the same
                                  int newCurrentIndex = currentIndex;
                                  if (songIndex < currentIndex) {
                                    newCurrentIndex = currentIndex - 1;
                                    print('  Current index adjusted: $currentIndex → $newCurrentIndex');
                                  }

                                  print('  New queue order:');
                                  for (int i = 0; i < mutableSongs.length; i++) {
                                    final marker = i == newCurrentIndex ? '▶️' : i == adjustedInsertIndex ? '⏭️' : '  ';
                                    print('    $marker [$i] ${mutableSongs[i].title}');
                                  }

                                  // ✅ CRITICAL: Use reorderSongInQueue for seamless update
                                  try {
                                    // Use the reorder method which handles both platforms correctly
                                    await musicService.reorderSongInQueue(songIndex, adjustedInsertIndex);

                                    print('✅ Queue updated successfully');

                                    if (mounted) {
                                      showSnackBar(
                                        context,
                                            () {},
                                        message: '${songToMove.title} will play next',
                                        alertBannerLocation: AlertBannerLocation.bottom,
                                      );
                                    }
                                  } catch (e) {
                                    print('❌ Error updating queue: $e');
                                    if (mounted) {
                                      showSnackBar(
                                        context,
                                            () {},
                                        message: 'Failed to move song',
                                        backgroundColor: Colors.red,
                                        alertBannerLocation: AlertBannerLocation.bottom,
                                      );
                                    }
                                  }

                                  return;
                                }*/

                                // ✅ Handle Play Next for playlist (KEEP THIS CODE AS IS)
                                if (widget.from == 'playlist') {
                                  // Close the bottom sheet first
                                  Navigator.pop(context);

                                  List<SongsModel> _songs = [];
                                  final _repo = locator<PlaylistRepository>();
                                  try {
                                    if (widget.isSystemPlaylist) {
                                      log('Playing next songs from system playlist ${widget.systemKeyOrId}');
                                      _songs = await _repo.getSongsForSystemPlaylist(widget.systemKeyOrId ?? '');
                                    } else {
                                      log('Playing next songs from playlist ${widget.systemKeyOrId}');
                                      _songs = await _repo.getSongsForPlaylist(int.parse(widget.systemKeyOrId!));
                                    }

                                    if (_songs.isEmpty) {
                                      if (mounted) {
                                        showSnackBar(context, () {}, message: "Playlist contains no songs", alertBannerLocation: AlertBannerLocation.bottom);
                                      }
                                      return;
                                    }

                                    // Insert playlist songs after current song
                                    if (musicService.songs.isEmpty) {
                                      print('📀 Queue empty, starting playlist');
                                      await musicService.setPlaylist(_songs, startIndex: 0, autoPlay: true);
                                    } else {
                                      print('📀 Inserting playlist after current song');
                                      final currentIndex = musicService.currentIndex;
                                      final newSongsList = List<SongsModel>.from(musicService.songs);

                                      final insertIndex = currentIndex + 1;

                                      // Filter out songs already in queue
                                      final songsToAdd = _songs.where((song) {
                                        return !newSongsList.any((existingSong) => existingSong.id == song.id);
                                      }).toList();

                                      // Insert after current song
                                      newSongsList.insertAll(insertIndex, songsToAdd);

                                      print('✅ Inserted ${songsToAdd.length} songs at position $insertIndex');

                                      // ✅ CRITICAL FIX: Pass the current index to preserve playback
                                      await musicService.updateSongsInQueueWithIndex(newSongsList, currentIndex);
                                    }

                                    if (mounted) {
                                      // showSnackBar(context, () {}, message: "${_songs.length} songs added to play next", alertBannerLocation: AlertBannerLocation.bottom);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      // showSnackBar(context, () {}, message: "Error adding to play next: $e", alertBannerLocation: AlertBannerLocation.bottom);
                                    }
                                  }
                                } else {
                                  // Individual song
                                  if (musicService.songs.isEmpty) {
                                    print('🎵 Play Next: Queue empty, starting song');
                                    await musicService.setPlaylist([widget.currentSong!], startIndex: 0, autoPlay: true);
                                  } else {
                                    final currentIndex = musicService.currentIndex;
                                    final newSongsList = List<SongsModel>.from(musicService.songs);
                                    final insertIndex = currentIndex + 1;

                                    print('🎵 Play Next: Current index: $currentIndex, Insert at: $insertIndex');

                                    // Check if song already exists
                                    final existingIndex = newSongsList.indexWhere((song) => song.id == widget.currentSong!.id);

                                    if (existingIndex == currentIndex) {
                                      showSnackBar(context, () {}, message: 'Song is already playing', alertBannerLocation: AlertBannerLocation.bottom);
                                      Navigator.pop(context);
                                      return;
                                    }

                                    // Don't move if it's already next
                                    if (existingIndex == currentIndex + 1) {
                                      showSnackBar(context, () {}, message: 'Song is already next in queue', alertBannerLocation: AlertBannerLocation.bottom);
                                      Navigator.pop(context);
                                      return;
                                    }

                                    if (existingIndex != -1 && existingIndex != insertIndex) {
                                      print('  Song exists at index $existingIndex, moving to $insertIndex');
                                      // Remove from old position
                                      final songToMove = newSongsList.removeAt(existingIndex);

                                      // Adjust insert index if we removed a song before the insert point
                                      final adjustedInsertIndex = existingIndex < insertIndex ? insertIndex - 1 : insertIndex;
                                      newSongsList.insert(adjustedInsertIndex, songToMove);

                                      await musicService.reorderSongInQueue(existingIndex, adjustedInsertIndex);

                                      print('  Moved to adjusted index: $adjustedInsertIndex');
                                    } else if (existingIndex == -1) {
                                      print('  Song not in queue, inserting at $insertIndex');
                                      newSongsList.insert(insertIndex, widget.currentSong!);
                                    } else {
                                      print('  Song already at correct position');
                                    }

                                    // ✅ CRITICAL FIX: Calculate the correct current index after modifications
                                    final newCurrentIndex = existingIndex != -1 && existingIndex < insertIndex
                                        ? currentIndex - 1 // If we moved a song from before current, current stays same
                                        : currentIndex; // Otherwise current index is unchanged

                                    print('  New current index: $newCurrentIndex');

                                    // Update with explicit current index preservation
                                    // await musicService.reorderSongInQueue(existingIndex, adjustedInsertIndex);
                                    // await musicService.updateSongsInQueueWithIndex(newSongsList, newCurrentIndex);
                                  }

                                  if (mounted) {
                                    showSnackBar(context, () {}, message: '${widget.currentSong!.title} will play next', alertBannerLocation: AlertBannerLocation.bottom);
                                  }
                                  Navigator.pop(context);
                                }

                                /*if (widget.from == 'playlist') {
                                  // Close the bottom sheet first
                                  Navigator.pop(context);

                                  List<SongsModel> _songs = [];
                                  final _repo = locator<PlaylistRepository>();
                                  try {
                                    if (widget.isSystemPlaylist) {
                                      log('Playing next songs from system playlist ${widget.systemKeyOrId}');
                                      _songs = await _repo.getSongsForSystemPlaylist(widget.systemKeyOrId ?? '');
                                    } else {
                                      log('Playing next songs from playlist ${widget.systemKeyOrId}');
                                      _songs = await _repo.getSongsForPlaylist(int.parse(widget.systemKeyOrId!));
                                    }

                                    if (_songs.isEmpty) {
                                      if (mounted) {
                                        showSnackBar(context, () {}, message: "Playlist contains no songs", alertBannerLocation: AlertBannerLocation.bottom);
                                      }
                                      return;
                                    }

                                    // Insert playlist songs after current song
                                    if (musicService.songs.isEmpty) {
                                      print('📀 Queue empty, starting playlist');
                                      // No songs playing, start playing the playlist
                                      await musicService.setPlaylist(_songs, startIndex: 0, autoPlay: true);
                                      // await musicService.play();
                                    } else {
                                      print('📀 Inserting playlist after current song at index ${musicService.currentIndex + 1}');
                                      final currentIndex = musicService.currentIndex;
                                      final newSongsList = List<SongsModel>.from(musicService.songs);

                                      final insertIndex = currentIndex + 1; // Insert right after current

                                      print('  Insert index: $insertIndex');

                                      // Filter out songs that are already in the queue
                                      final songsToAdd = _songs.where((song) {
                                        return !newSongsList.any((existingSong) => existingSong.id == song.id);
                                      }).toList();

                                      // Insert the new songs after the current song
                                      newSongsList.insertAll(insertIndex, songsToAdd);

                                      print('✅ Inserted ${songsToAdd.length} songs at position $insertIndex');

                                      // await musicService.setPlaylist(newSongsList, startIndex: currentIndex >= 0 ? currentIndex : 0, autoPlay: false);
                                      await musicService.updateSongsInQueue(newSongsList);
                                    }

                                    if (mounted) {

                                      // showSnackBar(context, () {}, message: "${_songs.length} songs added to play next", alertBannerLocation: AlertBannerLocation.bottom);
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      // showSnackBar(context, () {}, message: "Error adding to play next: $e", alertBannerLocation: AlertBannerLocation.bottom);
                                    }
                                  }
                                } else {
                                  if (musicService.songs.isEmpty) {
                                    // No songs playing, just play this song
                                    print('🎵 Play Next: Queue empty, starting song');
                                    await musicService.setPlaylist([widget.currentSong!], startIndex: 0, autoPlay: true);
                                  } else {
                                    // Add individual song to play next (insert after current song)
                                    final currentIndex = musicService.currentIndex;
                                    final newSongsList = List<SongsModel>.from(musicService.songs);

                                    final insertIndex = currentIndex + 1; // Right after current
                                    print('  Insert index: $insertIndex');

                                    // Check if song is already in the queue
                                    final existingIndex = newSongsList.indexWhere((song) => song.id == widget.currentSong!.id);

                                    if (existingIndex != -1 && existingIndex != insertIndex) {
                                      print('  Song exists at index $existingIndex, moving to $insertIndex');
                                      // Song already exists, move it to the correct position
                                      final songToMove = newSongsList.removeAt(existingIndex);
                                      // final adjustedInsertIndex = existingIndex < insertIndex ? insertIndex - 1 : insertIndex;
                                      newSongsList.insert(insertIndex, songToMove);
                                    } else if (existingIndex == -1) {
                                      // Song not in queue, insert it
                                      print('  Song not in queue, inserting at $insertIndex');
                                      newSongsList.insert(insertIndex, widget.currentSong!);
                                    } else {
                                      // Song is already at the correct position
                                      print('  Song already at correct play next position');
                                    }

                                    await musicService.updateSongsInQueue(newSongsList);
                                  }

                                    // Update the music service with the new playlist

                                    // await musicService.setPlaylist(
                                    //   newSongsList,
                                    //   startIndex: currentIndex >= 0 ? currentIndex : 0,
                                    //   autoPlay: false, // ✅ CRITICAL: Don't play, just queue
                                    // );
                                    print('✅ Play Next: Song queued, continuing current playback');
                                    if (mounted) {
                                      showSnackBar(
                                        context,
                                            () {},
                                        message: '${widget.currentSong!.title} will play next',
                                        alertBannerLocation: AlertBannerLocation.bottom,
                                      );
                                    }
                                      Navigator.pop(context);
                                  }*/
                              } else if (songItem.title == S.of(context).addToQueue) {
                                if (widget.from == 'playlist') {
                                  List<SongsModel> _songs = [];
                                  final _repo = locator<PlaylistRepository>();
                                  if (widget.isSystemPlaylist) {
                                    log('Fetching songs for system playlist ${widget.systemKeyOrId}');
                                    _songs = await _repo.getSongsForSystemPlaylist(widget.systemKeyOrId ?? '');
                                  } else {
                                    log('Fetching songs for system playlist ${widget.systemKeyOrId}');
                                    _songs = await _repo.getSongsForPlaylist(int.parse(widget.systemKeyOrId!));
                                  }
                                  // Add entire songs list to queue
                                  final newSongsList = List<SongsModel>.from(musicService.songs);

                                  for (var song in _songs) {
                                    final existingIndex = newSongsList.indexWhere((s) => s.id == song.id);
                                    if (existingIndex == -1) {
                                      newSongsList.add(song);
                                    }
                                  }

                                  musicService.setPlaylist(newSongsList, autoPlay: false);

                                  showSnackBar(context, () {}, message: "${newSongsList.length} songs added to queue", alertBannerLocation: AlertBannerLocation.bottom);
                                } else {
                                  final newSongsList = List<SongsModel>.from(musicService.songs);

                                  final existingIndex = newSongsList.indexWhere((song) => song.id == widget.currentSong!.id);

                                  if (existingIndex == -1) {
                                    newSongsList.add(widget.currentSong!);
                                    musicService.setPlaylist(newSongsList, autoPlay: false);
                                    showSnackBar(context, () {}, message: "1 songs added to queue", alertBannerLocation: AlertBannerLocation.bottom);
                                  } else {
                                    showSnackBar(context, () {}, message: "Already added to queue", alertBannerLocation: AlertBannerLocation.bottom);
                                  }
                                }

                                Navigator.pop(context);
                              } else if (songItem.title == S.of(context).addToPlaylist) {
                                if (widget.from == 'playlist') {
                                  List<SongsModel> _songs = [];
                                  final _repo = locator<PlaylistRepository>();
                                  if (widget.isSystemPlaylist) {
                                    log('Fetching songs for system playlist ${widget.systemKeyOrId}');
                                    _songs = await _repo.getSongsForSystemPlaylist(widget.systemKeyOrId ?? '');
                                  } else {
                                    log('Fetching songs for system playlist ${widget.systemKeyOrId}');
                                    _songs = await _repo.getSongsForPlaylist(int.parse(widget.systemKeyOrId!));
                                  }
                                  // Show playlist bottom sheet with entire songs list
                                  if (mounted) {
                                    _showPlaylistBottomSheetWithSongs(context, _songs);
                                  }
                                } else {
                                  _showPlaylistBottomSheet(context, widget.currentSong);
                                }
                              } else if (songItem.title == S.of(context).changeCover) {
                                await _handleChangeCover(context);
                              } else if (songItem.title == S.of(context).deleteSong) {

                                if (widget.from == 'queue') {
                                  Navigator.pop(context);

                                  if (widget.currentSong == null || widget.songIndex == null) {
                                    showSnackBar(context, () {}, message: 'Unable to remove song', alertBannerLocation: AlertBannerLocation.bottom);
                                    return;
                                  }

                                  final currentIndex = musicService.currentIndex;
                                  final removeIndex = widget.songIndex!;

                                  print('🗑️ Removing song from queue at index $removeIndex');
                                  print('  Current index: $currentIndex');
                                  print('  Queue size: ${musicService.songs.length}');

                                  // ✅ CRITICAL: Capture playback state BEFORE any modifications
                                  final wasPlaying = musicService.isPlaying;
                                  final currentPosition = musicService.position;
                                  final isRemovingCurrent = removeIndex == currentIndex;

                                  // Create mutable copy
                                  final mutableSongs = List<SongsModel>.from(musicService.songs);
                                  final removedSong = mutableSongs[removeIndex];
                                  mutableSongs.removeAt(removeIndex);

                                  // Handle empty queue
                                  if (mutableSongs.isEmpty) {
                                    print('  Queue empty after removal');
                                    try {
                                      await musicService.player.stop();
                                      await musicService.player.seek(Duration.zero);


                                    } catch (e) {
                                      print('⚠️ Error stopping player: $e');
                                    }
                                    await musicService.stopAndClearQueue();
                                    if (context.mounted) {
                                      showSnackBar(context, () {}, message: 'Queue cleared', alertBannerLocation: AlertBannerLocation.bottom);
                                    }
                                    await Future.delayed(Duration(milliseconds: 250));
                                    // if (context.mounted) {
                                    //   context.pop();
                                    // }


                                    widget.onSongDeleted?.call();
                                    return;
                                  }

                                  try {
                                    if (isRemovingCurrent) {
                                      // ✅ Removing CURRENT song - play next song
                                      print('  Removing CURRENT song');
                                      final nextIndex = removeIndex < mutableSongs.length ? removeIndex : 0;
                                      print('  Playing next at index: $nextIndex');

                                      // Stop current playback first to avoid glitches
                                      await musicService.player.stop();

                                      // Set new playlist and start playing
                                      await musicService.setPlaylist(
                                          mutableSongs,
                                          startIndex: nextIndex,
                                          autoPlay: true
                                      );

                                      showSnackBar(context, () {}, message: 'Removed "${removedSong.title}"', alertBannerLocation: AlertBannerLocation.bottom);
                                    }
                                    else if (removeIndex < currentIndex) {
                                      // ✅ Removing BEFORE current - adjust index, keep playing
                                      print('  Removing BEFORE current');
                                      final newCurrentIndex = currentIndex - 1;
                                      print('  Adjusting index: $currentIndex → $newCurrentIndex');

                                      if (Platform.isAndroid) {
                                        final source = musicService.player.audioSource;
                                        // if (source is ConcatenatingAudioSource && !musicService.isShuffleEnabled) {
                                        if (source is ConcatenatingAudioSource) {
                                          print('  Android: Using seamless removeAt()');

                                          // Remove from audio source
                                          await source.removeAt(removeIndex);

                                          // Update internal list
                                          musicService.updateSongsList(mutableSongs);

                                        } else {
                                          // Shuffle enabled or fallback - rebuild
                                          print('  Android: Rebuilding (shuffle or fallback)');
                                          final currentSong = musicService.songs[currentIndex];
                                          await musicService.updateSongsInQueueWithIndex(mutableSongs, newCurrentIndex);

                                          if (wasPlaying && !musicService.isPlaying) {
                                            await musicService.seek(currentPosition, index: newCurrentIndex);
                                            await musicService.play();
                                          }
                                        }
                                      } else if (Platform.isIOS) {
                                        print('  iOS: Updating list only');
                                        // ✅ iOS: Use dedicated method channel call for seamless removal
                                        await musicService.removeFromQueueAtIndex(removeIndex, newCurrentIndex);
                                        musicService.updateSongsList(mutableSongs);
                                      }

                                      // showSnackBar(context, () {}, message: 'Removed "${removedSong.title}"', alertBannerLocation: AlertBannerLocation.bottom);
                                    }
                                    else {
                                      // ✅ Removing AFTER current - seamless update
                                      print('  Removing AFTER current');

                                      if (Platform.isAndroid) {
                                        final source = musicService.player.audioSource;
                                        if (source is ConcatenatingAudioSource && !musicService.isShuffleEnabled) {
                                          print('  Android: Using seamless removeAt()');

                                          // No need to pause for songs after current
                                          await source.removeAt(removeIndex);
                                          musicService.updateSongsList(mutableSongs);
                                        } else {
                                          print('  Android: Rebuilding (shuffle enabled)');
                                          await musicService.updateSongsInQueueWithIndex(mutableSongs, currentIndex);
                                        }
                                      } else if (Platform.isIOS) {
                                        print('  iOS: Updating list only');
                                        musicService.updateSongsList(mutableSongs);
                                      }

                                      // showSnackBar(context, () {}, message: 'Removed "${removedSong.title}"', alertBannerLocation: AlertBannerLocation.bottom);
                                    }

                                    print('✅ Song removed successfully');
                                    widget.onSongDeleted?.call();

                                  } catch (e) {
                                    print('❌ Error removing song: $e');

                                    // Restore playback on error
                                    if (wasPlaying && !musicService.isPlaying) {
                                      try {
                                        await musicService.play();
                                      } catch (playError) {
                                        print('❌ Failed to restore playback: $playError');
                                      }
                                    }

                                  }

                                  return;
                                }
                               /* if (widget.from == 'queue') {
                                  Navigator.pop(context);

                                  if (widget.currentSong == null || widget.songIndex == null) {
                                    showSnackBar(context, () {}, message: 'Unable to remove song', alertBannerLocation: AlertBannerLocation.bottom);
                                    return;
                                  }

                                  final currentIndex = musicService.currentIndex;
                                  final removeIndex = widget.songIndex!;

                                  print('🗑️ Removing song from queue at index $removeIndex');

                                  // ✅ CRITICAL: Get playback state BEFORE modifications
                                  final wasPlaying = musicService.isPlaying;
                                  final currentPosition = musicService.position;

                                  // Update queue
                                  final mutableSongs = List<SongsModel>.from(musicService.songs);
                                  mutableSongs.removeAt(removeIndex);

                                  if (mutableSongs.isEmpty) {
                                    await musicService.stopAndClearQueue();
                                    showSnackBar(context, () {}, message: 'Queue cleared', alertBannerLocation: AlertBannerLocation.bottom);
                                    // Notify parent to refresh
                                    widget.onSongDeleted?.call();
                                    return;
                                  }

                                  // Handle current song removal
                                  try {
                                    // Handle current song removal
                                    if (removeIndex == currentIndex) {
                                      final nextIndex = removeIndex < mutableSongs.length ? removeIndex : 0;
                                      print('  Removed current song, playing next at: $nextIndex');
                                      await musicService.setPlaylist(mutableSongs, startIndex: nextIndex, autoPlay: true);
                                    } else if (removeIndex < currentIndex) {
                                      // ✅ CRITICAL: Removing BEFORE current - use seamless update
                                      final newCurrentIndex = currentIndex - 1;
                                      print('  Removed BEFORE current: $currentIndex → $newCurrentIndex');

                                      if (Platform.isAndroid) {
                                        if (musicService.isShuffleEnabled) {
                                          print('  Android: Shuffle enabled - rebuilding');
                                          await musicService.updateSongsInQueueWithIndex(mutableSongs, newCurrentIndex);

                                          if (wasPlaying) {
                                            await musicService.seek(currentPosition, index: newCurrentIndex);
                                            await musicService.play();
                                          }
                                        } else {
                                          final source = musicService.player.audioSource;
                                          if (source is ConcatenatingAudioSource) {
                                            await source.removeAt(removeIndex);
                                            musicService.songs.clear();
                                            musicService.songs.addAll(mutableSongs);
                                            musicService.songsChangedController.add(List.from(musicService.songs));

                                            if (wasPlaying && !musicService.isPlaying) {
                                              await musicService.play();
                                            }
                                          } else {
                                            await musicService.updateSongsInQueueWithIndex(mutableSongs, newCurrentIndex);
                                            if (wasPlaying) {
                                              await musicService.seek(currentPosition, index: newCurrentIndex);
                                              await musicService.play();
                                            }
                                          }
                                        }
                                      } else if (Platform.isIOS) {
                                        musicService.songs.clear();
                                        musicService.songs.addAll(mutableSongs);
                                        musicService.songsChangedController.add(List.from(musicService.songs));
                                      }
                                    } else {
                                      // ✅ Removing AFTER current - seamless update
                                      print('  Removed AFTER current, keeping index: $currentIndex');

                                      if (Platform.isAndroid) {
                                        if (musicService.isShuffleEnabled) {
                                          // If shuffle enabled, rebuild to maintain shuffle order
                                          print('  Android: Shuffle enabled - rebuilding');
                                          await musicService.updateSongsInQueueWithIndex(mutableSongs, currentIndex);
                                        } else {
                                          // No shuffle - use seamless removal
                                          final source = musicService.player.audioSource;
                                          if (source is ConcatenatingAudioSource) {
                                            await source.removeAt(removeIndex);
                                            musicService.songs.clear();
                                            musicService.songs.addAll(mutableSongs);
                                            musicService.songsChangedController.add(List.from(musicService.songs));
                                          } else {
                                            await musicService.updateSongsInQueueWithIndex(mutableSongs, currentIndex);
                                          }
                                        }
                                      } else if (Platform.isIOS) {
                                        musicService.songs.clear();
                                        musicService.songs.addAll(mutableSongs);
                                        musicService.songsChangedController.add(List.from(musicService.songs));
                                      }
                                    }

                                    showSnackBar(context, () {}, message: 'Song removed from queue', alertBannerLocation: AlertBannerLocation.bottom);
                                    widget.onSongDeleted?.call();
                                  } catch (e) {
                                    print('❌ Error removing song: $e');
                                    showSnackBar(
                                      context,
                                      () {},
                                      message: 'Failed to remove song',
                                      backgroundColor: Colors.red,
                                      alertBannerLocation: AlertBannerLocation.bottom,
                                    );
                                  }

                                  return;
                                }*/

                                // ✅ EXISTING CODE: Handle other delete contexts

                                if (widget.from == 'playlist_in') {
                                  // Remove song from current playlist
                                  if (widget.currentSong != null) {
                                    try {
                                      // Use PlaylistBloc event instead of direct repository call
                                      // This automatically handles state updates

                                      if (widget.isSystemPlaylist) {
                                        showSnackBar(
                                          context,
                                          () {},
                                          message: 'Song cannot be deleted from system playlist',
                                          alertBannerLocation: AlertBannerLocation.bottom,
                                        );
                                      } else {
                                        final playlistBloc = context.read<PlaylistBloc>();
                                        playlistBloc.add(PlaylistEvent.removeSongFromPlaylist(int.parse(widget.systemKeyOrId!), widget.currentSong!.id!));

                                        final currentSongs = List<SongsModel>.from(musicService.songs);
                                        currentSongs.removeWhere((element) => element.id == widget.currentSong!.id);

                                        log('currentSongs ${currentSongs.length} ${widget.currentSong!.title}');
                                        await musicService.player.stop();
                                        if (currentSongs.isNotEmpty) {
                                          musicService.setPlaylist(currentSongs);
                                        } else {
                                          musicService.resetPlaylist(currentSongs);
                                        }
                                        // Show success message
                                        showSnackBar(context, () {}, message: 'Song removed from playlist', alertBannerLocation: AlertBannerLocation.bottom);
                                      }
                                    } catch (e) {
                                      // Show error message
                                      showSnackBar(
                                        context,
                                        () {},
                                        message: 'Failed to remove playlist: $e',
                                        backgroundColor: Colors.red,
                                        alertBannerLocation: AlertBannerLocation.bottom,
                                      );
                                    }

                                    // Close the menu to refresh the view
                                    Navigator.pop(context);
                                  }
                                } else if (widget.from == 'folder_in') {
                                  // Handle delete song from folder (delete file from system)
                                  if (widget.currentSong != null) {
                                    _showDeleteFromFolderConfirmation(context);
                                  }
                                } else {
                                  _showDeleteFromLibraryBottomSheet(context);
                                }
                              } else if (songItem.title == S.of(context).deletePlaylist) {
                                if (!widget.isSystemPlaylist) {
                                  _showDeletePlaylistBottomSheet(context);
                                } else {
                                  showSnackBar(context, () {}, message: 'System playlist cannot be deleted', alertBannerLocation: AlertBannerLocation.bottom);
                                }
                              } else if (songItem.title == S.of(context).goToAlbum) {
                                // Navigate to album detail screen
                                await _navigateToAlbum(context);
                              } else if (songItem.title == S.of(context).goToArtist) {
                                // Navigate to artist detail screen
                                await _navigateToArtist(context);
                              } else if (songItem.title == S.of(context).setAsRingtone) {
                                // Set as ringtone (Android only)
                                if (!Platform.isAndroid) {
                                  showSnackBar(context, () {}, message: 'Ringtone feature is only available on Android', alertBannerLocation: AlertBannerLocation.bottom);
                                  return;
                                }

                                if (widget.currentSong == null) {
                                  showSnackBar(context, () {}, message: 'No song selected', alertBannerLocation: AlertBannerLocation.bottom);
                                  return;
                                }

                                await _setAsRingtone(context);
                              } else if (songItem.title == S.of(context).hideSong) {
                                if (widget.currentSong?.id == null) {
                                  showSnackBar(
                                    context,
                                    () {},
                                    message: 'Unable to hide this song',
                                    backgroundColor: Colors.red,
                                    alertBannerLocation: AlertBannerLocation.bottom,
                                  );
                                  return;
                                }

                                try {
                                  context.read<SongsBloc>().add(SongsEvent.hideSong(widget.currentSong!.id!));

                                  if (mounted) {
                                    showSnackBar(context, () {}, message: '"${widget.currentSong!.title}" hidden', alertBannerLocation: AlertBannerLocation.bottom);
                                  }

                                  widget.onSongDeleted?.call();
                                } catch (e) {
                                  showSnackBar(
                                    context,
                                    () {},
                                    message: 'Failed to hide song: $e',
                                    backgroundColor: Colors.red,
                                    alertBannerLocation: AlertBannerLocation.bottom,
                                  );
                                } finally {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                }
                              }
                            },
                          ),
                          if (showDivider)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                              child: Divider(height: 1, thickness: 1, color: AppColors.black.withValues(alpha: .1)),
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
                      border: Border.all(color: AppColors.black.withValues(alpha: 0.10), width: 1),
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
              ],
            ),
          ),
          SizedBox(height: 25.h),
        ],
      ),
    );
  }

  Future<void> _handleChangeCover(BuildContext context) async {
    if (widget.currentSong == null) {
      showSnackBar(context, () {}, message: 'No song selected', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }

    final action = await _showChangeCoverSelectionSheet(context);
    if (!mounted || action == null) {
      return;
    }

    if (action == _ChangeCoverAction.localGallery) {
      await _handleLocalGalleryCover(context);
    } else if (action == _ChangeCoverAction.searchOnline) {
      showSnackBar(context, () {}, message: 'Search online feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<_ChangeCoverAction?> _showChangeCoverSelectionSheet(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return showModalBottomSheet<_ChangeCoverAction>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: bottomPadding),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32.r)),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48.w,
                    height: 4.h,
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(2.r)),
                  ),
                ),
                SizedBox(height: 18.h),
                Center(
                  child: Texts('Select cover from', fontSize: 18.sp, fontWeight: FontWeight.w600, fontFamily: AppFonts.inter, color: AppColors.textColor),
                ),
                SizedBox(height: 24.h),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 21.w,
                    height: 21.w,
                    decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12.r)),
                    child: SvgPicture.asset(Assets.svgLocalGallery, colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn), height: 16.h, width: 16.h),
                  ),
                  title: Texts('Local gallery', fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.textColor),
                  onTap: () {
                    Navigator.pop(sheetContext, _ChangeCoverAction.localGallery);
                  },
                ),
                Divider(color: Colors.black.withOpacity(0.08), height: 12.h, thickness: 0.8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 23.w,
                    height: 23.w,
                    decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r)),
                    child: SvgPicture.asset(Assets.svgSearch, colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn), height: 16.h, width: 16.h),
                  ),
                  title: Texts('Search online', fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.textColor),
                  onTap: () {
                    Navigator.pop(sheetContext, _ChangeCoverAction.searchOnline);
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
                    decoration: BoxDecoration(color: AppColors.black.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(24.r)),
                    child: Texts('Close', fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.textColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLocalGalleryCover(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);

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
        showSnackBar(context, () {}, message: 'Unable to read selected image', backgroundColor: Colors.red, alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      final croppedBytes = await Navigator.of(context).push<Uint8List>(MaterialPageRoute(builder: (_) => ImageCropScreen(imageBytes: bytes!), fullscreenDialog: true));

      if (croppedBytes == null) {
        return;
      }

      final optimizedBytes = await _optimizeImage(croppedBytes);
      final savedFile = await _persistCustomArtwork(optimizedBytes);
      await _cleanupPreviousCustomArtwork();
      await _updateSongArtworkPath(savedFile.path);

      if (!mounted) return;

      showSnackBar(context, () {}, message: 'Cover updated successfully', alertBannerLocation: AlertBannerLocation.bottom);

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, () {}, message: 'Failed to update cover: $e', backgroundColor: Colors.red, alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<Uint8List> _optimizeImage(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unsupported image format');
    }

    final maxDimension = 720;
    img.Image processed = decoded;
    final largestSide = decoded.width > decoded.height ? decoded.width : decoded.height;

    if (largestSide > maxDimension) {
      if (decoded.width >= decoded.height) {
        processed = img.copyResize(decoded, width: maxDimension, height: (decoded.height * maxDimension / decoded.width).round());
      } else {
        processed = img.copyResize(decoded, height: maxDimension, width: (decoded.width * maxDimension / decoded.height).round());
      }
    }

    final optimizedBytes = img.encodeJpg(processed, quality: 85);

    return Uint8List.fromList(optimizedBytes);
  }

  Future<File> _persistCustomArtwork(Uint8List bytes) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(documentsDir.path, 'covers'));

    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    final fileName = 'cover_${widget.currentSong?.id ?? DateTime.now().millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = p.join(coversDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _cleanupPreviousCustomArtwork() async {
    final existingPath = widget.currentSong?.artwork_path;
    if (existingPath == null || existingPath.isEmpty) {
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final coversDirPath = p.join(documentsDir.path, 'covers');
      if (p.isWithin(coversDirPath, existingPath)) {
        final existingFile = File(existingPath);
        if (await existingFile.exists()) {
          await existingFile.delete();
        }
      }
    } catch (e) {
      log('Failed to remove previous custom cover: $e');
    }
  }

  Future<void> _updateSongArtworkPath(String newPath) async {
    if (widget.currentSong?.id == null) {
      return;
    }

    context.read<SongsBloc>().add(SongsEvent.updateSongArtwork(songId: widget.currentSong!.id!, artworkPath: newPath));
  }

  void _showDeleteFromLibraryBottomSheet(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 10.h, bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.r)),
            ),
            SizedBox(height: 30.h),
            Texts(S.of(context).deleteSong, fontSize: 18.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.textColor),
            SizedBox(height: 30.h),
            Texts(
              'Are you sure you want to delete "${widget.currentSong?.title}"?',
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
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8.r)),
                      child: Center(
                        child: Texts(S.of(context).cancel, fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _deleteSongFile(context);
                    },
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(8.r)),
                      child: Center(
                        child: Texts(S.of(context).delete, fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.white),
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

  void _showDeletePlaylistBottomSheet(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 10.h, bottom: bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2.r)),
            ),
            SizedBox(height: 30.h),
            Texts(S.of(context).deletePlaylist, fontSize: 18.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.textColor),
            SizedBox(height: 30.h),
            Texts(
              'Are you sure you want to delete the playlist?',
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
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8.r)),
                      child: Center(
                        child: Texts(S.of(context).cancel, fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      final playlistBloc = context.read<PlaylistBloc>();
                      playlistBloc.add(PlaylistEvent.deletePlaylist(int.parse(widget.systemKeyOrId!)));
                      showSnackBar(context, () {}, message: 'Playlist deleted successfully', alertBannerLocation: AlertBannerLocation.bottom);
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(color: AppColors.primaryOrange, borderRadius: BorderRadius.circular(8.r)),
                      child: Center(
                        child: Texts(S.of(context).delete, fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.white),
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

  void _showPlaylistBottomSheet(BuildContext context, SongsModel? currentSong) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
      isScrollControlled: true,
      builder: (_) => PlaylistBottomSheet(songId: currentSong!.id!),
    );
  }

  void _showPlaylistBottomSheetWithSongs(BuildContext context, List<SongsModel> songs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
      isScrollControlled: true,
      builder: (_) => PlaylistBottomSheet(songsList: songs),
    );
  }

  void _showDeleteFromFolderConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.textColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Texts('Delete song?', fontSize: 18.sp, fontWeight: FontWeight.w600, fontFamily: AppFonts.inter, color: AppColors.white),
            SizedBox(height: 15.h),

            // Message
            Texts(
              'Are you sure you want to delete ${widget.currentSong?.title}?',
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              fontFamily: AppFonts.inter,
              color: AppColors.white.withValues(alpha: 0.9),
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
                      decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8.r)),
                      child: Center(
                        child: Texts('CANCEL', fontSize: 16.sp, fontWeight: FontWeight.w600, fontFamily: AppFonts.inter, color: AppColors.white),
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
                      await _deleteSongFile(context);
                    },
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primaryOrange, AppColors.mildOrange]),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Center(
                        child: Texts('DELETE', fontSize: 16.sp, fontWeight: FontWeight.w600, fontFamily: AppFonts.inter, color: AppColors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSongFile(BuildContext context) async {
    if (widget.currentSong == null) return;

    try {
      // Check and request storage permission
      bool hasPermission = await _checkAndRequestPermission();

      if (!hasPermission) {
        showSnackBar(context, () {}, message: 'Storage permission denied', backgroundColor: Colors.red, alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      // Delete the file from storage
      final file = File(widget.currentSong!.filePath);
      if (await file.exists()) {
        await file.delete();
        log('File deleted: ${widget.currentSong!.filePath}');
      }

      // Remove from database
      final songsBloc = context.read<SongsBloc>();
      songsBloc.add(SongsEvent.removeSong(widget.currentSong!.id!));

      // Show success message
      showSnackBar(context, () {}, message: 'Song deleted successfully', alertBannerLocation: AlertBannerLocation.bottom);

      // Call the callback to refresh the folder detail screen
      var musicService = MusicPlayerService();
      final currentSongs = List<SongsModel>.from(musicService.songs);
      currentSongs.removeWhere((element) => element.id == widget.currentSong!.id);

      await musicService.player.stop();
      if (currentSongs.isNotEmpty) {
        musicService.setPlaylist(currentSongs);
      } else {
        musicService.resetPlaylist(currentSongs);
      }

      widget.onSongDeleted?.call();

      // Close the menu
      Navigator.pop(context);
    } catch (e) {
      log('Error deleting song: $e');
      showSnackBar(context, () {}, message: 'Failed to delete song: $e', backgroundColor: Colors.red, alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    if (Platform.isAndroid) {
      // Check if we have manage external storage permission (Android 11+)
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // Request manage external storage permission
      PermissionStatus status = await Permission.manageExternalStorage.request();
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

  Future<void> _navigateToAlbum(BuildContext context) async {
    if (widget.currentSong == null) {
      showSnackBar(context, () {}, message: 'No song selected', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }

    try {
      final albumRepository = locator<AlbumRepository>();
      final albumName = widget.currentSong!.album;
      final artistName = 'Various Artists'; //widget.currentSong!.artist;

      if (albumName.isEmpty) {
        showSnackBar(context, () {}, message: 'Album information not available', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      // Get the album from the repository
      final album = await albumRepository.getAlbumByNameAndArtist(albumName, artistName);

      if (album != null) {
        // Close the menu
        Navigator.pop(context);

        // Navigate to album detail screen
        context.push('/dashboard/album-detail', extra: album);
      } else {
        showSnackBar(context, () {}, message: 'Album not found $albumName $artistName', alertBannerLocation: AlertBannerLocation.bottom);
      }
    } catch (e) {
      log('Error navigating to album: $e');
      showSnackBar(context, () {}, message: 'Error opening album: $e', backgroundColor: Colors.red, alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _navigateToArtist(BuildContext context) async {
    if (widget.currentSong == null) {
      showSnackBar(context, () {}, message: 'No song selected', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }

    try {
      final artistRepository = locator<ArtistRepository>();
      final artistName = widget.currentSong!.artist;

      if (artistName.isEmpty) {
        showSnackBar(context, () {}, message: 'Artist information not available', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      // Get the artist from the repository
      final artist = await artistRepository.getArtistByName(artistName);

      if (artist != null) {
        // Close the menu
        Navigator.pop(context);

        // Navigate to artist detail screen
        context.push('/dashboard/artist-detail', extra: artist);
      } else {
        showSnackBar(context, () {}, message: 'Artist not found', alertBannerLocation: AlertBannerLocation.bottom);
      }
    } catch (e) {
      log('Error navigating to artist: $e');
      showSnackBar(context, () {}, message: 'Error opening artist: $e', backgroundColor: Colors.red, alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _setAsRingtone(BuildContext context) async {
    if (widget.currentSong == null) {
      return;
    }

    if (!Platform.isAndroid) {
      return;
    }

    try {
      final song = widget.currentSong!;
      final filePath = song.filePath;

      if (filePath.isEmpty || !await File(filePath).exists()) {
        if (mounted) {
          showSnackBar(context, () {}, message: 'Song file not found', backgroundColor: Colors.red, alertBannerLocation: AlertBannerLocation.bottom);
        }
        return;
      }

      // Set the ringtone using platform channel
      const platform = MethodChannel('com.example.music_app/ringtone');
      try {
        // First check if we have WRITE_SETTINGS permission
        final hasPermission = await platform.invokeMethod('checkWriteSettingsPermission') as bool? ?? false;

        if (!hasPermission) {
          // Request permission by opening system settings
          if (mounted) {
            final shouldOpenSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Permission Required'),
                content: const Text('To set ringtone, please grant "Modify system settings" permission.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Open Settings')),
                ],
              ),
            );

            if (shouldOpenSettings == true) {
              // Open system settings for WRITE_SETTINGS permission
              await platform.invokeMethod('openWriteSettings');

              // Wait a bit for user to grant permission and return
              await Future.delayed(const Duration(milliseconds: 500));
            } else {
              // User cancelled
              if (mounted) {
                Navigator.pop(context);
              }
              return;
            }
          }
        }

        // Now set the ringtone (this will check permission again and set if available)
        final result = await platform.invokeMethod('setRingtone', {'filePath': filePath, 'title': song.title}) as Map<dynamic, dynamic>;

        final success = result['success'] as bool? ?? false;
        final setAsDefault = result['setAsDefault'] as bool? ?? false;
        final needsPermission = result['needsPermission'] as bool? ?? false;

        if (success) {
          if (mounted) {
            if (setAsDefault) {
              showSnackBar(context, () {}, message: '"${song.title}" set as ringtone successfully', alertBannerLocation: AlertBannerLocation.bottom);
            } else if (needsPermission) {
              showSnackBar(
                context,
                () {},
                message: 'Ringtone added. Please select "${song.title}" from Settings > Sound',
                alertBannerLocation: AlertBannerLocation.bottom,
              );
            } else {
              showSnackBar(context, () {}, message: '"${song.title}" added to ringtones', alertBannerLocation: AlertBannerLocation.bottom);
            }
            // Close the menu
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          }
        } else {
          throw Exception('Failed to set ringtone');
        }
      } on PlatformException catch (e) {
        throw Exception('Platform error: ${e.message}');
      }
    } catch (e) {
      log('Error setting ringtone: $e');
      if (mounted) {
        showSnackBar(context, () {}, message: 'Error setting ringtone: $e', backgroundColor: Colors.red, alertBannerLocation: AlertBannerLocation.bottom);
      }
    }
  }
}

enum _ChangeCoverAction { localGallery, searchOnline }
