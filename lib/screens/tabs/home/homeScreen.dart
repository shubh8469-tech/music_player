import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/commonWidgets/song_menu_screen.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

import '../../../commonWidgets/MusicListTile.dart';
import '../../../commonWidgets/gradientCard.dart';
import '../../../commonWidgets/textWidget.dart';
import '../../../generated/assets.dart';
import '../../../utills/globals.dart';
import '../../../features/playlists/domain/repositories/playlist_repository.dart';
import '../../../features/playlists/domain/entities/playlist.dart';
import '../../../features/songs/data/models/song_model.dart';
import '../../../core/di/injection.dart';
import '../../../screens/tabs/music_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> categories = ['Most Played', 'Recently Added', 'My Favorites'];

  List<String> icons = [
    Assets.svgMostPlayed,
    Assets.svgRecentlyAdded,
    Assets.svgFavorites
  ];

  List<String> musicIcons = [
    Assets.svgMusicIcon,
    Assets.pngBand,
    Assets.pngBand2
  ];

  List<Color> colors = [
    AppColors.mildOrange,
    AppColors.mildBlue,
    AppColors.mildPink
  ];

  // Data lists
  List<SongsModel> recentlyPlayedSongs = [];
  List<Playlist> userPlaylists = [];
  List<Playlist> systemPlaylists = [];
  bool isLoading = true;

  late PlaylistRepository playlistRepository;
  final MusicPlayerService musicService = MusicPlayerService();

  @override
  void initState() {
    super.initState();
    playlistRepository = locator<PlaylistRepository>();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final recentlyPlayed =
          await playlistRepository.getSongsForSystemPlaylist('recently_played');

      final allPlaylists = await playlistRepository.fetchAllPlaylists();
      final userPlaylistsOnly =
          allPlaylists.where((p) => p.isSystem == false).toList();
      final systemPlaylistsOnly =
          allPlaylists.where((p) => p.isSystem == true).toList();

      setState(() {
        recentlyPlayedSongs = recentlyPlayed.take(3).toList();
        userPlaylists = userPlaylistsOnly.take(3).toList();
        systemPlaylists = systemPlaylistsOnly;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Texts('Explore Playlists',
                  fontSize: 18.sp,
                  fontWeight: AppFontWeights.medium,
                  fontFamily: AppFonts.inter),
              SizedBox(height: 13.h),
              if (isLoading)
                Center(child: CircularProgressIndicator())
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      // Find the corresponding system playlist
                      final systemPlaylist = systemPlaylists.isNotEmpty
                          ? systemPlaylists.firstWhere(
                              (p) =>
                                  p.systemKey ==
                                  [
                                    'most_played',
                                    'recently_added',
                                    'favorites'
                                  ][index],
                              orElse: () => systemPlaylists.first,
                            )
                          : null;

                      return GradientCard(
                        height: 104.h,
                        width: 104.w,
                        colors: [
                          colors[index].withValues(alpha: 0.21),
                          colors[index]
                        ],
                        borderRadius: 13.r,
                        iconAsset: icons[index],
                        iconSize: 40.r,
                        title: categories[index],
                        onTap: () {
                          if (systemPlaylist != null) {
                            context.push(
                              '/dashboard/playlist-detail',
                              extra: systemPlaylist,
                            );
                          }
                        },
                        margin: 10.w,
                      );
                    }),
                  ),
                ),
              SizedBox(height: 40.h),
              Row(
                children: [
                  Texts('Recently Played',
                      fontSize: 18.sp,
                      fontWeight: AppFontWeights.medium,
                      fontFamily: AppFonts.inter),
                  Spacer(),
                  Texts('see all',
                      fontSize: 14.sp,
                      fontWeight: AppFontWeights.regular,
                      fontFamily: AppFonts.inter),
                ],
              ),
              SizedBox(height: 5.h),
              if (isLoading)
                Center(child: CircularProgressIndicator())
              else if (recentlyPlayedSongs.isEmpty)
                Text('No recently played songs',
                    style: TextStyle(color: Colors.grey))
              else
                Column(
                  children: recentlyPlayedSongs.map((song) {
                    return StreamBuilder<int?>(
                      stream: musicService.currentSongIdStream,
                      initialData: musicService.currentSongId,
                      builder: (context, currentIdSnap) {
                        return StreamBuilder<bool>(
                          stream: musicService.isPlayingStream,
                          initialData: musicService.isPlaying,
                          builder: (context, playingSnap) {
                            final currentId = currentIdSnap.data;
                            final isPlaying = playingSnap.data ?? false;
                            final isCurrent = song.id == currentId;
                            final isCurrentlyPlaying = isCurrent && isPlaying;

                            return MusicListTile(
                              margin: 7.w,
                              height: 66.h,
                              borderRadius: 10.r,
                              backgroundColor:
                                  AppColors.musicTileBackgroundColor,
                              cardHeight: 50.h,
                              cardWidth: 50.w,
                              cardRadius: 7.r,
                              cardIconAsset:
                                  song.artwork_path ?? Assets.svgMusicIcon,
                              cardIconSize: 32.r,
                              isSvgCardIcon:
                                  (song.artwork_path ?? '').contains('.svg'),
                              title: song.title,
                              subtitle: '${song.artist} - ${song.album}',
                              trailingIconAsset: isCurrentlyPlaying
                                  ? Assets.svgPause
                                  : Assets.svgPlayLogo,
                              trailingIconHeight: 32.r,
                              trailingIconWidth: 32.r,
                              trailingMargin: 0,
                              isGifLoad: isCurrentlyPlaying,
                              onTap: () async {
                                await musicService.setPlaylist(
                                    recentlyPlayedSongs,
                                    startIndex:
                                        recentlyPlayedSongs.indexOf(song));
                                await musicService.play();
                              },
                              onPlayTap: () async {
                                if (isCurrentlyPlaying) {
                                  await musicService.pause();
                                } else {
                                  await musicService.setPlaylist(
                                      recentlyPlayedSongs,
                                      startIndex:
                                          recentlyPlayedSongs.indexOf(song));
                                  await musicService.play();
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  }).toList(),
                ),
              SizedBox(height: 38.h),
              Row(
                children: [
                  Texts('My PlayLists',
                      fontSize: 18.sp,
                      fontWeight: AppFontWeights.medium,
                      fontFamily: AppFonts.inter),
                  Spacer(),
                  Texts('see all',
                      fontSize: 14.sp,
                      fontWeight: AppFontWeights.regular,
                      fontFamily: AppFonts.inter),
                ],
              ),
              SizedBox(height: 5.h),
              if (isLoading)
                Center(child: CircularProgressIndicator())
              else if (userPlaylists.isEmpty)
                Text('No user playlists', style: TextStyle(color: Colors.grey))
              else
                Column(
                  children: userPlaylists.map((playlist) {
                    return MusicListTile(
                      margin: 7.w,
                      height: 66.h,
                      borderRadius: 10.r,
                      backgroundColor: AppColors.musicTileBackgroundColor,
                      cardHeight: 50.h,
                      cardWidth: 50.w,
                      cardRadius: 7.r,
                      cardIconAsset: Assets.svgMusicIcon,
                      cardIconSize: 32.r,
                      title: playlist.name,
                      subtitle: '${playlist.songCount} Songs',
                      trailingIconAsset: Assets.svgMenuIcon,
                      trailingIconHeight: 15.h,
                      trailingIconWidth: 3.w,
                      trailingMargin: 10.w,
                      onTap: () => {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(40))),
                          isScrollControlled: true,
                          builder: (_) => SongMenuScreen(
                              songMenuList: songMenuItems, isPlaying: false),
                        ),
                      },
                      onPlayTap: () => print("Play tapped: ${playlist.name}"),
                    );
                  }).toList(),
                ),

              SizedBox(
                height: 90.h,
              )
            ],
          ),
        ),
      ),
    );
  }
}
