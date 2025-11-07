import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/themes/color.dart';
import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/albums/bloc/album_bloc.dart';
import '../../../../features/albums/domain/entities/album.dart';
import '../../../../features/albums/domain/repositories/album_repository.dart';
import '../../../../features/playlists/bloc/playlist_bloc.dart';
import '../../../../features/songs/data/models/song_model.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../themes/font.dart';
import '../../../../utills/globals.dart';
import '../../../../utills/snack_bar.dart';
import '../../music_service.dart';
import '../../../play_song/widget/playlist_bottomsheet.dart';
import 'sort_by_bottomsheet.dart';

class AlbumListScreen extends StatefulWidget {
  const AlbumListScreen({super.key});

  @override
  State<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends State<AlbumListScreen> {
  int selectedIndex = 0; // Default to Album Name
  int selectedOrder = 0; // 0 = ascending, 1 = descending
  String selectedAlbumSort = albumSortByItems[0].title;
  var musicService = MusicPlayerService();

  @override
  void initState() {
    super.initState();
    context.read<AlbumBloc>().add(const AlbumEvent.fetchAllAlbums());
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
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    context.push('/dashboard/select-albums');
                  },
                  child: Row(
                    children: [
                      SvgPicture.asset(Assets.svgSongsCount),
                      SizedBox(width: 10.w),
                      BlocBuilder<AlbumBloc, AlbumState>(
                        builder: (context, state) {
                          return state.maybeWhen(
                            loaded: (albums, _) => Texts(
                              '${albums.length} Albums',
                              fontSize: 14.sp,
                              fontWeight: AppFontWeights.regular,
                              color: AppColors.textColor,
                            ),
                            orElse: () => Texts(
                              '0 Albums',
                              fontSize: 14.sp,
                              fontWeight: AppFontWeights.regular,
                              color: AppColors.textColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Spacer(),
                SizedBox(width: 5.w),
                GestureDetector(
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
                      builder: (_) => BlocProvider.value(
                        value: context.read<AlbumBloc>(),
                        child: AlbumSortByBottomSheet(
                          selectedIndex: selectedIndex,
                          selectedOrder: selectedOrder,
                          onItemSelected: (index, order) {
                            setState(() {
                              selectedIndex = index;
                              selectedOrder = order;
                              selectedAlbumSort = albumSortByItems[index].title;
                            });
                            // Trigger Bloc sort event
                            context.read<AlbumBloc>().add(
                              AlbumEvent.sortAlbums(index, order),
                            );
                            // Close bottom sheet safely
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (Navigator.canPop(context))
                                Navigator.pop(context);
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: SvgPicture.asset(Assets.svgFilter),
                ),
                SizedBox(width: 10.w),
              ],
            ),
            SizedBox(height: 25.h),
            Expanded(
              child: BlocBuilder<AlbumBloc, AlbumState>(
                builder: (context, state) {
                  return state.when(
                    initial: () => const SizedBox(),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    loaded: (albums, _) {
                      if (albums.isEmpty) {
                        return Center(
                          child: Texts(
                            'No albums found',
                            fontSize: 16.sp,
                            color: AppColors.mediumDarkGrey,
                          ),
                        );
                      }
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 5.h,
                          crossAxisSpacing: 20.w,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: albums.length,
                        itemBuilder: (context, index) {
                          final album = albums[index];
                          final albumArtworkPath =
                              (album.artworkPath?.isNotEmpty ?? false)
                                  ? album.artworkPath!
                                  : Assets.svgAlbum;
                          return GestureDetector(
                            onTap: () {
                              context.push(
                                '/dashboard/album-detail',
                                extra: album,
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GradientCard(
                                  height: 120.h,
                                  width: 120.w,
                                  colors: [
                                    AppColors.mildOrange.withValues(
                                      alpha: 0.21,
                                    ),
                                    AppColors.mildOrange,
                                  ],
                                  borderRadius: 13.r,
                                  iconAsset: albumArtworkPath,
                                  iconSize: 66.51.r,
                                  onTap: () {
                                    context.push(
                                      '/dashboard/album-detail',
                                      extra: album,
                                    );
                                  },
                                  margin: 0,
                                ),
                                SizedBox(height: 6.h),
                                SizedBox(
                                  width: 118.w,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Texts(
                                              album.name,
                                              fontFamily: AppFonts.inter,
                                              fontWeight: AppFontWeights.medium,
                                              fontSize: 14.sp,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Texts(
                                              '${album.songCount} songs',
                                              fontFamily: AppFonts.inter,
                                              fontWeight:
                                                  AppFontWeights.regular,
                                              fontSize: 10.sp,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 5.w),
                                      InkWell(
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
                                            builder: (_) =>
                                                _buildAlbumMenu(context, album),
                                          );
                                        },
                                        child: SvgPicture.asset(
                                          Assets.svgMenuIcon,
                                          height: 21.5.h,
                                          width: 21.5.w,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    error: (message) => Center(
                      child: Texts(
                        'Error: $message',
                        fontSize: 14.sp,
                        color: Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumMenu(BuildContext context, Album album) {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    final albumArtworkPath = (album.artworkPath?.isNotEmpty ?? false)
        ? album.artworkPath!
        : Assets.svgAlbum;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.63.sh),
      padding: EdgeInsets.only(top: 10.h, bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 10.h),
          Flexible(
            child: Column(
              children: [
                // Album info
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
                      AppColors.mildOrange,
                    ],
                    cardIconAsset: albumArtworkPath,
                    cardIconSize: 32.r,
                    isSvgCardIcon: true,
                    title: album.name,
                    subtitle: '${album.songCount} Songs',
                    trailingIconAsset: Assets.svgIcShare,
                    trailingIconHeight: 25.h,
                    trailingIconWidth: 25.w,
                    trailingMargin: 2.w,
                    onTap: () {
                      showSnackBar(
                        context,
                        () {},
                        message: 'Share album feature coming soon',
                        alertBannerLocation: AlertBannerLocation.bottom,
                      );
                    },
                    onPlayTap: () {
                      showSnackBar(
                        context,
                        () {},
                        message: 'Play album feature coming soon',
                        alertBannerLocation: AlertBannerLocation.bottom,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: albumMenuItems.length,
                    itemBuilder: (context, index) {
                      final menuItem = albumMenuItems[index];
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(
                              horizontal: 0.w,
                              vertical: 0.h,
                            ),
                            leading: SvgPicture.asset(
                              menuItem.icon,
                              height: 24,
                              width: 24,
                            ),
                            title: Texts(
                              menuItem.title,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppFonts.inter,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _handleAlbumMenuAction(menuItem.title, album);
                            },
                          ),
                          if (index == 3) ...[
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
                    margin: EdgeInsets.symmetric(horizontal: 15.w),
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

  void _handleAlbumMenuAction(String menuTitle, Album album) {
    if (menuTitle == S.of(context).play) {
      _playAlbum(album);
    } else if (menuTitle == S.of(context).playNext) {
      _playNextAlbum(album);
    } else if (menuTitle == S.of(context).addToQueue) {
      _addAlbumToQueue(album);
    } else if (menuTitle == S.of(context).addToPlaylist) {
      _addAlbumToPlaylist(album);
    }
  }

  // Play album
  void _playAlbum(Album album) async {
    try {
      final _repo = locator<AlbumRepository>();
      List<SongsModel> albumSongs = (await _repo.getSongsForAlbum(
        album.id!,
      )).cast<SongsModel>();

      if (albumSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Album contains no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      await musicService.setPlaylist(albumSongs, startIndex: 0);
      await musicService.play();

      showSnackBar(
        context,
        () {},
        message: "Playing ${albumSongs.length} songs from ${album.name}",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error playing album: $e",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Play next album
  void _playNextAlbum(Album album) async {
    try {
      final _repo = locator<AlbumRepository>();
      List<SongsModel> albumSongs = (await _repo.getSongsForAlbum(
        album.id!,
      )).cast<SongsModel>();

      if (albumSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Album contains no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      if (musicService.songs.isEmpty) {
        await musicService.setPlaylist(albumSongs, startIndex: 0);
        await musicService.play();
      } else {
        final currentIndex = musicService.currentIndex;
        final insertIndex = currentIndex + 1;
        final newSongsList = List<SongsModel>.from(musicService.songs);

        final songsToAdd = albumSongs.where((song) {
          return !newSongsList.any(
            (existingSong) => existingSong.id == song.id,
          );
        }).toList();

        newSongsList.insertAll(insertIndex, songsToAdd);

        await musicService.setPlaylist(
          newSongsList,
          startIndex: currentIndex >= 0 ? currentIndex : 0,
          autoPlay: false,
        );
      }

      showSnackBar(
        context,
        () {},
        message:
            "${albumSongs.length} songs from ${album.name} added to play next",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error adding album to play next",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add album to queue
  void _addAlbumToQueue(Album album) async {
    try {
      final _repo = locator<AlbumRepository>();
      List<SongsModel> albumSongs = (await _repo.getSongsForAlbum(
        album.id!,
      )).cast<SongsModel>();

      if (albumSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Album contains no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final newSongsList = List<SongsModel>.from(musicService.songs);
      int addedCount = 0;

      for (final song in albumSongs) {
        final existingIndex = newSongsList.indexWhere(
          (existingSong) => existingSong.id == song.id,
        );

        if (existingIndex == -1) {
          newSongsList.add(song);
          addedCount++;
        }
      }

      await musicService.setPlaylist(newSongsList);

      showSnackBar(
        context,
        () {},
        message: "$addedCount songs from ${album.name} added to queue",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error adding album to queue",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add album to playlist
  void _addAlbumToPlaylist(Album album) async {
    try {
      // Capture PlaylistBloc before async operations
      final playlistBloc = context.read<PlaylistBloc>();

      final _repo = locator<AlbumRepository>();
      List<SongsModel> albumSongs = (await _repo.getSongsForAlbum(
        album.id!,
      )).cast<SongsModel>();

      if (albumSongs.isEmpty) {
        if (mounted) {
          showSnackBar(
            context,
            () {},
            message: "Album contains no songs",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
        return;
      }

      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
          ),
          isScrollControlled: true,
          builder: (_) => BlocProvider.value(
            value: playlistBloc,
            child: PlaylistBottomSheet(songsList: albumSongs),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error fetching songs from album: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }
}
