import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../../screens/tabs/music_service.dart';
import '../../../features/playlists/bloc/playlist_bloc.dart';

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
    Assets.svgFavorites,
  ];

  List<String> musicIcons = [
    Assets.svgMusicIcon,
    Assets.pngBand,
    Assets.pngBand2,
  ];

  List<Color> colors = [
    AppColors.mildOrange,
    AppColors.mildBlue,
    AppColors.mildPink,
  ];

  final MusicPlayerService musicService = MusicPlayerService();

  @override
  void initState() {
    super.initState();
    // Fetch songs for recently played system playlist
    context.read<PlaylistBloc>().add(
      const PlaylistEvent.fetchSongsForSystemPlaylist('recently_played'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: BlocBuilder<PlaylistBloc, PlaylistState>(
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Texts(
                    'Explore Playlists',
                    fontSize: 18.sp,
                    fontWeight: AppFontWeights.medium,
                    fontFamily: AppFonts.inter,
                  ),
                  SizedBox(height: 13.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        // Find the corresponding system playlist
                        final systemPlaylist = state.maybeWhen(
                          loaded: (playlists, systemPlaylistSongs) =>
                              playlists.isNotEmpty
                              ? playlists
                                    .where((p) => p.isSystem == true)
                                    .firstWhere(
                                      (p) =>
                                          p.systemKey ==
                                          [
                                            'most_played',
                                            'recently_added',
                                            'favorites',
                                          ][index],
                                      orElse: () => playlists
                                          .where((p) => p.isSystem == true)
                                          .first,
                                    )
                              : null,
                          orElse: () => null,
                        );

                        return GradientCard(
                          height: 104.h,
                          width: 104.w,
                          colors: [
                            colors[index].withValues(alpha: 0.21),
                            colors[index],
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
                      Texts(
                        'Recently Played',
                        fontSize: 18.sp,
                        fontWeight: AppFontWeights.medium,
                        fontFamily: AppFonts.inter,
                      ),
                      Spacer(),
                      Texts(
                        'see all',
                        fontSize: 14.sp,
                        fontWeight: AppFontWeights.regular,
                        fontFamily: AppFonts.inter,
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  state.when(
                    initial: () => Center(child: CircularProgressIndicator()),
                    loading: () => Center(child: CircularProgressIndicator()),
                    loaded: (playlists, systemPlaylistSongs) {
                      // Get recently played songs from the system playlist songs
                      final recentlyPlayedSongs =
                          systemPlaylistSongs?['recently_played'] ?? [];

                      log('recentlyPlayedSongs length: ${recentlyPlayedSongs.length}');

                      if (recentlyPlayedSongs.isEmpty) {
                        return Text(
                          'No recently played songs',
                          style: TextStyle(color: Colors.grey),
                        );
                      }
                      return Column(
                        children: recentlyPlayedSongs.take(3).map((song) {
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
                                  final isCurrentlyPlaying =
                                      isCurrent;// && isPlaying;

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
                                        song.artwork_path ??
                                        Assets.svgMusicIcon,
                                    cardIconSize: 32.r,
                                    isSvgCardIcon: (song.artwork_path ?? '')
                                        .contains('.svg'),
                                    title: song.title,
                                    subtitle: '${song.artist} - ${song.album}',
                                    trailingIconAsset: isCurrent && isPlaying
                                        ? Assets.svgPause
                                        : Assets.svgPlayLogo,
                                    trailingIconHeight: 32.r,
                                    trailingIconWidth: 32.r,
                                    trailingMargin: 0,
                                    isGifLoad: isCurrentlyPlaying,
                                    onTap: () async {
                                      await musicService.setPlaylist(
                                        recentlyPlayedSongs,
                                        startIndex: recentlyPlayedSongs.indexOf(
                                          song,
                                        ),
                                      );
                                      await musicService.play();
                                    },
                                    onPlayTap: () async {
                                      if (isCurrent && isPlaying) {
                                        await musicService.pause();
                                      } else {
                                        await musicService.setPlaylist(
                                          recentlyPlayedSongs,
                                          startIndex: recentlyPlayedSongs
                                              .indexOf(song),
                                        );
                                        await musicService.play();
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                    error: (message) => Text('Error: $message'),
                  ),
                  SizedBox(height: 38.h),
                  Row(
                    children: [
                      Texts(
                        'My PlayLists',
                        fontSize: 18.sp,
                        fontWeight: AppFontWeights.medium,
                        fontFamily: AppFonts.inter,
                      ),
                      Spacer(),
                      Texts(
                        'see all',
                        fontSize: 14.sp,
                        fontWeight: AppFontWeights.regular,
                        fontFamily: AppFonts.inter,
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  state.when(
                    initial: () => Center(child: CircularProgressIndicator()),
                    loading: () => Center(child: CircularProgressIndicator()),
                    loaded: (playlists, systemPlaylistSongs) {
                      // Get user playlists (non-system playlists)
                      final userPlaylists = playlists
                          .where((p) => p.isSystem == false)
                          .toList();

                      if (userPlaylists.isEmpty) {
                        return Text(
                          'No user playlists',
                          style: TextStyle(color: Colors.grey),
                        );
                      }
                      return Column(
                        children: userPlaylists.take(3).map((playlist) {
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
                            trailingIconAsset: Assets.svgPlayLogo,
                            trailingIconHeight: 32.r,
                            trailingIconWidth: 32.r,
                            trailingMargin: 0,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(40),
                                  ),
                                ),
                                isScrollControlled: true,
                                builder: (_) => SongMenuScreen(
                                  songMenuList: songMenuItems,
                                  isPlaying: false,
                                ),
                              );
                            },
                            onPlayTap: () =>
                                print("Play tapped: ${playlist.name}"),
                          );
                        }).toList(),
                      );
                    },
                    error: (message) => Text('Error: $message'),
                  ),
                  SizedBox(height: 90.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
