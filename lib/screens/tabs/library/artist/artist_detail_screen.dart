import 'dart:developer' as logS;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/commonWidgets/app_bar_with_icon_title.dart';
import 'package:music_app/commonWidgets/common_functions.dart';
import 'package:music_app/features/artists/bloc/artist_bloc.dart';
import 'package:music_app/features/artists/domain/entities/artist.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/features/music_player/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/bloc/music_player_state.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/bottom_button_two.dart';
import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/song_menu_screen.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/albums/domain/entities/album.dart';
import '../../../../features/albums/domain/usecases/get_albums_by_artist.dart';
import '../../../../features/artists/domain/repositories/artist_repository.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../model/song_menu_model.dart';
import '../../../../utills/globals.dart';
import '../../../common/commonTapProvider.dart';
import '../../../play_song/playing_song_screen.dart';
import '../widgets/mini_player_bar.dart';

class ArtistDetailScreen extends StatefulWidget {
  final Artist artist;
  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final _repo = locator<ArtistRepository>();
  final _getAlbumsByArtist = locator<GetAlbumsByArtist>();
  final musicService = MusicPlayerService();

  List<SongsModel> _songs = [];
  List<SongsModel> _baseSongs = [];
  List<Album> _albums = [];
  late Artist _currentArtist;

  // Sort options without artist option
  late final List<SongMenuItem> _artistSongSortByItems;
  int selectedIndex = 0;
  int selectedOrder = 0;

  @override
  void initState() {
    super.initState();
    _currentArtist = widget.artist;
    // Create sort items without artist option (index 1 in sortByItems)
    _artistSongSortByItems = List.from(sortByItems)..removeAt(1);
    _loadSongs();
    _loadAlbums();
  }

  Future<void> _loadSongs() async {
    final songs = await _repo.getSongsForArtist(_currentArtist.id!);
    if (mounted) {
      setState(() {
        _songs = songs.cast<SongsModel>();
        _baseSongs = List<SongsModel>.from(_songs);
      });
    }
  }

  Future<void> _loadAlbums() async {
    try {
      final albums = await _getAlbumsByArtist(_currentArtist.name);
      logS.log("albums length -----> $albums");
      if (mounted) {
        setState(() {
          _albums = albums;
        });
      }
    } catch (e) {
      logS.log('Error loading albums: $e');
    }
  }

  Future<void> _refreshArtistData() async {
    // Refresh artist data to get updated song count
    final artistBloc = context.read<ArtistBloc>();
    artistBloc.add(const ArtistEvent.fetchAllArtists());
  }

  void _sortSongs(int sortIndex, int sortOrder) {
    List<SongsModel> sortedSongs = List.from(_songs);
    final isAscending = sortOrder == 0;

    // Adjust sortIndex since we removed artist option (original index 1)
    // 0: Song Name -> 0
    // 1: Album -> 2 (original)
    // 2: Folder -> 3 (original)
    // 3: Added Time -> 4 (original)
    // 4: Play Count -> 5 (original)
    // 5: Year -> 6 (original)
    int adjustedIndex = sortIndex;
    if (sortIndex >= 1) {
      adjustedIndex = sortIndex + 1; // Skip artist option
    }

    switch (adjustedIndex) {
      case 0: // Song Name
        sortedSongs.sort((a, b) => isAscending ? a.title.toLowerCase().compareTo(b.title.toLowerCase()) : b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case 2: // Album
        sortedSongs.sort((a, b) => isAscending ? a.album.toLowerCase().compareTo(b.album.toLowerCase()) : b.album.toLowerCase().compareTo(a.album.toLowerCase()));
        break;
      case 3: // Folder
        sortedSongs.sort((a, b) => isAscending ? a.folder!.toLowerCase().compareTo(b.folder!.toLowerCase()) : b.folder!.toLowerCase().compareTo(a.folder!.toLowerCase()));
        break;
      case 4: // Added Time
        sortedSongs.sort((a, b) => isAscending ? a.createdTime.compareTo(b.createdTime) : b.createdTime.compareTo(a.createdTime));
        break;
      case 5: // Play Count
        sortedSongs.sort((a, b) => isAscending ? a.playCount.compareTo(b.playCount) : b.playCount.compareTo(a.playCount));
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
            subtitle: song.album,
            trailingIconAsset: Assets.svgMenuIcon,
            songLengthRequired: true,
            songLength:formatDuration(song.duration),
            trailingIconHeight: 19.5.h,
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
                  systemKeyOrId: _currentArtist.id.toString(),
                  isSystemPlaylist: false,
                  from: 'artist_in',
                  onSongDeleted: () {
                    final songId = song.id;
                    setState(() {
                      _songs.removeWhere((s) => s.id == songId);
                      _baseSongs.removeWhere((s) => s.id == songId);
                      _currentArtist = Artist(
                        id: _currentArtist.id,
                        name: _currentArtist.name,
                        songCount: _currentArtist.songCount - 1,
                        albumCount: _currentArtist.albumCount,
                        createdTime: _currentArtist.createdTime,
                        updatedTime: _currentArtist.updatedTime,
                      );
                    });

                    Future.delayed(
                      const Duration(milliseconds: 800),
                      () async {
                        if (mounted) {
                          await _loadSongs();
                          _refreshArtistData();
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

  // Custom sort by bottom sheet for artist songs
  Widget _buildSortByBottomSheet() {
    int localSelectedIndex = selectedIndex;
    int localSelectedOrder = selectedOrder;

    return StatefulBuilder(
      builder: (context, setModalState) {
        // Handle keyboard visibility and safe area
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        final viewPadding = MediaQuery.of(context).viewPadding.bottom;
        final bottomPadding = viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

        return Container(
          padding: EdgeInsets.only(top: 10.h, bottom: bottomPadding, left: 10.w, right: 10.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(Assets.svgIcLineBottom),
              SizedBox(height: 20.h),
              Texts('Sort By', fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter),
              SizedBox(height: 10.h),

              // Sort Type Options
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(_artistSongSortByItems.length, (index) {
                    var songItem = _artistSongSortByItems[index];
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      title: Texts(
                        songItem.title,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFonts.inter,
                        color: index == localSelectedIndex ? AppColors.primaryOrange : AppColors.textColor,
                      ),
                      trailing: SvgPicture.asset(index == localSelectedIndex ? Assets.svgIcRadioCheckl : Assets.svgIcRadioUncheck, height: 20.h, width: 20.w),
                      onTap: () {
                        setModalState(() {
                          localSelectedIndex = index;
                        });
                      },
                    );
                  }),

                  // Divider
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                    child: Divider(color: AppColors.textColor.withOpacity(0.2), thickness: 1),
                  ),

                  // Ascending Option
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    title: Texts(
                      'Ascending',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppFonts.inter,
                      color: localSelectedOrder == 0 ? AppColors.primaryOrange : AppColors.textColor,
                    ),
                    trailing: SvgPicture.asset(localSelectedOrder == 0 ? Assets.svgIcRadioCheckl : Assets.svgIcRadioUncheck, height: 20.h, width: 20.w),
                    onTap: () {
                      setModalState(() {
                        localSelectedOrder = 0;
                      });
                    },
                  ),

                  // Descending Option
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    title: Texts(
                      'Descending',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppFonts.inter,
                      color: localSelectedOrder == 1 ? AppColors.primaryOrange : AppColors.textColor,
                    ),
                    trailing: SvgPicture.asset(localSelectedOrder == 1 ? Assets.svgIcRadioCheckl : Assets.svgIcRadioUncheck, height: 20.h, width: 20.w),
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ArtistBloc, ArtistState>(
          listener: (context, state) {
            // Update current artist when artists are refreshed
            state.maybeWhen(
              loaded: (artists, artistSongs) {
                // Find the updated artist with new song count
                final updatedArtist = artists.firstWhere((artist) => artist.id == _currentArtist.id, orElse: () => _currentArtist);
                // Update artist if it exists and has changed
                if (updatedArtist.id == _currentArtist.id) {
                  final oldSongCount = _currentArtist.songCount;
                  final newSongCount = updatedArtist.songCount;
                  final songCountChanged = newSongCount != oldSongCount;
                  final hasChanged = songCountChanged || updatedArtist.name != _currentArtist.name;

                  if (hasChanged && mounted) {
                    setState(() {
                      _currentArtist = updatedArtist;
                    });
                    // Only reload songs if the count actually decreased (song was deleted)
                    // This prevents unnecessary reloads when artist is just refreshed
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
            // When a song is successfully removed, refresh artist data
            state.maybeWhen(
              loaded: (songs) {
                // Wait a bit for database trigger to update artist count, then refresh
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _refreshArtistData();
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
          title: _currentArtist.name,
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
                  final hasAny = playerState.songs.isNotEmpty;
                  final showMiniPlayer = hasAny;

                  final artistArtworkPath = (_currentArtist.artworkPath?.isNotEmpty ?? false) ? _currentArtist.artworkPath! : Assets.svgProxyArtist;
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 20.w,
                      right: 20.w,
                      // top: 20.h,
                      bottom: showMiniPlayer ? 91.h : 3.h, // Space for MiniPlayerBar (which includes system nav bar padding)
                    ),
                    child: SizedBox(
                      height: double.infinity,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(height: 22.h),
                            CircleAvatar(
                              radius: 57.r,
                              backgroundColor: Colors.transparent,
                              child: GradientCard(
                                height: 100.h,
                                width: 100.w,
                                colors: [AppColors.black.withValues(alpha: 0.14), AppColors.black.withValues(alpha: 0.14)],
                                borderRadius: 50.r,
                                iconAsset: artistArtworkPath,
                                iconSize: 36.5.r,
                                margin: 10.w,
                              ),
                            ),
                            Texts(
                              _currentArtist.name,
                              fontSize: 20.sp,
                              fontWeight: AppFontWeights.medium,
                              fontFamily: AppFonts.inter,
                              color: AppColors.textColor,
                              align: TextAlign.center,
                              maxLines: 1,
                            ),
                            SizedBox(height: 7.h),
                            // Albums section
                            if (_albums.isNotEmpty) ...{
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Texts(
                                  '${_albums.length} Albums',
                                  fontSize: 14.sp,
                                  fontWeight: AppFontWeights.regular,
                                  fontFamily: AppFonts.inter,
                                  color: AppColors.textColor,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              SizedBox(
                                height: 170.h,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _albums.length,
                                  itemBuilder: (context, index) {
                                    final album = _albums[index];
                                    final albumArtworkPath = (album.artworkPath?.isNotEmpty ?? false) ? album.artworkPath! : Assets.svgAlbum;
                                    return GestureDetector(
                                      onTap: () {
                                        context.push('/dashboard/album-detail', extra: album);
                                      },
                                      child: Container(
                                        width: 120.w,
                                        margin: EdgeInsets.only(right: 15.w),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            GradientCard(
                                              height: 120.h,
                                              width: 120.w,
                                              colors: [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.primaryOrange],
                                              borderRadius: 13.r,
                                              iconAsset: albumArtworkPath,
                                              iconSize: 60.r,
                                              margin: 0,
                                            ),
                                            SizedBox(height: 6.h),
                                            Texts(
                                              album.name,
                                              fontSize: 14.sp,
                                              fontWeight: AppFontWeights.medium,
                                              fontFamily: AppFonts.inter,
                                              color: AppColors.textColor,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 2.h),
                                            Texts(
                                              '${album.songCount} songs',
                                              fontSize: 10.sp,
                                              fontWeight: AppFontWeights.regular,
                                              fontFamily: AppFonts.inter,
                                              color: AppColors.textColor,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 25.h),
                            },
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
                                            logS.log("Shuffle error in ArtistDetailScreen: $e");
                                          }
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
                                            logS.log("Play error in ArtistDetailScreen: $e");
                                          }
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

                            // Song count header
                            Row(
                              children: [
                                // Bullets icon and song count - tappable to navigate to select songs
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to select song screen for artist management
                                    context.push('/dashboard/select-song', extra: {'artist': _currentArtist, 'songs': _songs, 'isSystemPlaylist': false});
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
                                        '${_currentArtist.songCount} songs',
                                        fontSize: 16.sp,
                                        fontWeight: AppFontWeights.medium,
                                        fontFamily: AppFonts.inter,
                                        color: AppColors.textColor,
                                      ),
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
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
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
                                  'No songs by this artist',
                                  fontSize: 16,
                                  fontWeight: AppFontWeights.regular,
                                  fontFamily: AppFonts.inter,
                                ),
                              ),
                            },
                            Column(
                              children: List.generate(_songs.length, (index) {
                                return _songTile(
                                  _songs,
                                  index,
                                  playerState,
                                );
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
