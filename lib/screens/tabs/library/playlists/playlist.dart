import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/themes/color.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/playlist_menu_screen.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../generated/assets.dart';
import '../../../../themes/font.dart';
import '../../../../features/playlists/bloc/playlist_bloc.dart';
import '../../../../features/playlists/domain/entities/playlist.dart' as domain;
import 'package:go_router/go_router.dart';
import '../../music_service.dart';
import 'dart:async';

import 'create_playlist_bottom_sheet.dart';
import 'rename_playlist_bottom_sheet.dart';
import '../../../../utills/snack_bar.dart';

class PlayListScreen extends StatefulWidget {
  const PlayListScreen({super.key});

  @override
  State<PlayListScreen> createState() => _PlayListScreenState();
}

class _PlayListScreenState extends State<PlayListScreen> {
  final List<String> systemOrder = [
    'most_played',
    'recently_added',
    'recently_played',
    'favorites',
  ];
  final Map<String, String> systemIcon = {
    'most_played': Assets.svgMostPlayed,
    'recently_added': Assets.svgRecentlyAdded,
    'recently_played': Assets.svgRecentlyPlayed,
    'favorites': Assets.svgFavorites,
  };
  final Map<String, Color> systemColor = {
    'most_played': AppColors.mildOrange,
    'recently_added': AppColors.mildBlue,
    'recently_played': AppColors.mildYellow,
    'favorites': AppColors.mildPink,
  };

  StreamSubscription<void>? _libChangedSub;
  var musicService = MusicPlayerService();

  @override
  void initState() {
    super.initState();
    // Listen once per screen lifecycle with debounce
    // _libChangedSub = MusicPlayerService().libraryChanged.listen((_) {
    //   if (!mounted) return;
    //
    //   // Debounce: Only refresh if last refresh was more than 1 second ago
    //   final now = DateTime.now();
    //   if (_lastRefreshTime == null ||
    //       now.difference(_lastRefreshTime!).inSeconds > 1) {
    //     _lastRefreshTime = now;
    //     context.read<PlaylistBloc>().add(
    //       const PlaylistEvent.refreshPlaylists(),
    //     );
    //   }
    // });
  }

  @override
  void dispose() {
    _libChangedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 30.h,
          bottom: 1.h,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      context.push('/dashboard/select-playlist');
                    },
                    child: Row(
                      children: [
                        SvgPicture.asset(Assets.svgSongsCount),
                        SizedBox(width: 10.w),
                        BlocBuilder<PlaylistBloc, PlaylistState>(
                          builder: (context, state) {
                            int total = 0;
                            state.maybeWhen(
                              loaded: (playlists, systemPlaylistSongs) =>
                                  total = playlists.length,
                              orElse: () {},
                            );
                            return Texts(
                              '$total Playlists',
                              fontSize: 14.sp,
                              fontWeight: AppFontWeights.regular,
                              color: AppColors.textColor,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      CreatePlaylistBottomSheet.show(context);
                    },
                    child: Container(
                      height: 24.h,
                      width: 24.w,
                      decoration: BoxDecoration(
                        color: AppColors.mediumDarkGrey.withAlpha(100),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Icon(Icons.add),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  SvgPicture.asset(Assets.svgMenuIcon),
                ],
              ),
              SizedBox(height: 33.h),
              BlocBuilder<PlaylistBloc, PlaylistState>(
                builder: (context, state) {
                  return state.maybeWhen(
                    loaded: (allPlaylists, systemPlaylistSongs) {
                      final systemPlaylists = allPlaylists
                          .where((p) => (p.isSystem == true))
                          .cast<domain.Playlist>()
                          .toList();
                      // Order
                      systemPlaylists.sort((a, b) {
                        final ai = systemOrder.indexOf(a.systemKey ?? '');
                        final bi = systemOrder.indexOf(b.systemKey ?? '');
                        return ai.compareTo(bi);
                      });

                      return Column(
                        children: List.generate(systemPlaylists.length, (
                          index,
                        ) {
                          final p = systemPlaylists[index];
                          final icon =
                              systemIcon[p.systemKey] ?? Assets.svgMusicIcon;
                          final color =
                              systemColor[p.systemKey] ?? AppColors.mildBlue;
                          return MusicListTile(
                            margin: 7.w,
                            height: 66.h,
                            borderRadius: 10.r,
                            backgroundColor: AppColors.musicTileBackgroundColor,
                            cardHeight: 50.h,
                            cardWidth: 50.w,
                            cardRadius: 7.r,
                            cardIconAsset: icon,
                            cardIconSize: 32.r,
                            isSvgCardIcon: icon.contains('.svg'),
                            title: p.name,
                            noLogoGradientColor: [
                              color.withValues(alpha: 0.21),
                              color,
                            ],
                            subtitle: '${p.songCount} Songs',
                            trailingIconAsset: Assets.svgMenuIcon,
                            trailingIconHeight: 19.5.h,
                            trailingIconWidth: 3.w,
                            trailingMargin: 10.w,
                            songLength: '5:20',
                            songLengthRequired: true,
                            onTap: () {
                              context.push(
                                '/dashboard/playlist-detail',
                                extra: {
                                  'playlist': p,
                                  'assetIcon': icon,
                                  'colors': [
                                    color.withValues(alpha: 0.21),
                                    color,
                                  ],
                                },
                              );
                            },
                            onPlayTap: () {
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
                                builder: (_) => BlocProvider.value(
                                  value: context.read<PlaylistBloc>(),
                                  child: PlaylistMenuScreen(
                                    playlist: p,
                                    playlistIconAsset: icon,
                                    playlistGradientColors: [
                                      color.withValues(alpha: 0.21),
                                      color,
                                    ],
                                    isSystemPlaylist: true,
                                    systemKeyOrId: p.systemKey!,
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      );
                    },
                    orElse: () => Column(),
                  );
                },
              ),
              SizedBox(height: 33.h),
              BlocBuilder<PlaylistBloc, PlaylistState>(
                builder: (context, state) {
                  int userCount = 0;
                  state.maybeWhen(
                    loaded: (all, systemPlaylistSongs) => userCount = all
                        .where((p) => (p.isSystem != true))
                        .length,
                    orElse: () {},
                  );
                  return Texts(
                    'My PlayLists ($userCount)',
                    fontSize: 18,
                    fontWeight: AppFontWeights.medium,
                    fontFamily: AppFonts.inter,
                  );
                },
              ),
              SizedBox(height: 15.h),
              BlocBuilder<PlaylistBloc, PlaylistState>(
                builder: (context, state) {
                  return state.maybeWhen(
                    loaded: (allPlaylists, systemPlaylistSongs) {
                      final userPlaylists = allPlaylists
                          .where((p) => (p.isSystem != true))
                          .cast<domain.Playlist>()
                          .toList();
                      return Column(
                        children: List.generate(userPlaylists.length, (index) {
                          final p = userPlaylists[index];
                          final hasCover = (p.coverPath?.isNotEmpty ?? false);
                          final coverAsset =
                              hasCover ? p.coverPath! : Assets.svgMusicIcon;
                          final coverIsSvg = coverAsset.contains('.svg');
                          return MusicListTile(
                            margin: 7.w,
                            height: 66.h,
                            borderRadius: 10.r,
                            backgroundColor: AppColors.musicTileBackgroundColor,
                            cardHeight: 50.h,
                            cardWidth: 50.w,
                            cardRadius: 7.r,
                            cardIconAsset: coverAsset,
                            cardIconSize: 32.r,
                            isSvgCardIcon: coverIsSvg,
                            isSvgColorNeeded: coverIsSvg,
                            title: p.name,
                            subtitle: '${p.songCount} Songs',
                            trailingIconAsset: Assets.svgMenuIcon,
                            trailingIconHeight: 19.5.h,
                            trailingIconWidth: 3.w,
                            trailingMargin: 10.w,
                            onTap: () {
                              context.push(
                                '/dashboard/playlist-detail',
                                extra: {
                                  'playlist': p,
                                  'assetIcon': coverAsset,
                                  'colors': [
                                    AppColors.primaryOrange.withValues(
                                      alpha: 0.21,
                                    ),
                                    AppColors.primaryOrange,
                                  ],
                                },
                              );
                            },
                            onPlayTap: () {
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
                                builder: (_) => BlocProvider.value(
                                  value: context.read<PlaylistBloc>(),
                                  child: PlaylistMenuScreen(
                                    playlist: p,
                                    playlistIconAsset: coverAsset,
                                    playlistGradientColors: [
                                      AppColors.primaryOrange.withValues(
                                        alpha: 0.21,
                                      ),
                                      AppColors.primaryOrange,
                                    ],
                                    isSystemPlaylist: false,
                                    systemKeyOrId: p.id.toString(),
                                    onRename: () async {
                                      final result =
                                          await showModalBottomSheet<String>(
                                            context: context,
                                            backgroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(40.r),
                                                  ),
                                            ),
                                            isScrollControlled: true,
                                            builder: (_) => BlocProvider.value(
                                              value: context
                                                  .read<PlaylistBloc>(),
                                              child: RenamePlaylistBottomSheet(
                                                playlist: p,
                                              ),
                                            ),
                                          );
                                      if (!mounted) return;
                                      if (result != null && result.isNotEmpty) {
                                        showSnackBar(
                                          context,
                                          () {},
                                          message:
                                              'Playlist renamed successfully',
                                          alertBannerLocation:
                                              AlertBannerLocation.bottom,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      );
                    },
                    orElse: () => Column(),
                  );
                },
              ),
              SizedBox(height: 90.h),
            ],
          ),
        ),
      ),
    );
  }
}
