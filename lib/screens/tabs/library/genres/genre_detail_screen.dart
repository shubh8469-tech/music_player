import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/genres/domain/entities/genre.dart';
import 'package:music_app/features/genres/bloc/genre_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/song_menu_screen.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../features/genres/domain/repositories/genre_repository.dart';
import '../../../../generated/assets.dart';
import '../../../../core/di/injection.dart';
import '../../../../utills/globals.dart';
import '../widgets/mini_player_bar.dart';
import '../../../../model/song_menu_model.dart';
import '../../../../commonWidgets/bottom_button_two.dart';
import '../../../../l10n/l10n.dart';
import '../../../play_song/playing_song_screen.dart';

class GenreDetailScreen extends StatefulWidget {
  final Genre genre;
  const GenreDetailScreen({super.key, required this.genre});

  @override
  State<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends State<GenreDetailScreen> {
  final _repo = locator<GenreRepository>();
  final musicService = MusicPlayerService();

  List<SongsModel> _songs = [];
  late Genre _currentGenre;

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
    if (mounted) {
      setState(() {
        _songs = songs.cast<SongsModel>();
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
        sortedSongs.sort((a, b) => isAscending
            ? a.title.toLowerCase().compareTo(b.title.toLowerCase())
            : b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case 1: // Artist
        sortedSongs.sort((a, b) => isAscending
            ? a.artist.toLowerCase().compareTo(b.artist.toLowerCase())
            : b.artist.toLowerCase().compareTo(a.artist.toLowerCase()));
        break;
      case 2: // Album
        sortedSongs.sort((a, b) => isAscending
            ? a.album.toLowerCase().compareTo(b.album.toLowerCase())
            : b.album.toLowerCase().compareTo(a.album.toLowerCase()));
        break;
      case 3: // Folder
        sortedSongs.sort((a, b) => isAscending
            ? a.folder!.toLowerCase().compareTo(b.folder!.toLowerCase())
            : b.folder!.toLowerCase().compareTo(a.folder!.toLowerCase()));
        break;
      case 4: // Added Time
        sortedSongs.sort((a, b) => isAscending
            ? a.createdTime.compareTo(b.createdTime)
            : b.createdTime.compareTo(a.createdTime));
        break;
      case 5: // Play Count
        sortedSongs.sort((a, b) => isAscending
            ? a.playCount.compareTo(b.playCount)
            : b.playCount.compareTo(a.playCount));
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

  Widget _songTile(List<SongsModel> list, int index) {
    final song = list[index];
    return StreamBuilder<int?>(
      stream: musicService.currentSongIdStream,
      initialData: musicService.currentSongId,
      builder: (context, idSnap) {
        return MusicListTile(
          margin: 7.w,
          height: 66.h,
          borderRadius: 10.r,
          backgroundColor: AppColors.musicTileBackgroundColor,
          cardHeight: 50.h,
          cardWidth: 50.w,
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
          onTap: () async {
            final musicService = MusicPlayerService();
            if (musicService.songs.isNotEmpty && musicService.songs[musicService.currentIndex].id == song.id && musicService.isPlaying) {
              context.push('/dashboard/playing', extra: PlayingSongArgs(songs: musicService.songs));
            } else {
              await musicService.setPlaylist(_songs, startIndex: index);
              await musicService.play();
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
                songsList: _songs,
                onSongDeleted: () {
                  _loadSongs();
                  _refreshGenreData();
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final genreArtworkPath = (_currentGenre.artworkPath?.isNotEmpty ?? false)
        ? _currentGenre.artworkPath!
        : Assets.svgProxyArtist;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: SvgPicture.asset(
                      Assets.svgIcBack,
                      height: 24.h,
                      width: 24.w,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Texts(
                      _currentGenre.name,
                      fontSize: 18.sp,
                      fontWeight: AppFontWeights.semiBold,
                      fontFamily: AppFonts.manrope,
                    ),
                  ),
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
            ),

            // Genre Info Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: GradientCard(
                height: 180.h,
                width: double.infinity,
                colors: [
                  AppColors.mildOrange.withValues(alpha: 0.21),
                  AppColors.mildOrange,
                ],
                borderRadius: 13.r,
                iconAsset: genreArtworkPath,
                iconSize: 100.r,
                margin: 0,
              ),
            ),

            SizedBox(height: 20.h),

            // Songs Count
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Texts(
                    '${_songs.length} Songs',
                    fontSize: 14.sp,
                    fontWeight: AppFontWeights.regular,
                    color: AppColors.textColor,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Songs List
            Expanded(
              child: _songs.isEmpty
                  ? Center(
                      child: Texts(
                        'No songs found',
                        fontSize: 16.sp,
                        color: AppColors.mediumDarkGrey,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: _songs.length,
                      itemBuilder: (context, index) => _songTile(_songs, index),
                    ),
            ),

            // Mini Player Bar
            MiniPlayerBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSortBottomSheet() {
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
                  visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                  title: Texts(
                    item.title,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.inter,
                    color: index == selectedIndex
                        ? AppColors.primaryOrange
                        : AppColors.textColor,
                  ),
                  trailing: SvgPicture.asset(
                    index == selectedIndex
                        ? Assets.svgIcRadioCheckl
                        : Assets.svgIcRadioUncheck,
                    height: 20.h,
                    width: 20.w,
                  ),
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              }),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                child: Divider(
                  color: AppColors.textColor.withOpacity(0.2),
                  thickness: 1,
                ),
              ),
              if (selectedIndex != 6) ...[
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                  title: Texts(
                    'Ascending',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.inter,
                    color: selectedOrder == 0
                        ? AppColors.primaryOrange
                        : AppColors.textColor,
                  ),
                  trailing: SvgPicture.asset(
                    selectedOrder == 0
                        ? Assets.svgIcRadioCheckl
                        : Assets.svgIcRadioUncheck,
                    height: 20.h,
                    width: 20.w,
                  ),
                  onTap: () {
                    setState(() {
                      selectedOrder = 0;
                    });
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                  title: Texts(
                    'Descending',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w400,
                    fontFamily: AppFonts.inter,
                    color: selectedOrder == 1
                        ? AppColors.primaryOrange
                        : AppColors.textColor,
                  ),
                  trailing: SvgPicture.asset(
                    selectedOrder == 1
                        ? Assets.svgIcRadioCheckl
                        : Assets.svgIcRadioUncheck,
                    height: 20.h,
                    width: 20.w,
                  ),
                  onTap: () {
                    setState(() {
                      selectedOrder = 1;
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
              lefBtnTap: () {
                Navigator.pop(context);
              },
              rightBtnTap: () {
                _sortSongs(selectedIndex, selectedOrder);
                Navigator.pop(context);
              },
            ),
          ),
          SizedBox(height: 25.h),
        ],
      ),
    );
  }
}

