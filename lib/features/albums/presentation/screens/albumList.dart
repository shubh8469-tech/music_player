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
import 'package:music_app/themes/color.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:music_app/core/widgets/gradientCard.dart';
import 'package:music_app/core/widgets/MusicListTile.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/albums/presentation/bloc/album_bloc.dart';
import 'package:music_app/features/albums/domain/entities/album.dart';
import 'package:music_app/features/albums/domain/repositories/album_repository.dart';
import 'package:music_app/features/playlists/presentation/bloc/playlist_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/core/utils/globals.dart';
import 'package:music_app/core/utils/snack_bar.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_event.dart';
import 'package:music_app/core/common_screens/image_crop_screen.dart';
import 'package:music_app/core/widgets/common_modal_bottom_sheet.dart';
import 'edit_album_tags_screen.dart';
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
          left: 15.w,
          right: 15.w,
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
                      SizedBox(width: 8.w),
                      SizedBox(
                        height: 38
                            .h, // Increase height so padding doesn't zero it out
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8.h,
                          ), // Leave some room for the line
                          child: VerticalDivider(
                            color: AppColors.mediumDarkGrey.withOpacity(0.5),
                            width: 1.w, // Total space the widget occupies
                            thickness:
                                1.2.w, // The actual thickness of the line
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
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
                SizedBox(width: 5.w),
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
                          childAspectRatio: 0.9,
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
                                      // Spacer(width: 5.w),
                                      InkWell(
                                        onTap: () {
                                          showModalBottomSheet(
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
                                            builder: (_) =>
                                                _buildAlbumMenu(context, album),
                                          );
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4.r,
                                            horizontal: 2.r,
                                          ),
                                          child: SvgPicture.asset(
                                            Assets.svgMenuIcon,
                                            height: 21.5.h,
                                            width: 21.5.w,
                                          ),
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
    final localization = S.of(context);
    final albumArtworkPath = (album.artworkPath?.isNotEmpty ?? false)
        ? album.artworkPath!
        : Assets.svgAlbum;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: 10.h, bottom: 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(Assets.svgIcLineBottom),
            SizedBox(height: 10.h),
            Column(
              children: [
                // Album header (similar to playlist/folder header)
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
                    cardWidth: 50.h,
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

                // Menu items (flat list, like playlist/folder)
                _buildMenuItem(
                  icon: Assets.svgPlayBlackBorder,
                  title: localization.play,
                  onTap: () {
                    Navigator.pop(context);
                    _handleAlbumMenuAction(localization.play, album);
                  },
                ),
                _buildMenuItem(
                  icon: Assets.svgIcMenuPlaynext,
                  title: localization.playNext,
                  onTap: () {
                    Navigator.pop(context);
                    _handleAlbumMenuAction(localization.playNext, album);
                  },
                ),
                _buildMenuItem(
                  icon: Assets.svgIcMenuQueue,
                  title: localization.addToQueue,
                  onTap: () {
                    Navigator.pop(context);
                    _handleAlbumMenuAction(localization.addToQueue, album);
                  },
                ),
                _buildMenuItem(
                  icon: Assets.svgIcMenuPlaylist,
                  title: localization.addToPlaylist,
                  onTap: () {
                    Navigator.pop(context);
                    _handleAlbumMenuAction(localization.addToPlaylist, album);
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Assets.svgIcCover,
                  title: localization.changeCover,
                  onTap: () {
                    Navigator.pop(context);
                    _handleAlbumMenuAction(localization.changeCover, album);
                  },
                ),
                _buildMenuItem(
                  icon: Assets.svgIcEdit,
                  title: localization.editTags,
                  onTap: () {
                    Navigator.pop(context);
                    _handleAlbumMenuAction(localization.editTags, album);
                  },
                ),
              ],
            ),
            // Cancel button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
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
                margin: EdgeInsets.only(top: 8.h, left: 15.w, right: 15.w),
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
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity(horizontal: 0.w, vertical: 0.h),
      leading: SvgPicture.asset(icon, height: 24, width: 24),
      title: Texts(
        title,
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        fontFamily: AppFonts.inter,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.black.withValues(alpha: .1),
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
    } else if (menuTitle == S.of(context).changeCover) {
      _handleAlbumChangeCover(album);
    } else if (menuTitle == S.of(context).editTags) {
      _handleEditAlbumTags(album);
    }
  }

  void _handleEditAlbumTags(Album album) {
    showCommonConfirmationBottomSheet(
      context: context,
      title: S.of(context).editTags,
      message: 'Do you want to edit tags for "${album.name}"?',
      confirmButtonText: S.of(context).editTags,
      onConfirm: (sheetContext) async {
        Navigator.pop(sheetContext);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<AlbumBloc>(),
              child: EditAlbumTagsScreen(album: album),
            ),
          ),
        );
      },
    );
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

      final bloc = context.read<MusicPlayerBloc>();
      bloc.add(SetPlaylistEvent(albumSongs.map((m) => m.toDomain()).toList(), startIndex: 0));
      bloc.add(const PlayEvent());

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

      final bloc = context.read<MusicPlayerBloc>();
      if (bloc.state.songs.isEmpty) {
        bloc.add(SetPlaylistEvent(albumSongs.map((m) => m.toDomain()).toList(), startIndex: 0));
        bloc.add(const PlayEvent());
        showSnackBar(
          context,
          () {},
          message: "Playing ${albumSongs.length} songs from ${album.name}",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      } else {
        bloc.add(PlayNextMultipleSongsEvent(albumSongs.map((m) => m.toDomain()).toList()));
        showSnackBar(
          context,
          () {},
          message: "${albumSongs.length} songs added to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
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

      final bloc = context.read<MusicPlayerBloc>();
      bloc.add(AddMultipleSongsToQueueEvent(albumSongs.map((m) => m.toDomain()).toList()));

      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "${albumSongs.length} songs added to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }

      // final newSongsList = List<SongsModel>.from(musicService.songs);
      // int addedCount = 0;
      //
      // for (final song in albumSongs) {
      //   final existingIndex = newSongsList.indexWhere(
      //     (existingSong) => existingSong.id == song.id,
      //   );
      //
      //   if (existingIndex == -1) {
      //     newSongsList.add(song);
      //     addedCount++;
      //   }
      // }
      //
      // await musicService.setPlaylist(newSongsList, autoPlay: false);
      //
      // if(addedCount < 1){
      //   showSnackBar(
      //     context,
      //         () {},
      //     message: "Songs already added to queue",
      //     alertBannerLocation: AlertBannerLocation.bottom,
      //   );
      // }
      // else{
      //   showSnackBar(
      //     context,
      //         () {},
      //     message: "$addedCount songs from ${album.name} added to queue",
      //     alertBannerLocation: AlertBannerLocation.bottom,
      //   );
      // }
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
        showCommonAddToPlaylistBottomSheet(
          context,
          songsList: albumSongs,
          playlistBloc: playlistBloc,
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

  Future<void> _handleAlbumChangeCover(Album album) async {
    if (album.id == null) return;
    final action = await _showChangeCoverSelectionSheet();
    if (!mounted || action == null) return;

    if (action == _ChangeCoverAction.localGallery) {
      await _handleAlbumLocalGalleryCover(album);
    } else if (action == _ChangeCoverAction.searchOnline) {
      showSnackBar(
        context,
        () {},
        message: 'Search online feature coming soon',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  Future<_ChangeCoverAction?> _showChangeCoverSelectionSheet() {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return showModalBottomSheet<_ChangeCoverAction>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.w,
            right: 20.w,
            bottom: bottomPadding,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Center(
                  child: Texts(
                    'Select cover from',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                ),
                SizedBox(height: 24.h),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 21.w,
                    height: 21.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: SvgPicture.asset(
                      Assets.svgLocalGallery,
                      colorFilter: const ColorFilter.mode(
                        AppColors.black,
                        BlendMode.srcIn,
                      ),
                      height: 16.h,
                      width: 16.h,
                    ),
                  ),
                  title: Texts(
                    'Local gallery',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      _ChangeCoverAction.localGallery,
                    );
                  },
                ),
                Divider(
                  color: Colors.black.withOpacity(0.08),
                  height: 12.h,
                  thickness: 0.8,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 23.w,
                    height: 23.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: SvgPicture.asset(
                      Assets.svgSearch,
                      colorFilter: const ColorFilter.mode(
                        AppColors.black,
                        BlendMode.srcIn,
                      ),
                      height: 16.h,
                      width: 16.h,
                    ),
                  ),
                  title: Texts(
                    'Search online',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      _ChangeCoverAction.searchOnline,
                    );
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
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Texts(
                      'Close',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFonts.inter,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAlbumLocalGalleryCover(Album album) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

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
        showSnackBar(
          context,
          () {},
          message: 'Unable to read selected image',
          backgroundColor: Colors.red,
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => ImageCropScreen(imageBytes: bytes!),
          fullscreenDialog: true,
        ),
      );

      if (croppedBytes == null) return;

      final optimizedBytes = await _optimizeCoverImage(croppedBytes);
      final savedFile = await _persistAlbumCoverFile(album.id!, optimizedBytes);

      await _cleanupAlbumCover(album.artworkPath);
      context.read<AlbumBloc>().add(
        AlbumEvent.updateAlbumCover(album.id!, savedFile.path),
      );

      if (!mounted) return;

      showSnackBar(
        context,
        () {},
        message: 'Album cover updated successfully',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      log('Failed to update album cover: $e');
      if (!mounted) return;
      showSnackBar(
        context,
        () {},
        message: 'Failed to update cover: $e',
        backgroundColor: Colors.red,
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  Future<Uint8List> _optimizeCoverImage(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unsupported image format');
    }

    const maxDimension = 720;
    img.Image processed = decoded;
    final largestSide = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;

    if (largestSide > maxDimension) {
      if (decoded.width >= decoded.height) {
        processed = img.copyResize(
          decoded,
          width: maxDimension,
          height: (decoded.height * maxDimension / decoded.width).round(),
        );
      } else {
        processed = img.copyResize(
          decoded,
          height: maxDimension,
          width: (decoded.width * maxDimension / decoded.height).round(),
        );
      }
    }

    final optimizedBytes = img.encodeJpg(processed, quality: 85);

    return Uint8List.fromList(optimizedBytes);
  }

  Future<File> _persistAlbumCoverFile(int albumId, Uint8List bytes) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(documentsDir.path, 'covers', 'albums'));

    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'album_${albumId}_$timestamp.jpg';
    final filePath = p.join(coversDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _cleanupAlbumCover(String? existingPath) async {
    if (existingPath == null || existingPath.isEmpty) {
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final coversDirPath = p.join(documentsDir.path, 'covers', 'albums');

      if (p.isWithin(coversDirPath, existingPath)) {
        final existingFile = File(existingPath);
        if (await existingFile.exists()) {
          await existingFile.delete();
        }
      }
    } catch (e) {
      log('Failed to remove previous album cover: $e');
    }
  }
}

enum _ChangeCoverAction { localGallery, searchOnline }
