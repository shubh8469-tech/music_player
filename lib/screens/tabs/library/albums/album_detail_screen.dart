import 'dart:developer' as logS;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/commonWidgets/app_bar_with_icon_title.dart';
import 'package:music_app/features/albums/bloc/album_bloc.dart';
import 'package:music_app/features/albums/domain/entities/album.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/features/music_player/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/bloc/music_player_state.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/bottom_button_two.dart';
import '../../../../commonWidgets/common_functions.dart';
import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/song_menu_screen.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/albums/domain/repositories/album_repository.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../model/song_menu_model.dart';
import '../../../../utills/globals.dart';
import '../../../../utills/snack_bar.dart';
import '../../../common/commonTapProvider.dart';
import '../../../play_song/playing_song_screen.dart';
import '../widgets/mini_player_bar.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album album;
  const AlbumDetailScreen({super.key, required this.album});

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final _repo = locator<AlbumRepository>();
  final musicService = MusicPlayerService();

  List<SongsModel> _songs = [];
  List<SongsModel> _baseSongs = [];
  late Album _currentAlbum;

  // Sort options without album option
  late final List<SongMenuItem> _albumSongSortByItems;
  int selectedIndex = 0;
  int selectedOrder = 0;

  @override
  void initState() {
    super.initState();
    _currentAlbum = widget.album;
    // Create sort items without album option (index 2 in sortBFrom what we pull via MetadataGod, the audio tags only give us text fields (artist, album, albumArtist, etc.)—no stable artist IDs. Common tag standards (ID3, Vorbis Comments, MP4) don’t include a universal identifier unless someone manually embeds extras like MusicBrainz IDs, and our importer doesn’t read those. So the only consistent value we can rely on right now is the album-artist string. If we need something stronger, we’d have to add optional support for IDs from third-party tag fields (e.g., MusicBrainz TXXX frames) and fall back to the text metadata when they’re absent.yItems)
    _albumSongSortByItems = List.from(sortByItems)..removeAt(2);
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

  void _sortSongs(int sortIndex, int sortOrder) {
    List<SongsModel> sortedSongs = List.from(_songs);
    final isAscending = sortOrder == 0;

    // Adjust sortIndex since we removed album option (original index 2)
    // 0: Song Name -> 0
    // 1: Artist -> 1
    // 2: Folder -> 3 (original)
    // 3: Added Time -> 4 (original)
    // 4: Play Count -> 5 (original)
    // 5: Year -> 6 (original)
    int adjustedIndex = sortIndex;
    if (sortIndex >= 2) {
      adjustedIndex = sortIndex + 1; // Skip album option
    }

    switch (adjustedIndex) {
      case 0: // Song Name
        sortedSongs.sort(
          (a, b) => isAscending
              ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
              : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case 1: // Artist
        sortedSongs.sort((a, b) {
          final aArtist = a.artist == '<unknown>'
              ? 'zzz'
              : a.artist.toLowerCase();
          final bArtist = b.artist == '<unknown>'
              ? 'zzz'
              : b.artist.toLowerCase();
          return isAscending
              ? aArtist.compareTo(bArtist)
              : bArtist.compareTo(aArtist);
        });
        break;
      case 3: // Folder
        sortedSongs.sort(
          (a, b) => isAscending
              ? a.folder!.toLowerCase().compareTo(b.folder!.toLowerCase())
              : b.folder!.toLowerCase().compareTo(a.folder!.toLowerCase()),
        );
        break;
      case 4: // Added Time
        sortedSongs.sort(
          (a, b) => isAscending
              ? a.createdTime.compareTo(b.createdTime)
              : b.createdTime.compareTo(a.createdTime),
        );
        break;
      case 5: // Play Count
        sortedSongs.sort(
          (a, b) => isAscending
              ? a.playCount.compareTo(b.playCount)
              : b.playCount.compareTo(a.playCount),
        );
        break;
      case 6: // Year
        sortedSongs.sort((a, b) {
          final aYear = a.year ?? 0;
          final bYear = b.year ?? 0;
          // Songs without year go to the end
          if (aYear == 0 && bYear == 0) return 0;
          if (aYear == 0) return 1;
          if (bYear == 0) return -1;
          return isAscending ? aYear.compareTo(bYear) : bYear.compareTo(aYear);
        });
        break;
      default:
        break;
    }

    setState(() {
      _songs = sortedSongs;
    });
  }

  Widget _songTile(
    List<SongsModel> list,
    int index,
    MusicPlayerState playerState,
  ) {
    final song = list[index];
    final isCurrent = song.id == playerState.currentSongId;
    final isPlaying = playerState.isPlaying;

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
            cardWidth: 50.h,
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
            songLengthRequired: true,
            songLength: formatDuration(song.duration),
            trailingIconWidth: 3.w,
            trailingMargin: 10.w,
            isGifLoad: isCurrent,
            isPlaying: isPlaying,
            onTap: context.watch<HoldTheTapFor>().isHoldingSongPLay
                ? null
                : () async {
                    context.read<HoldTheTapFor>().startHoldingSongPlay();
                    final current = musicService.currentSong;
                    if (current != null &&
                        current.id == song.id &&
                        musicService.isPlaying) {
                      context.push(
                        '/dashboard/playing',
                        extra: PlayingSongArgs(songs: musicService.songs),
                      );
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
                    final songId = song.id;
                    setState(() {
                      _songs.removeWhere((s) => s.id == songId);
                      _baseSongs.removeWhere((s) => s.id == songId);
                      _currentAlbum = Album(
                        id: _currentAlbum.id,
                        name: _currentAlbum.name,
                        artist: _currentAlbum.artist,
                        songCount: _currentAlbum.songCount - 1,
                        year: _currentAlbum.year,
                        artworkPath: _currentAlbum.artworkPath,
                        createdTime: _currentAlbum.createdTime,
                        updatedTime: _currentAlbum.updatedTime,
                        cachedArtistNames: _currentAlbum.cachedArtistNames,
                      );
                    });

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
  }

  // Custom sort by bottom sheet for album songs
  Widget _buildSortByBottomSheet() {
    int localSelectedIndex = selectedIndex;
    int localSelectedOrder = selectedOrder;

    return StatefulBuilder(
      builder: (context, setModalState) {
        // Handle keyboard visibility and safe area
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        final viewPadding = MediaQuery.of(context).viewPadding.bottom;
        final bottomPadding = viewInsets > 0
            ? viewInsets + 16.h
            : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

        return Container(
          padding: EdgeInsets.only(
            top: 10.h,
            bottom: bottomPadding,
            left: 10.w,
            right: 10.w,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(Assets.svgIcLineBottom),
              SizedBox(height: 20.h),
              Texts(
                'Sort By',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                fontFamily: AppFonts.inter,
              ),
              SizedBox(height: 10.h),

              // Sort Type Options
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(_albumSongSortByItems.length, (index) {
                    var songItem = _albumSongSortByItems[index];
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity(
                        horizontal: 0.w,
                        vertical: -2.h,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      title: Texts(
                        songItem.title,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFonts.inter,
                        color: index == localSelectedIndex
                            ? AppColors.primaryOrange
                            : AppColors.textColor,
                      ),
                      trailing: SvgPicture.asset(
                        index == localSelectedIndex
                            ? Assets.svgIcRadioCheckl
                            : Assets.svgIcRadioUncheck,
                        height: 20.h,
                        width: 20.w,
                      ),
                      onTap: () {
                        setModalState(() {
                          localSelectedIndex = index;
                        });
                      },
                    );
                  }),

                  // Divider
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 16.w,
                    ),
                    child: Divider(
                      color: AppColors.textColor.withOpacity(0.2),
                      thickness: 1,
                    ),
                  ),

                  // Ascending Option
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity(
                      horizontal: 0.w,
                      vertical: -2.h,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    title: Texts(
                      'Ascending',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppFonts.inter,
                      color: localSelectedOrder == 0
                          ? AppColors.primaryOrange
                          : AppColors.textColor,
                    ),
                    trailing: SvgPicture.asset(
                      localSelectedOrder == 0
                          ? Assets.svgIcRadioCheckl
                          : Assets.svgIcRadioUncheck,
                      height: 20.h,
                      width: 20.w,
                    ),
                    onTap: () {
                      setModalState(() {
                        localSelectedOrder = 0;
                      });
                    },
                  ),

                  // Descending Option
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity(
                      horizontal: 0.w,
                      vertical: -2.h,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    title: Texts(
                      'Descending',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppFonts.inter,
                      color: localSelectedOrder == 1
                          ? AppColors.primaryOrange
                          : AppColors.textColor,
                    ),
                    trailing: SvgPicture.asset(
                      localSelectedOrder == 1
                          ? Assets.svgIcRadioCheckl
                          : Assets.svgIcRadioUncheck,
                      height: 20.h,
                      width: 20.w,
                    ),
                    onTap: () {
                      setModalState(() {
                        localSelectedOrder = 1;
                      });
                    },
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: BottomButtonTwo(
                  leftBtnTitle: S.of(context).cancel,
                  rightBtnTitle: "Done",
                  lefBtnTap: () {
                    Navigator.pop(context);
                  },
                  rightBtnTap: () {
                    setState(() {
                      selectedIndex = localSelectedIndex;
                      selectedOrder = localSelectedOrder;
                    });
                    _sortSongs(localSelectedIndex, localSelectedOrder);
                  },
                ),
              ),
              SizedBox(height: 25.h),
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
        appBar: AppBarWithIconTitle(
          title: _currentAlbum.name,
          backgroundColor: AppColors.primaryOrange,
          titleColor: AppColors.white,
          centerTitle: false,
          onBack: () => context.pop(),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              BlocBuilder<MusicPlayerBloc, MusicPlayerState>(
                buildWhen: (prev, curr) =>
                    prev.songs != curr.songs ||
                    prev.currentSongId != curr.currentSongId ||
                    prev.isPlaying != curr.isPlaying,
                builder: (context, playerState) {
                  final albumArtworkPath =
                      (_currentAlbum.artworkPath?.isNotEmpty ?? false)
                          ? _currentAlbum.artworkPath!
                          : Assets.svgAlbum;
                  final hasAny = playerState.songs.isNotEmpty;
                  final showMiniPlayer = hasAny;

                  return Padding(
                    padding: EdgeInsets.only(
                      left: 20.w,
                      right: 20.w,
                      // top: 27.h,
                      bottom: showMiniPlayer
                          ? 91.h
                          : 3.h, // Space for MiniPlayerBar (which includes system nav bar padding)
                    ),
                    child: SizedBox(
                      height: double.infinity,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(height: 25.h),
                            GradientCard(
                              height: 150.h,
                              width: 150.w,
                              colors: [
                                AppColors.mildOrange.withValues(alpha: 0.21),
                                AppColors.primaryOrange,
                              ],
                              borderRadius: 13.r,
                              iconAsset: albumArtworkPath,
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
                              maxLines: 1,
                            ),
                            // if (_currentAlbum.artist != null) ...[
                            //   SizedBox(height: 4.h),
                            //   Texts(
                            //     _currentAlbum.artist!,
                            //     fontSize: 14.sp,
                            //     fontWeight: AppFontWeights.regular,
                            //     fontFamily: AppFonts.inter,
                            //     color: AppColors.mediumDarkGrey,
                            //     align: TextAlign.center,
                            //   ),
                            // ],
                            SizedBox(height: 25.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: context.watch<HoldTheTapFor>().isHoldingShuffle
                                      ? null
                                      : () async {
                                          try {
                                            if (_songs.isEmpty) return;

                                            context.read<HoldTheTapFor>().startHoldingShuffle();

                                            if (musicService.currentIndex < 0) {
                                              await musicService.setPlaylist(
                                                _songs,
                                                autoPlay: false,
                                                startIndex: 0,
                                              );
                                              await musicService.play();
                                            } else {
                                              context.push(
                                                '/dashboard/playing',
                                                extra: PlayingSongArgs(songs: _songs),
                                              );
                                              await musicService.setShufflePlaylist(
                                                _songs,
                                                autoPlay: false,
                                              );
                                              await musicService.ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();
                                              await musicService.player.currentIndexStream.firstWhere(
                                                (idx) => idx != null && idx != 0,
                                              );
                                              await musicService.play();
                                            }

                                            logS.log("Shuffle Play started");
                                          } catch (e) {
                                            logS.log("Shuffle error in AlbumDetailScreen: $e");
                                          }
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
                                  onTap: context.watch<HoldTheTapFor>().isHoldingPlay
                                      ? null
                                      : () async {
                                          try {
                                            if (_baseSongs.isEmpty) return;

                                            context.read<HoldTheTapFor>().startHoldingPlay();

                                            if (musicService.isPlaying) {
                                              context.push(
                                                '/dashboard/playing',
                                                extra: PlayingSongArgs(songs: _songs),
                                              );
                                            } else if (musicService.currentIndex >= 0) {
                                              context.push(
                                                '/dashboard/playing',
                                                extra: PlayingSongArgs(songs: _songs),
                                              );
                                              await musicService.play();
                                            } else {
                                              await musicService.ensureShuffleOff();
                                              await musicService.setPlaylist(
                                                List<SongsModel>.from(_baseSongs),
                                                startIndex: 0,
                                                autoPlay: true,
                                              );
                                            }
                                          } catch (e) {
                                            logS.log("Play error in AlbumDetailScreen: $e");
                                          }
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
                                    // Navigate to select song screen for album management
                                    context.push(
                                      '/dashboard/select-song',
                                      extra: {
                                        'album': _currentAlbum,
                                        'songs': _songs,
                                        'isSystemPlaylist': false,
                                      },
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(Assets.svgSongsCount),
                                      SizedBox(width: 8.w),
                                      SizedBox(
                                        height: 38.h, // Increase height so padding doesn't zero it out
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8.h), // Leave some room for the line
                                          child: VerticalDivider(
                                            color: AppColors.mediumDarkGrey.withOpacity(0.5),
                                            width: 1.w,      // Total space the widget occupies
                                            thickness: 1.2.w,   // The actual thickness of the line
                                          ),
                                        ),
                                      ),
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

                                Spacer(),

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
                                      builder: (_) => _buildSortByBottomSheet(),
                                    );
                                  },
                                  child: SvgPicture.asset(Assets.svgFilter),
                                ),
                              ],
                            ),

                            SizedBox(height: 25.h),

                            if (_songs.isEmpty) ...{
                              Center(
                                child: Texts(
                                  'No songs available',
                                  fontSize: 16,
                                  fontWeight: AppFontWeights.regular,
                                  fontFamily: AppFonts.inter,
                                ),
                              ),
                            },
                            Column(
                              children: List.generate(_songs.length, (index) {
                                return _songTile(_songs, index, playerState);
                              }),
                            ),
                            // SizedBox(height: 200.h),
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
      ),
    );
  }
}
