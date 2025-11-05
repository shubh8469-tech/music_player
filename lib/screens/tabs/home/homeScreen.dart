import 'dart:developer';
import 'dart:io';

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
import '../../play_song/playing_song_screen.dart';
import '../library/playlists/create_playlist_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToLibraryPlaylists;

  const HomeScreen({super.key, this.onNavigateToLibraryPlaylists});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> categories = ['Most Played', 'Recently Added', 'My Favorites'];

  List<String> icons = [Assets.svgMostPlayed, Assets.svgRecentlyAdded, Assets.svgFavorites];

  List<String> musicIcons = [Assets.svgMusicIcon, Assets.pngBand, Assets.pngBand2];

  List<Color> colors = [AppColors.mildOrange, AppColors.mildBlue, AppColors.mildPink];

  final MusicPlayerService musicService = MusicPlayerService();

  @override
  void initState() {
    super.initState();
    // Fetch songs for recently played system playlist
    context.read<PlaylistBloc>().add(const PlaylistEvent.fetchSongsForSystemPlaylist('recently_played'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      // floatingActionButton: Platform.isIOS
      //     ? FloatingActionButton(
      //         onPressed: () {
      //           context.push('/dashboard/import-songs');
      //         },
      //         backgroundColor: AppColors.primaryOrange,
      //         child: Icon(Icons.add, color: AppColors.white, size: 28.r),
      //       )
      //     : null,
      body: BlocBuilder<PlaylistBloc, PlaylistState>(
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Texts('Explore Playlists', fontSize: 18.sp, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter),
                  SizedBox(height: 13.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        // Find the corresponding system playlist
                        final systemPlaylist = state.maybeWhen(
                          loaded: (playlists, systemPlaylistSongs) => playlists.isNotEmpty
                              ? playlists
                                    .where((p) => p.isSystem == true)
                                    .firstWhere(
                                      (p) => p.systemKey == ['most_played', 'recently_added', 'favorites'][index],
                                      orElse: () => playlists.where((p) => p.isSystem == true).first,
                                    )
                              : null,
                          orElse: () => null,
                        );

                        return GradientCard(
                          height: 104.h,
                          width: 104.w,
                          colors: [colors[index].withValues(alpha: 0.21), colors[index]],
                          borderRadius: 13.r,
                          iconAsset: icons[index],
                          iconSize: 40.r,
                          title: categories[index],
                          onTap: () {
                            if (systemPlaylist != null) {
                              context.push(
                                '/dashboard/playlist-detail',
                                extra: {
                                  'playlist': systemPlaylist,
                                  'assetIcon': icons[index],
                                  'colors': [colors[index].withValues(alpha: 0.21), colors[index]],
                                },
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
                      Texts('Recently Played', fontSize: 18.sp, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter),
                      Spacer(),
                      GestureDetector(
                        onTap: () {
                          // Find the recently_played system playlist
                          state.maybeWhen(
                            loaded: (playlists, systemPlaylistSongs) {
                              final recentlyPlayedPlaylist = playlists
                                  .where((p) => p.isSystem == true)
                                  .firstWhere((p) => p.systemKey == 'recently_played', orElse: () => playlists.where((p) => p.isSystem == true).first);

                              context.push(
                                '/dashboard/playlist-detail',
                                extra: {
                                  'playlist': recentlyPlayedPlaylist,
                                  'assetIcon': Assets.svgRecentlyPlayed,
                                  'colors': [AppColors.mildYellow.withValues(alpha: 0.21), AppColors.mildYellow],
                                },
                              );
                            },
                            orElse: () {},
                          );
                        },
                        child: Texts('See All', fontSize: 14.sp, fontWeight: AppFontWeights.regular, fontFamily: AppFonts.inter),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  state.when(
                    initial: () => Center(child: CircularProgressIndicator()),
                    loading: () => Center(child: CircularProgressIndicator()),
                    loaded: (playlists, systemPlaylistSongs) {
                      // Get recently played songs from the system playlist songs
                      final recentlyPlayedSongs = systemPlaylistSongs?['recently_played'] ?? [];

                      log('recentlyPlayedSongs length: ${recentlyPlayedSongs.length}');

                      if (recentlyPlayedSongs.isEmpty) {
                        return Text('No recently played songs', style: TextStyle(color: Colors.grey));
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
                                  final isCurrentlyPlaying = isCurrent; // && isPlaying;

                                  return MusicListTile(
                                    margin: 7.w,
                                    height: 66.h,
                                    borderRadius: 10.r,
                                    backgroundColor: AppColors.musicTileBackgroundColor,
                                    cardHeight: 50.h,
                                    cardWidth: 50.w,
                                    cardRadius: 7.r,
                                    cardIconAsset: song.artwork_path ?? Assets.svgMusicIcon,
                                    cardIconSize: 32.r,
                                    isSvgCardIcon: (song.artwork_path ?? '').contains('.svg'),
                                    title: song.title,
                                    subtitle: '${song.artist} - ${song.album}',
                                    trailingIconAsset: isCurrent && isPlaying ? Assets.svgPause : Assets.svgPlayLogo,
                                    trailingIconHeight: 32.r,
                                    trailingIconWidth: 32.r,
                                    trailingMargin: 0,
                                    isGifLoad: isCurrentlyPlaying,
                                    onTap: () async {
                                      if (musicService.songs.isNotEmpty && musicService.songs[musicService.currentIndex].id == song.id && musicService.isPlaying) {
                                        context.push('/dashboard/playing', extra: PlayingSongArgs(songs: musicService.songs));
                                      } else {
                                        await musicService.setPlaylist(recentlyPlayedSongs, startIndex: recentlyPlayedSongs.indexOf(song));
                                        await musicService.play();
                                      }
                                    },
                                    onPlayTap: () async {
                                      if (isCurrent && isPlaying) {
                                        await musicService.pause();
                                      } else {
                                        await musicService.setPlaylist(recentlyPlayedSongs, startIndex: recentlyPlayedSongs.indexOf(song));
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
                      Texts('My PlayLists', fontSize: 18.sp, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter),
                      Spacer(),
                      GestureDetector(
                        onTap: () {
                          // Navigate to Library tab and switch to Playlists
                          widget.onNavigateToLibraryPlaylists?.call();
                        },
                        child: Texts('See All', fontSize: 14.sp, fontWeight: AppFontWeights.regular, fontFamily: AppFonts.inter),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  state.when(
                    initial: () => Center(child: CircularProgressIndicator()),
                    loading: () => Center(child: CircularProgressIndicator()),
                    loaded: (playlists, systemPlaylistSongs) {
                      // Get user playlists (non-system playlists)
                      final userPlaylists = playlists.where((p) => p.isSystem == false).toList();

                      if (userPlaylists.isEmpty) {
                        return GestureDetector(
                          onTap: () {
                            CreatePlaylistBottomSheet.show(context);
                          },
                          child: Row(
                            children: [
                              Container(
                                height: 66.h,
                                width: 66.w,
                                decoration: BoxDecoration(color: AppColors.musicTileBackgroundColor, borderRadius: BorderRadius.circular(10.r)),
                                child: Icon(Icons.add, size: 32.r, color: Colors.black),
                              ),
                              SizedBox(width: 12.w),
                              Texts('Create new playlist', fontSize: 16.sp, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter),
                            ],
                          ),
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
                            trailingIconAsset: Assets.svgMenuIcon,
                            trailingIconHeight: 19.5.h,
                            trailingIconWidth: 3.w,
                            trailingMargin: 0,
                            onTap: () {
                              context.push(
                                '/dashboard/playlist-detail',
                                extra: {
                                  'playlist': playlist,
                                  'assetIcon': Assets.svgMusicIcon,
                                  'colors': [AppColors.mildBlue.withValues(alpha: 0.21), AppColors.mildBlue],
                                },
                              );
                            },
                            onPlayTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
                                isScrollControlled: true,
                                builder: (_) => SongMenuScreen(
                                  songMenuList: playlistMenuItems,
                                  isPlaying: false,
                                  currentSong: musicService.currentIndex != -1 ? musicService.songs[musicService.currentIndex] : null,
                                  songIndex: 0,
                                  songsList: [],
                                  maxHeight: 0.79.sh,
                                  from: 'playlist',
                                  systemKeyOrId: playlist.id.toString(),
                                  isSystemPlaylist: false,
                                ),
                              );
                            },
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
