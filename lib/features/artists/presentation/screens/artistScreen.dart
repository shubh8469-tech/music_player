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
import 'package:music_app/core/widgets/MusicListTile.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/artists/presentation/bloc/artist_bloc.dart';
import 'package:music_app/features/artists/domain/entities/artist.dart';
import 'package:music_app/features/artists/domain/repositories/artist_repository.dart';
import 'package:music_app/features/playlists/presentation/bloc/playlist_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/core/utils/globals.dart';
import 'package:music_app/core/utils/snack_bar.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_event.dart';
import 'package:music_app/core/screens/common/image_crop_screen.dart';
import 'package:music_app/core/widgets/common_modal_bottom_sheet.dart';
import 'package:music_app/core/widgets/edit_tag_bottom_sheet.dart';
import 'sort_by_bottomsheet.dart';

class ArtistListScreen extends StatefulWidget {
  const ArtistListScreen({super.key});

  @override
  State<ArtistListScreen> createState() => _ArtistListScreenState();
}

class _ArtistListScreenState extends State<ArtistListScreen> {
  int selectedIndex = 0; // Default to Artist Name
  int selectedOrder = 0; // 0 = ascending, 1 = descending
  String selectedArtistSort = artistSortByItems[0].title;

  @override
  void initState() {
    super.initState();
    context.read<ArtistBloc>().add(const ArtistEvent.fetchAllArtists());
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.push('/dashboard/select-artist');
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
                        BlocBuilder<ArtistBloc, ArtistState>(
                          builder: (context, state) {
                            return state.maybeWhen(
                              loaded: (artists, _) => Texts(
                                '${artists.length} Artists',
                                fontSize: 14.sp,
                                fontWeight: AppFontWeights.regular,
                                color: AppColors.textColor,
                              ),
                              orElse: () => Texts(
                                '0 Artists',
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
                          value: context.read<ArtistBloc>(),
                          child: ArtistSortByBottomSheet(
                            selectedIndex: selectedIndex,
                            selectedOrder: selectedOrder,
                            onItemSelected: (index, order) {
                              setState(() {
                                selectedIndex = index;
                                selectedOrder = order;
                                selectedArtistSort =
                                    artistSortByItems[index].title;
                              });
                              // Trigger Bloc sort event
                              context.read<ArtistBloc>().add(
                                ArtistEvent.sortArtists(index, order),
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
              BlocBuilder<ArtistBloc, ArtistState>(
                builder: (context, state) {
                  return state.when(
                    initial: () => const SizedBox(),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    loaded: (artists, _) {
                      if (artists.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50.h),
                            child: Texts(
                              'No artists found',
                              fontSize: 16.sp,
                              color: AppColors.mediumDarkGrey,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: artists.map((artist) {
                          final artistArtworkPath =
                              (artist.artworkPath?.isNotEmpty ?? false)
                              ? artist.artworkPath!
                              : Assets.svgProxyArtist;
                          return MusicListTile(
                            margin: 7.w,
                            height: 66.h,
                            borderRadius: 10.r,
                            backgroundColor: AppColors.musicTileBackgroundColor,
                            cardHeight: 50.h,
                            cardWidth: 50.h,
                            cardRadius: 100.r,
                            cardIconAsset: artistArtworkPath,
                            noLogoGradientColor: [
                              AppColors.black.withValues(alpha: 0.14),
                              AppColors.black.withValues(alpha: 0.14),
                            ],
                            cardIconSize: 19.r,
                            title: artist.name,
                            subtitle:
                                '${artist.albumCount} Album${artist.albumCount != 1 ? 's' : ''} - ${artist.songCount} Songs',
                            trailingIconAsset: Assets.svgMenuIcon,
                            trailingIconHeight: 19.5.h,
                            trailingIconWidth: 3.w,
                            trailingMargin: 10.w,
                            onTap: () {
                              context.push(
                                '/dashboard/artist-detail',
                                extra: artist,
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
                                builder: (_) =>
                                    _buildArtistMenu(context, artist),
                              );
                            },
                          );
                        }).toList(),
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
              SizedBox(height: 25.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistMenu(BuildContext context, Artist artist) {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;
    final localization = S.of(context);
    final artistArtworkPath = (artist.artworkPath?.isNotEmpty ?? false)
        ? artist.artworkPath!
        : Assets.svgMusicIcon;

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
                // Artist header (similar to playlist/folder header)
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
                    cardRadius: 100.r,
                    cardIconAsset: artistArtworkPath,
                    cardIconSize: 32.r,
                    isSvgColorNeeded: false,
                    title: artist.name,
                    subtitle:
                        '${artist.albumCount} Album${artist.albumCount != 1 ? 's' : ''} - ${artist.songCount} Songs',
                    trailingIconAsset: Assets.svgIcShare,
                    trailingIconHeight: 25.h,
                    trailingIconWidth: 25.w,
                    trailingMargin: 2.w,
                    onTap: () {
                      showSnackBar(
                        context,
                        () {},
                        message: 'Share artist feature coming soon',
                        alertBannerLocation: AlertBannerLocation.bottom,
                      );
                    },
                    onPlayTap: () {
                      showSnackBar(
                        context,
                        () {},
                        message: 'Play artist feature coming soon',
                        alertBannerLocation: AlertBannerLocation.bottom,
                      );
                    },
                  ),
                ),

                // Menu items (flat list)
                _buildMenuItem(
                  icon: Assets.svgPlayBlackBorder,
                  title: localization.play,
                  onTap: () {
                    Navigator.pop(context);
                    _handleArtistMenuAction(localization.play, artist);
                  },
                ),
                _buildMenuItem(
                  icon: Assets.svgIcMenuPlaynext,
                  title: localization.playNext,
                  onTap: () {
                    Navigator.pop(context);
                    _handleArtistMenuAction(localization.playNext, artist);
                  },
                ),
                _buildMenuItem(
                  icon: Assets.svgIcMenuQueue,
                  title: localization.addToQueue,
                  onTap: () {
                    Navigator.pop(context);
                    _handleArtistMenuAction(localization.addToQueue, artist);
                  },
                ),
                _buildMenuItem(
                  icon: Assets.svgIcMenuPlaylist,
                  title: localization.addToPlaylist,
                  onTap: () {
                    Navigator.pop(context);
                    _handleArtistMenuAction(localization.addToPlaylist, artist);
                  },
                ),
                _buildDivider(),
                _buildMenuItem(
                  icon: Assets.svgIcCover,
                  title: localization.changeCover,
                  onTap: () {
                    Navigator.pop(context);
                    _handleArtistMenuAction(localization.changeCover, artist);
                  },
                ),
                _buildMenuItem(
                  icon: Assets.svgIcEdit,
                  title: localization.editTags,
                  onTap: () {
                    Navigator.pop(context);
                    _handleArtistMenuAction(localization.editTags, artist);
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

  void _handleArtistMenuAction(String menuTitle, Artist artist) {
    if (menuTitle == S.of(context).play) {
      _playArtist(artist);
    } else if (menuTitle == S.of(context).playNext) {
      _playNextArtist(artist);
    } else if (menuTitle == S.of(context).addToQueue) {
      _addArtistToQueue(artist);
    } else if (menuTitle == S.of(context).addToPlaylist) {
      _addArtistToPlaylist(artist);
    } else if (menuTitle == S.of(context).changeCover) {
      _handleArtistChangeCover(artist);
    } else if (menuTitle == S.of(context).editTags) {
      _handleEditArtistTags(artist);
    }
  }

  void _handleEditArtistTags(Artist artist) {
    showCommonConfirmationBottomSheet(
      context: context,
      title: S.of(context).editTags,
      message: 'Do you want to edit tags for "${artist.name}"?',
      confirmButtonText: S.of(context).editTags,
      onConfirm: (sheetContext) async {
        Navigator.pop(sheetContext);
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (bottomSheetContext) => BlocProvider.value(
            value: context.read<ArtistBloc>(),
            child: EditTagBottomSheet(
              initialValue: artist.name,
              title: S.of(bottomSheetContext).editTags,
              onSave: (newName) {
                if (artist.id != null && newName.trim().isNotEmpty) {
                  context.read<ArtistBloc>().add(
                        ArtistEvent.updateArtistName(artist.id!, newName),
                      );
                  showSnackBar(
                    bottomSheetContext,
                    () {},
                    message: 'Artist name updated successfully',
                    alertBannerLocation: AlertBannerLocation.bottom,
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  // Play artist
  void _playArtist(Artist artist) async {
    try {
      final _repo = locator<ArtistRepository>();
      List<SongsModel> artistSongs = (await _repo.getSongsForArtist(
        artist.id!,
      )).cast<SongsModel>();

      if (artistSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Artist has no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final bloc = context.read<MusicPlayerBloc>();
      bloc.add(SetPlaylistEvent(artistSongs.map((m) => m.toDomain()).toList(), startIndex: 0));
      bloc.add(const PlayEvent());

      showSnackBar(
        context,
        () {},
        message: "Playing ${artistSongs.length} songs from ${artist.name}",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error playing artist: $e",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Play next artist
  void _playNextArtist(Artist artist) async {
    try {
      final _repo = locator<ArtistRepository>();
      List<SongsModel> artistSongs = (await _repo.getSongsForArtist(
        artist.id!,
      )).cast<SongsModel>();

      if (artistSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Artist has no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final bloc = context.read<MusicPlayerBloc>();
      if (bloc.state.songs.isEmpty) {
        bloc.add(SetPlaylistEvent(artistSongs.map((m) => m.toDomain()).toList(), startIndex: 0));
        bloc.add(const PlayEvent());
        showSnackBar(
          context,
          () {},
          message: "Playing ${artistSongs.length} songs from ${artist.name}",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      } else {
        bloc.add(PlayNextMultipleSongsEvent(artistSongs.map((m) => m.toDomain()).toList()));
        showSnackBar(
          context,
          () {},
          message: "${artistSongs.length} songs added to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error adding artist to play next",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add artist to queue
  void _addArtistToQueue(Artist artist) async {
    try {
      final _repo = locator<ArtistRepository>();
      List<SongsModel> artistSongs = (await _repo.getSongsForArtist(
        artist.id!,
      )).cast<SongsModel>();

      if (artistSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Artist has no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final bloc = context.read<MusicPlayerBloc>();
      bloc.add(AddMultipleSongsToQueueEvent(artistSongs.map((m) => m.toDomain()).toList()));

      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "${artistSongs.length} songs added to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }

      // final newSongsList = List<SongsModel>.from(musicService.songs);
      // int addedCount = 0;
      //
      // for (final song in artistSongs) {
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
      //     message: "$addedCount songs from ${artist.name} added to queue",
      //     alertBannerLocation: AlertBannerLocation.bottom,
      //   );
      // }
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error adding artist to queue",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add artist to playlist
  void _addArtistToPlaylist(Artist artist) async {
    try {
      // Capture PlaylistBloc before async operations
      final playlistBloc = context.read<PlaylistBloc>();

      final _repo = locator<ArtistRepository>();
      List<SongsModel> artistSongs = (await _repo.getSongsForArtist(
        artist.id!,
      )).cast<SongsModel>();

      if (artistSongs.isEmpty) {
        if (mounted) {
          showSnackBar(
            context,
            () {},
            message: "Artist has no songs",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
        return;
      }

      if (mounted) {
        showCommonAddToPlaylistBottomSheet(
          context,
          songsList: artistSongs,
          playlistBloc: playlistBloc,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error fetching songs from artist: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  Future<void> _handleArtistChangeCover(Artist artist) async {
    if (artist.id == null) return;
    final action = await _showArtistChangeCoverSheet();
    if (!mounted || action == null) return;

    if (action == _ChangeCoverAction.localGallery) {
      await _handleArtistLocalGalleryCover(artist);
    } else if (action == _ChangeCoverAction.searchOnline) {
      showSnackBar(
        context,
        () {},
        message: 'Search online feature coming soon',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  Future<_ChangeCoverAction?> _showArtistChangeCoverSheet() {
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

  Future<void> _handleArtistLocalGalleryCover(Artist artist) async {
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

      final optimizedBytes = await _optimizeArtistCoverImage(croppedBytes);
      final savedFile = await _persistArtistCoverFile(
        artist.id!,
        optimizedBytes,
      );

      await _cleanupArtistCover(artist.artworkPath);
      context.read<ArtistBloc>().add(
        ArtistEvent.updateArtistCover(artist.id!, savedFile.path),
      );

      if (!mounted) return;

      showSnackBar(
        context,
        () {},
        message: 'Artist cover updated successfully',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      log('Failed to update artist cover: $e');
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

  Future<Uint8List> _optimizeArtistCoverImage(Uint8List bytes) async {
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

  Future<File> _persistArtistCoverFile(int artistId, Uint8List bytes) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(documentsDir.path, 'covers', 'artists'));

    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'artist_${artistId}_$timestamp.jpg';
    final filePath = p.join(coversDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _cleanupArtistCover(String? existingPath) async {
    if (existingPath == null || existingPath.isEmpty) {
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final coversDirPath = p.join(documentsDir.path, 'covers', 'artists');

      if (p.isWithin(coversDirPath, existingPath)) {
        final existingFile = File(existingPath);
        if (await existingFile.exists()) {
          await existingFile.delete();
        }
      }
    } catch (e) {
      log('Failed to remove previous artist cover: $e');
    }
  }
}

enum _ChangeCoverAction { localGallery, searchOnline }
