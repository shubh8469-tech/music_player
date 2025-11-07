import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/themes/color.dart';
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/artists/bloc/artist_bloc.dart';
import '../../../../features/artists/domain/entities/artist.dart';
import '../../../../features/artists/domain/repositories/artist_repository.dart';
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

class ArtistListScreen extends StatefulWidget {
  const ArtistListScreen({super.key});

  @override
  State<ArtistListScreen> createState() => _ArtistListScreenState();
}

class _ArtistListScreenState extends State<ArtistListScreen> {
  int selectedIndex = 0; // Default to Artist Name
  int selectedOrder = 0; // 0 = ascending, 1 = descending
  String selectedArtistSort = artistSortByItems[0].title;
  var musicService = MusicPlayerService();

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
          left: 20.w,
          right: 20.w,
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
                        SizedBox(width: 10.w),
                        BlocBuilder<ArtistBloc, ArtistState>(
                          builder: (context, state) {
                            return state.maybeWhen(
                              loaded:
                                  (artists, _) => Texts(
                                    '${artists.length} Artists',
                                    fontSize: 14.sp,
                                    fontWeight: AppFontWeights.regular,
                                    color: AppColors.textColor,
                                  ),
                              orElse:
                                  () => Texts(
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
                                selectedArtistSort = artistSortByItems[index].title;
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
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
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
                        children:
                            artists.map((artist) {
                              final artistArtworkPath =
                                  (artist.artworkPath?.isNotEmpty ?? false)
                                      ? artist.artworkPath!
                                      : Assets.svgMusicIcon;
                              return MusicListTile(
                                margin: 7.w,
                                height: 66.h,
                                borderRadius: 10.r,
                                backgroundColor:
                                    AppColors.musicTileBackgroundColor,
                                cardHeight: 50.h,
                                cardWidth: 50.w,
                                cardRadius: 100.r,
                                cardIconAsset: artistArtworkPath,
                                isSvgColorNeeded: false,
                                cardIconSize: 32.r,
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
                    error:
                        (message) => Center(
                          child: Texts(
                            'Error: $message',
                            fontSize: 14.sp,
                            color: Colors.red,
                          ),
                        ),
                  );
                },
              ),
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

    final artistArtworkPath = (artist.artworkPath?.isNotEmpty ?? false)
        ? artist.artworkPath!
        : Assets.svgMusicIcon;

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
                // Artist info
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
                Expanded(
                  child: ListView.builder(
                    itemCount: artistMenuItems.length,
                    itemBuilder: (context, index) {
                      final menuItem = artistMenuItems[index];
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
                              _handleArtistMenuAction(menuItem.title, artist);
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

  void _handleArtistMenuAction(String menuTitle, Artist artist) {
    if (menuTitle == S.of(context).play) {
      _playArtist(artist);
    } else if (menuTitle == S.of(context).playNext) {
      _playNextArtist(artist);
    } else if (menuTitle == S.of(context).addToQueue) {
      _addArtistToQueue(artist);
    } else if (menuTitle == S.of(context).addToPlaylist) {
      _addArtistToPlaylist(artist);
    }
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

      await musicService.setPlaylist(artistSongs, startIndex: 0);
      await musicService.play();

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

      if (musicService.songs.isEmpty) {
        await musicService.setPlaylist(artistSongs, startIndex: 0);
        await musicService.play();
      } else {
        final currentIndex = musicService.currentIndex;
        final insertIndex = currentIndex + 1;
        final newSongsList = List<SongsModel>.from(musicService.songs);

        final songsToAdd = artistSongs.where((song) {
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
            "${artistSongs.length} songs from ${artist.name} added to play next",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
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

      final newSongsList = List<SongsModel>.from(musicService.songs);
      int addedCount = 0;

      for (final song in artistSongs) {
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
        message: "$addedCount songs from ${artist.name} added to queue",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
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
            child: PlaylistBottomSheet(songsList: artistSongs),
          ),
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
}
