import 'dart:developer' as logS;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/commonWidgets/app_bar_with_icon_title.dart';
import 'package:music_app/features/genres/bloc/genre_bloc.dart';
import 'package:music_app/features/genres/domain/entities/genre.dart';
import 'package:music_app/features/music_player/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/bloc/music_player_state.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
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
import '../../../../features/genres/domain/repositories/genre_repository.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../model/song_menu_model.dart';
import '../../../../utills/globals.dart';
import '../../../../utills/snack_bar.dart';
import '../../../common/commonTapProvider.dart';
import '../../../play_song/playing_song_screen.dart';
import '../widgets/mini_player_bar.dart';

class GenreDetailScreen extends StatefulWidget {
  final Genre genre;
  const GenreDetailScreen({super.key, required this.genre});

  @override
  State<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends State<GenreDetailScreen> {
  final _repo = locator<GenreRepository>();

  MusicPlayerService get _musicService =>
      context.read<MusicPlayerBloc>().musicService;

  List<SongsModel> _songs = [];
  List<SongsModel> _baseSongs = [];
  List<_GenreAlbumSummary> _albums = [];
  late Genre _currentGenre;

  Genre _withUpdatedFields(
    Genre source, {
    int? songCount,
    String? name,
    String? artworkPath,
  }) {
    return Genre(
      id: source.id,
      name: name ?? source.name,
      songCount: songCount ?? source.songCount,
      artworkPath: artworkPath ?? source.artworkPath,
      createdTime: source.createdTime,
      updatedTime: source.updatedTime,
    );
  }

  // Sort options without genre option
  late final List<SongMenuItem> _genreSongSortByItems;
  int selectedIndex = 0;
  int selectedOrder = 0;

  @override
  void initState() {
    super.initState();
    _currentGenre = widget.genre;
    // Create sort items - remove genre option if it exists
    _genreSongSortByItems = List.from(sortByItems);
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await _repo.getSongsForGenre(_currentGenre.id!);
    if (!mounted) return;

    final castedSongs = songs.cast<SongsModel>();
    setState(() {
      _songs = castedSongs;
      _baseSongs = List<SongsModel>.from(castedSongs);
      _currentGenre = _withUpdatedFields(
        _currentGenre,
        songCount: _songs.length,
      );
    });

    await _loadGenreAlbums(castedSongs);
  }

  Future<void> _loadGenreAlbums(List<SongsModel> songs) async {
    if (songs.isEmpty) {
      if (mounted) {
        setState(() {
          _albums = [];
        });
      }
      return;
    }

    final Map<String, _GenreAlbumSummary> groupedAlbums = {};

    for (final song in songs) {
      final rawAlbum = song.album.trim();
      if (rawAlbum.isEmpty) continue;

      final rawArtist = song.artist.trim();
      final key = '${rawAlbum.toLowerCase()}|${rawArtist.toLowerCase()}';

      if (!groupedAlbums.containsKey(key)) {
        groupedAlbums[key] = _GenreAlbumSummary(
          albumName: rawAlbum,
          artistName: rawArtist,
          artworkPath: song.artwork_path,
          songCount: 1,
        );
      } else {
        final existing = groupedAlbums[key]!;
        groupedAlbums[key] = existing.copyWith(
          songCount: existing.songCount + 1,
          artworkPath: existing.artworkPath?.isNotEmpty == true
              ? existing.artworkPath
              : song.artwork_path,
        );
      }
    }

    final summaries = groupedAlbums.values.toList()
      ..sort((a, b) => a.albumName.toLowerCase().compareTo(b.albumName.toLowerCase()));

    if (mounted) {
      setState(() {
        _albums = summaries;
      });
    }
  }

  Future<void> _refreshGenreData() async {
    // Refresh genre data to get updated song count
    final genreBloc = context.read<GenreBloc>();
    genreBloc.add(const GenreEvent.fetchAllGenres());
  }

  void _sortSongs(int sortIndex, int sortOrder) {
    List<SongsModel> sortedSongs = List.from(_songs);
    final isAscending = sortOrder == 0;

    switch (sortIndex) {
      case 0: // Song Name
        sortedSongs.sort(
          (a, b) => isAscending
              ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
              : b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
      case 1: // Artist
        sortedSongs.sort(
          (a, b) => isAscending
              ? a.artist.toLowerCase().compareTo(b.artist.toLowerCase())
              : b.artist.toLowerCase().compareTo(a.artist.toLowerCase()),
        );
        break;
      case 2: // Album
        sortedSongs.sort(
          (a, b) => isAscending
              ? a.album.toLowerCase().compareTo(b.album.toLowerCase())
              : b.album.toLowerCase().compareTo(a.album.toLowerCase()),
        );
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

  Widget _songTile(List<SongsModel> list, int index, MusicPlayerState state) {
    final song = list[index];
    final isCurrent = song.id == state.currentSongId;
    final isPlaying = state.isPlaying;
    return MusicListTile(
          margin: 7.w,
          height: 66.h,
          borderRadius: 10.r,
          backgroundColor: AppColors.musicTileBackgroundColor,
          cardHeight: 50.h,
          cardWidth: 50.h,
          cardRadius: 7.r,
          cardIconAsset: song.artwork_path ?? Assets.svgMusicIcon,
          noLogoGradientColor: [
            AppColors.mildOrange.withValues(alpha: 0.21),
            AppColors.mildOrange,
          ],
          cardIconSize: 19.r,
          title: song.title,
          subtitle: '${song.artist} • ${song.album}',
          trailingIconAsset: Assets.svgMenuIcon,
          trailingIconHeight: 19.5.h,
          trailingIconWidth: 3.w,
          trailingMargin: 10.w,
          isGifLoad: isCurrent,
          isPlaying: isPlaying,
          onTap: () async {
            final current = _musicService.currentSong;
            if (current != null &&
                current.id == song.id &&
                isPlaying) {
              context.push(
                '/dashboard/playing',
                extra: PlayingSongArgs(songs: _musicService.songs),
              );
            } else {
              await _musicService.setPlaylist(list, startIndex: index);
              await _musicService.play();
            }
          },
          onPlayTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
              ),
              isScrollControlled: true,
              builder: (_) => SongMenuScreen(
                songMenuList: songMenuItems,
                isPlaying: false,
                currentSong: song,
                songIndex: index,
                songsList: list,
                maxHeight: 0.87.sh,
                isSystemPlaylist: false,
                onSongDeleted: () {
                  final songId = song.id;
                  final updatedCount = _currentGenre.songCount > 0
                      ? _currentGenre.songCount - 1
                      : 0;
                  setState(() {
                    _songs.removeWhere((s) => s.id == songId);
                    _baseSongs.removeWhere((s) => s.id == songId);
                    _currentGenre = Genre(
                      id: _currentGenre.id,
                      name: _currentGenre.name,
                      songCount: updatedCount,
                      artworkPath: _currentGenre.artworkPath,
                      createdTime: _currentGenre.createdTime,
                      updatedTime: _currentGenre.updatedTime,
                    );
                  });

                  Future.delayed(const Duration(milliseconds: 800), () async {
                    if (mounted) {
                      await _loadSongs();
                      _refreshGenreData();
                    }
                  });
                },
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GenreBloc, GenreState>(
          listener: (context, state) {
            state.maybeWhen(
              loaded: (genres, genreSongs) {
                final updatedGenre = genres.firstWhere(
                  (genre) => genre.id == _currentGenre.id,
                  orElse: () => _currentGenre,
                );

                if (updatedGenre.id == _currentGenre.id) {
                  final oldSongCount = _currentGenre.songCount;
                  final newSongCount = updatedGenre.songCount;
                  final songCountChanged = newSongCount != oldSongCount;
                  final hasChanged =
                      songCountChanged ||
                      updatedGenre.name != _currentGenre.name ||
                      updatedGenre.artworkPath != _currentGenre.artworkPath;

                  if (hasChanged && mounted) {
                    setState(() {
                      final computedCount = _songs.isNotEmpty
                          ? _songs.length
                          : newSongCount;
                      _currentGenre = _withUpdatedFields(
                        updatedGenre,
                        songCount: computedCount,
                      );
                    });
                  }

                  if (songCountChanged) {
                    _loadSongs();
                  }
                }
              },
              orElse: () {},
            );
          },
        ),
        BlocListener<SongsBloc, SongsState>(
          listener: (context, state) {
            state.maybeWhen(
              loaded: (songs) {
                Future.microtask(() async {
                  if (!mounted) return;
                  await _loadSongs();
                  if (mounted) {
                    _refreshGenreData();
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
          title: _currentGenre.name,
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
                builder: (context, state) {
                  final hasAny = state.songs.isNotEmpty;
                  final showMiniPlayer = hasAny;
                  final hasArtwork =
                      _currentGenre.artworkPath?.isNotEmpty ?? false;
                  final genreArtworkPath =
                      hasArtwork ? _currentGenre.artworkPath! : '';

                  return Padding(
                    padding: EdgeInsets.only(
                      left: 20.w,
                      right: 20.w,
                      // top: 20.h,
                      bottom: showMiniPlayer ? 91.h : 3.h,
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
                                colors: [
                                  AppColors.primaryOrange.withValues(alpha: 0.21),
                                  AppColors.primaryOrange,
                                ],
                                borderRadius: 13.r,
                                iconAsset: genreArtworkPath,
                                iconSize: 36.5.r,
                                margin: 10.w,
                                content: hasArtwork
                                    ? null
                                    : buildGenreInitialAvatar(
                                        widget.genre.name,
                                        50.sp,
                                      ),
                              ),
                            ),
                            Texts(
                              _currentGenre.name,
                              fontSize: 20.sp,
                              fontWeight: AppFontWeights.medium,
                              fontFamily: AppFonts.inter,
                              color: AppColors.textColor,
                              align: TextAlign.center,
                              maxLines: 1,
                            ),
                            SizedBox(height: 7.h),
                            Texts(
                              '${_currentGenre.songCount} songs',
                              fontSize: 14.sp,
                              fontWeight: AppFontWeights.regular,
                              fontFamily: AppFonts.inter,
                              color: AppColors.textColor,
                              align: TextAlign.center,
                            ),
                            if (_albums.isNotEmpty) ...[
                              SizedBox(height: 12.h),
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
                                    final albumArtworkPath =
                                        (album.artworkPath?.isNotEmpty ?? false)
                                            ? album.artworkPath!
                                            : Assets.svgAlbum;
                                    return GestureDetector(
                                      onTap: () {
                                        showSnackBar(
                                          context,
                                          () {},
                                          message:
                                              'Open the Albums tab for full details',
                                          alertBannerLocation:
                                              AlertBannerLocation.bottom,
                                        );
                                      },
                                      child: Container(
                                        width: 120.w,
                                        margin: EdgeInsets.only(right: 15.w),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GradientCard(
                                              height: 120.h,
                                              width: 120.w,
                                              colors: [
                                                AppColors.mildOrange
                                                    .withValues(alpha: 0.21),
                                                AppColors.primaryOrange,
                                              ],
                                              borderRadius: 13.r,
                                              iconAsset: albumArtworkPath,
                                              iconSize: 60.r,
                                              margin: 0,
                                            ),
                                            SizedBox(height: 6.h),
                                            Texts(
                                              album.albumName,
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
                                              fontWeight:
                                                  AppFontWeights.regular,
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
                            ],
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

                                            if (_musicService.currentIndex < 0) {
                                              await _musicService.setPlaylist(
                                                _songs,
                                                autoPlay: false,
                                                startIndex: 0,
                                              );
                                              await _musicService.play();
                                            } else {
                                              context.push(
                                                '/dashboard/playing',
                                                extra: PlayingSongArgs(songs: _songs),
                                              );
                                              await _musicService.setShufflePlaylist(
                                                _songs,
                                                autoPlay: false,
                                              );
                                              await _musicService.ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();
                                              await _musicService.player.currentIndexStream.firstWhere(
                                                (idx) => idx != null && idx != 0,
                                              );
                                              await _musicService.play();
                                            }

                                            logS.log("Shuffle Play started for genre");
                                          } catch (e) {
                                            logS.log("Shuffle error in GenreDetailScreen: $e");
                                          }
                                        },
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 40.h,
                                    width: 165.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.shuffleBackground,
                                      borderRadius: BorderRadius.circular(
                                        100.r,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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

                                            if (_musicService.isPlaying) {
                                              context.push(
                                                '/dashboard/playing',
                                                extra: PlayingSongArgs(songs: _songs),
                                              );
                                            } else if (_musicService.currentIndex >= 0) {
                                              context.push(
                                                '/dashboard/playing',
                                                extra: PlayingSongArgs(songs: _songs),
                                              );
                                              await _musicService.play();
                                            } else {
                                              await _musicService.ensureShuffleOff();
                                              await _musicService.setPlaylist(
                                                List<SongsModel>.from(_baseSongs),
                                                startIndex: 0,
                                                autoPlay: true,
                                              );
                                            }
                                          } catch (e) {
                                            logS.log("Play error in GenreDetailScreen: $e");
                                          }
                                        },
                                  child: Container(
                                    height: 40.h,
                                    width: 165.w,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryOrange,
                                      borderRadius: BorderRadius.circular(
                                        100.r,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    final shouldRefresh = await context.push(
                                      '/dashboard/select-song',
                                      extra: {
                                        'genre': _currentGenre,
                                        'songs': _songs,
                                        'isSystemPlaylist': false,
                                      },
                                    );

                                    if (shouldRefresh == true && mounted) {
                                      await _loadSongs();
                                      _refreshGenreData();
                                    }
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
                                        '${_currentGenre.songCount} songs',
                                        fontSize: 16.sp,
                                        fontWeight: AppFontWeights.medium,
                                        fontFamily: AppFonts.inter,
                                        color: AppColors.textColor,
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
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
                                      builder: (_) => _buildSortBottomSheet(),
                                    );
                                  },
                                  child: SvgPicture.asset(Assets.svgFilter),
                                ),
                              ],
                            ),
                            SizedBox(height: 25.h),
                            if (_songs.isEmpty)
                              Center(
                                child: Texts(
                                  'No songs found',
                                  fontSize: 16.sp,
                                  fontWeight: AppFontWeights.regular,
                                  fontFamily: AppFonts.inter,
                                ),
                              )
                            else
                              Column(
                                children: List.generate(
                                  _songs.length,
                                  (index) => _songTile(_songs, index, state),
                                ),
                              ),
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

  Widget _buildSortBottomSheet() {
    int localSelectedIndex = selectedIndex;
    int localSelectedOrder = selectedOrder;

    return StatefulBuilder(
      builder: (context, setModalState) {
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(_genreSongSortByItems.length, (index) {
                    var item = _genreSongSortByItems[index];
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity(
                        horizontal: 0.w,
                        vertical: -2.h,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      title: Texts(
                        item.title,
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
                  if (localSelectedIndex != 6) ...[
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
                ],
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: BottomButtonTwo(
                  leftBtnTitle: S.of(context).cancel,
                  rightBtnTitle: "Done",
                  lefBtnTap: () {},
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
}

class _GenreAlbumSummary {
  final String albumName;
  final String artistName;
  final String? artworkPath;
  final int songCount;

  const _GenreAlbumSummary({
    required this.albumName,
    required this.artistName,
    required this.artworkPath,
    required this.songCount,
  });

  _GenreAlbumSummary copyWith({
    String? albumName,
    String? artistName,
    String? artworkPath,
    int? songCount,
  }) {
    return _GenreAlbumSummary(
      albumName: albumName ?? this.albumName,
      artistName: artistName ?? this.artistName,
      artworkPath: artworkPath ?? this.artworkPath,
      songCount: songCount ?? this.songCount,
    );
  }
}
