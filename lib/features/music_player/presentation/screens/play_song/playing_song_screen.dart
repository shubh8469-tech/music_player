import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:music_app/core/widgets/app_bar_with_icon_title.dart';
import 'package:music_app/core/widgets/common_modal_bottom_sheet.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_event.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_state.dart';
import 'package:music_app/features/playlists/presentation/bloc/playlist_bloc.dart';
import 'package:music_app/features/songs/presentation/bloc/songs_bloc.dart';
import 'package:music_app/features/music_player/presentation/screens/play_song/widget/audio_player.dart';
import 'package:music_app/features/music_player/presentation/screens/play_song/widget/audio_player_provider.dart';
import 'package:music_app/core/utils/globals.dart';

import 'package:music_app/core/widgets/gradientCard.dart';
import 'package:music_app/core/widgets/song_menu_screen.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/features/music_player/data/services/unified_equalizer_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/core/utils/snack_bar.dart';

class PlayingSongArgs {
  final List<SongsModel> songs;

  PlayingSongArgs({required this.songs});
}

class PlayingSongScreen extends StatefulWidget {
  const PlayingSongScreen({super.key, required this.songs});

  final List<SongsModel> songs;

  @override
  State<PlayingSongScreen> createState() => _PlayingSongScreenState();
}

class _PlayingSongScreenState extends State<PlayingSongScreen> {
  bool isFavorite = false;
  final UnifiedEqualizerService equalizerService = UnifiedEqualizerService();

  MusicPlayerBloc get _bloc => context.read<MusicPlayerBloc>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _bloc.state;
      if (state.songs.isEmpty || state.songs != widget.songs) {
        _bloc.add(SetPlaylistEvent(
          widget.songs.map((m) => m.toDomain()).toList(),
          startIndex: state.currentIndex ?? 0,
        ));
      }
      if (mounted) {
        setState(() => isFavorite = state.currentSong?.isFavorite ?? false);
      }
    });
  }

  Future<void> _toggleFavorite(MusicPlayerState state) async {
    if (state.songs.isEmpty || state.currentIndex == null) return;

    final currentSong = state.currentSong;
    if (currentSong == null) return;
    final newFavoriteStatus = !isFavorite;

    try {
      context.read<SongsBloc>().add(SongsEvent.updateSongFavorite(currentSong.id!, newFavoriteStatus));

      if (newFavoriteStatus) {
        context.read<PlaylistBloc>().add(
          PlaylistEvent.addSongToPlaylist(
            await _getFavoritesPlaylistId(),
            currentSong.id!,
            0, // Position doesn't matter for favorites
          ),
        );
      } else {
        context.read<PlaylistBloc>().add(PlaylistEvent.removeSongFromPlaylist(await _getFavoritesPlaylistId(), currentSong.id!));
      }

      setState(() {
        isFavorite = newFavoriteStatus;
      });

      // Sync the music player's playlist so when we come back to this screen,
      // state.currentSong?.isFavorite is correct and svgFavOn shows.
      final updatedSongs = state.songs
          .map((s) => s.id == currentSong.id ? s.copyWith(isFavorite: newFavoriteStatus) : s)
          .toList();
      _bloc.syncPlaylistWithUpdatedSongsFromModels(updatedSongs);

      showSnackBar(
        context,
        () {},
        message: newFavoriteStatus ? 'Added to favorites' : 'Removed from favorites',
        backgroundColor: AppColors.primaryOrange,
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error updating favorites: $e', backgroundColor: Colors.red, alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<int> _getFavoritesPlaylistId() async {
    // Get favorites playlist ID using PlaylistBloc
    context.read<PlaylistBloc>().add(PlaylistEvent.getFavoritesPlaylistId());

    // Wait for the BLoC to process and get the favorites playlist ID
    await Future.delayed(Duration(milliseconds: 100));

    // Get the favorites playlist ID from the BLoC
    final playlistBloc = context.read<PlaylistBloc>();
    final favoritesId = playlistBloc.favoritesPlaylistId;

    if (favoritesId != null) {
      return favoritesId;
    }

    // Fallback to hardcoded value if BLoC hasn't processed yet
    return 1; // Favorites playlist is typically the first system playlist
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MusicPlayerBloc, MusicPlayerState>(
      listenWhen: (prev, curr) => (prev.songs.isNotEmpty && curr.songs.isEmpty) || prev.currentSongId != curr.currentSongId,
      listener: (context, state) {
        if (state.songs.isEmpty && mounted && context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        } else {
          setState(() => isFavorite = state.currentSong?.isFavorite ?? false);
        }
      },
      buildWhen: (prev, curr) => prev.songs != curr.songs || prev.currentIndex != curr.currentIndex || prev.currentSongId != curr.currentSongId,
      builder: (context, state) {
        if (state.songs.isEmpty) {
          return Scaffold(backgroundColor: AppColors.white, body: const SizedBox.shrink());
        }

        final currentSong = state.currentSong;
        // Do not overwrite isFavorite here: after toggling favorite we set it in setState,
        // but state.currentSong still has the old value until playlist is synced.

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBarWithIconTitle(
            backgroundColor: AppColors.primaryOrange,
            title: null,
            leading: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: EdgeInsets.only(left: 22.w),
                child: SizedBox(
                  width: 26.w,
                  height: 26.h,
                  child: SvgPicture.asset(Assets.svgIcDownArrow, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
                ),
              ),
            ),
            showBackButton: false,
            actions: [
              SizedBox(
                width: 40.w,
                height: 40.h,
                child: IconButton(
                  onPressed: () {
                    showSnackBar(
                      context,
                      () {},
                      message: 'Themes feature coming soon',
                      backgroundColor: AppColors.primaryOrange,
                      alertBannerLocation: AlertBannerLocation.bottom,
                    );
                  },
                  icon: SvgPicture.asset(Assets.svgIcShirt, height: 26.h, width: 26.w),
                ),
              ),
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
                    isScrollControlled: true,
                    builder: (_) => SongMenuScreen(
                      songMenuList: songPlayingMenuItems,
                      isPlaying: state.isPlaying,
                      maxHeight: 0.87.sh,
                      currentSong: currentSong,
                      songIndex: 0,
                      songsList: [],
                    ),
                  );
                },
                icon: SvgPicture.asset(Assets.svgIcDots, height: 26.h, width: 26.w, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.only(top: 27.h),
            child: Column(
              children: [
                currentSong?.artwork_path != null && currentSong?.artwork_path != ''
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: 17.w),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9.r),
                          child: Image.file(File(currentSong!.artwork_path!), width: 250.w, height: 250.w, fit: BoxFit.cover),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.symmetric(horizontal: 17.w),
                        child: GradientCard(
                          width: 250.w,
                          height: 250.w,
                          borderRadius: 10.r,
                          iconAsset: Assets.svgMusicIcon,
                          iconSize: 100.r,
                          isSvg: false,
                          margin: 0.w,
                          colors: [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.mildOrange],
                        ),
                      ),
                SizedBox(height: 33.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 17.w),
                  child: songTitlePlaylistWidget(currentSong),
                ),
                Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 17.w),
                  child: songPropertiesWidget(state),
                ),
                SizedBox(height: 26.h),
                songProgressBarWidget(),
                SizedBox(height: 70.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget songTitlePlaylistWidget(SongsModel? currentSong) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Texts(
                currentSong?.title ?? '',
                fontSize: 20.sp,
                color: AppColors.black,
                fontWeight: FontWeight.w500,
                fontFamily: AppFonts.inter,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Texts(
                currentSong?.artist.isNotEmpty == true ? currentSong!.artist : 'Unknown Artist',
                fontSize: 14.sp,
                color: AppColors.textColor,
                fontWeight: FontWeight.w400,
                fontFamily: AppFonts.inter,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        SizedBox(width: 15.w),
        GestureDetector(
          onTap: () {
            if (currentSong?.id != null) {
              showCommonAddToPlaylistBottomSheet(context, songId: currentSong!.id);
            }
          },
          child: SvgPicture.asset(Assets.svgIcPlaylist, width: 32.w, height: 32.h),
        ),
      ],
    );
  }

  Widget songPropertiesWidget(MusicPlayerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () {
            context.go('/dashboard/queue');
            // _openQueueScreen();
            // QueueNavigationHelper.navigateToQueueScreen(context);
          },
          child: SvgPicture.asset(Assets.svgIcQueue, width: 23.w, height: 23.h),
        ),
        GestureDetector(
          onTap: () {
            showSnackBar(
              context,
              () {},
              message: 'Sleep timer feature coming soon',
              backgroundColor: AppColors.primaryOrange,
              alertBannerLocation: AlertBannerLocation.bottom,
            );
          },
          child: SvgPicture.asset(Assets.svgIcTimer, width: 23.w, height: 23.h),
        ),
        GestureDetector(
          onTap: () {
            context.push('/dashboard/equalizer');
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SvgPicture.asset(
                Assets.svgIEquilizerc,
                width: 23.w,
                height: 23.h,
                colorFilter: ColorFilter.mode(
                  equalizerService.isEnabled
                      ? AppColors
                            .primaryOrange // Active color when ON
                      : Colors.grey, // Grey when OFF
                  BlendMode.srcIn,
                ),
              ),
              // ON/OFF indicator badge
              if (equalizerService.isEnabled)
                Positioned(
                  right: -2.w,
                  top: -2.h,
                  child: Container(
                    width: 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
        /*GestureDetector(
          onTap: () {
            context.push('/dashboard/equalizer');
            // showSnackBar(
            //   context,
            //   () {},
            //   message: 'Equalizer feature coming soon',
            //   backgroundColor: AppColors.primaryOrange,
            //   alertBannerLocation: AlertBannerLocation.bottom,
            // );
          },
          child: SvgPicture.asset(Assets.svgIEquilizerc, width: 23.w, height: 23.h),
        ),*/
        GestureDetector(
          onTap: () => _toggleFavorite(state),
          child: Container(
            width: 23.w,
            height: 23.h,
            padding: EdgeInsets.all(0.r),
            child: SvgPicture.asset(
              isFavorite ? Assets.svgFavOn : Assets.svgFav,
              width: 21.w,
              height: 21.h,
              colorFilter: ColorFilter.mode(isFavorite ? AppColors.primaryOrange : AppColors.black, BlendMode.srcIn),
            ),
          ),
        ),
      ],
    );
  }

  Widget songProgressBarWidget() {
    return ChangeNotifierProvider<AudioPlayerProvider>(
      create: (context) => AudioPlayerProvider(bloc: context.read<MusicPlayerBloc>()),
      child: const AudioPlayerWidget(),
    );
  }
}
