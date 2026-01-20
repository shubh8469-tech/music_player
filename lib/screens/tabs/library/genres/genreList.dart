import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:characters/characters.dart';
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
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/common_functions.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/genres/bloc/genre_bloc.dart';
import '../../../../features/genres/domain/entities/genre.dart';
import '../../../../features/genres/domain/repositories/genre_repository.dart';
import '../../../../features/playlists/bloc/playlist_bloc.dart';
import '../../../../features/songs/data/models/song_model.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../themes/font.dart';
import '../../../../utills/globals.dart';
import '../../../../utills/snack_bar.dart';
import '../../../../commonWidgets/edit_tag_bottom_sheet.dart';
import '../../music_service.dart';
import '../../../common/image_crop_screen.dart';
import '../../../play_song/widget/playlist_bottomsheet.dart';
import 'sort_by_bottomsheet.dart';

class GenreListScreen extends StatefulWidget {
  const GenreListScreen({super.key});

  @override
  State<GenreListScreen> createState() => _GenreListScreenState();
}

class _GenreListScreenState extends State<GenreListScreen> {
  int selectedIndex = 0; // Default to Genre Name
  int selectedOrder = 0; // 0 = ascending, 1 = descending
  String selectedGenreSort = genreSortByItems[0].title;
  var musicService = MusicPlayerService();

  @override
  void initState() {
    super.initState();
    context.read<GenreBloc>().add(const GenreEvent.fetchAllGenres());
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
                      context.push('/dashboard/select-genre');
                    },
                    child: Row(
                      children: [
                        SvgPicture.asset(Assets.svgSongsCount),
                        SizedBox(width: 10.w),
                        BlocBuilder<GenreBloc, GenreState>(
                          builder: (context, state) {
                            return state.maybeWhen(
                              loaded: (genres, _) => Texts(
                                '${genres.length} Genres',
                                fontSize: 14.sp,
                                fontWeight: AppFontWeights.regular,
                                color: AppColors.textColor,
                              ),
                              orElse: () => Texts(
                                '0 Genres',
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
                          value: context.read<GenreBloc>(),
                          child: GenreSortByBottomSheet(
                            selectedIndex: selectedIndex,
                            selectedOrder: selectedOrder,
                            onItemSelected: (index, order) {
                              setState(() {
                                selectedIndex = index;
                                selectedOrder = order;
                                selectedGenreSort = genreSortByItems[index].title;
                              });
                              // Trigger Bloc sort event
                              context.read<GenreBloc>().add(
                                GenreEvent.sortGenres(index, order),
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
              BlocBuilder<GenreBloc, GenreState>(
                builder: (context, state) {
                  return state.when(
                    initial: () => const SizedBox(),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    loaded: (genres, _) {
                      if (genres.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50.h),
                            child: Texts(
                              'No genres found',
                              fontSize: 16.sp,
                              color: AppColors.mediumDarkGrey,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: genres.map((genre) {
                          final hasArtwork =
                              genre.artworkPath?.isNotEmpty ?? false;
                          final genreArtworkPath =
                              hasArtwork ? genre.artworkPath! : '';
                          return MusicListTile(
                            margin: 7.w,
                            height: 66.h,
                            borderRadius: 10.r,
                            backgroundColor: AppColors.musicTileBackgroundColor,
                            cardHeight: 50.h,
                            cardWidth: 50.w,
                            cardRadius: 100.r,
                            cardIconAsset: genreArtworkPath,
                            cardContent: hasArtwork
                                ? null
                                : buildGenreInitialAvatar(
                                    genre.name,
                                    20.sp,
                                  ),
                            noLogoGradientColor: [
                              AppColors.primaryOrange.withValues(alpha: 0.21),
                              AppColors.primaryOrange,
                            ],
                            cardIconSize: 19.r,
                            title: genre.name,
                            subtitle: '${genre.songCount} Songs',
                            trailingIconAsset: Assets.svgMenuIcon,
                            trailingIconHeight: 19.5.h,
                            trailingIconWidth: 3.w,
                            trailingMargin: 10.w,
                            onTap: () {
                              context.push(
                                '/dashboard/genre-detail',
                                extra: genre,
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
                                builder: (_) => _buildGenreMenu(context, genre),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenreMenu(BuildContext context, Genre genre) {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    final hasArtwork = genre.artworkPath?.isNotEmpty ?? false;
    final genreArtworkPath = hasArtwork ? genre.artworkPath! : '';

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
                // Genre info
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
                    cardIconAsset: genreArtworkPath,
                    cardContent: hasArtwork
                        ? null
                        : buildGenreInitialAvatar(
                            genre.name,
                            24.sp,
                          ),
                    cardIconSize: 32.r,
                    isSvgColorNeeded: false,
                    title: genre.name,
                    subtitle: '${genre.songCount} Songs',
                    trailingIconAsset: Assets.svgIcShare,
                    trailingIconHeight: 25.h,
                    trailingIconWidth: 25.w,
                    trailingMargin: 2.w,
                    onTap: () {
                      showSnackBar(
                        context,
                        () {},
                        message: 'Share genre feature coming soon',
                        alertBannerLocation: AlertBannerLocation.bottom,
                      );
                    },
                    onPlayTap: () {
                      showSnackBar(
                        context,
                        () {},
                        message: 'Play genre feature coming soon',
                        alertBannerLocation: AlertBannerLocation.bottom,
                      );
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: genreMenuItems.length,
                    itemBuilder: (context, index) {
                      final menuItem = genreMenuItems[index];
                      final isChangeCoverItem =
                          menuItem.title == S.of(context).hideFolder;
                      final displayTitle = isChangeCoverItem
                          ? S.of(context).changeCover
                          : menuItem.title;
                      final displayIcon = isChangeCoverItem
                          ? Assets.svgIcCover
                          : menuItem.icon;
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(
                              horizontal: 0.w,
                              vertical: 0.h,
                            ),
                            leading: SvgPicture.asset(
                              displayIcon,
                              height: 24,
                              width: 24,
                            ),
                            title: Texts(
                              displayTitle,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppFonts.inter,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _handleGenreMenuAction(displayTitle, genre);
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

  void _handleGenreMenuAction(String menuTitle, Genre genre) {
    if (menuTitle == S.of(context).play) {
      _playGenre(genre);
    } else if (menuTitle == S.of(context).playNext) {
      _playNextGenre(genre);
    } else if (menuTitle == S.of(context).addToQueue) {
      _addGenreToQueue(genre);
    } else if (menuTitle == S.of(context).addToPlaylist) {
      _addGenreToPlaylist(genre);
    } else if (menuTitle == S.of(context).changeCover) {
      _handleGenreChangeCover(genre);
    } else if (menuTitle == S.of(context).editTags) {
      _handleEditGenreTags(genre);
    }
  }

  void _handleEditGenreTags(Genre genre) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BlocProvider.value(
        value: context.read<GenreBloc>(),
        child: EditTagBottomSheet(
          initialValue: genre.name,
          title: S.of(context).editTags,
          onSave: (newName) {
            if (genre.id != null && newName.trim().isNotEmpty) {
              context.read<GenreBloc>().add(
                    GenreEvent.updateGenreName(genre.id!, newName),
                  );
              showSnackBar(
                context,
                () {},
                message: 'Genre name updated successfully',
                alertBannerLocation: AlertBannerLocation.bottom,
              );
            }
          },
        ),
      ),
    );
  }

  // Play genre
  void _playGenre(Genre genre) async {
    try {
      final _repo = locator<GenreRepository>();
      List<SongsModel> genreSongs = (await _repo.getSongsForGenre(
        genre.id!,
      )).cast<SongsModel>();

      if (genreSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Genre has no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      await musicService.setPlaylist(genreSongs, startIndex: 0);
      await musicService.play();

      showSnackBar(
        context,
        () {},
        message: "Playing ${genreSongs.length} songs from ${genre.name}",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error playing genre: $e",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Play next genre
  void _playNextGenre(Genre genre) async {
    try {
      final _repo = locator<GenreRepository>();
      List<SongsModel> genreSongs = (await _repo.getSongsForGenre(
        genre.id!,
      )).cast<SongsModel>();

      if (genreSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Genre has no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      if (musicService.songs.isEmpty) {
        await musicService.setPlaylist(genreSongs, startIndex: 0);
        await musicService.play();
      } else {
        final updateCount = await musicService.playNextMultipleSongs(genreSongs);
        // final currentIndex = musicService.currentIndex;
        // final insertIndex = currentIndex + 1;
        // final newSongsList = List<SongsModel>.from(musicService.songs);
        //
        // final songsToAdd = genreSongs.where((song) {
        //   return !newSongsList.any(
        //     (existingSong) => existingSong.id == song.id,
        //   );
        // }).toList();
        //
        // newSongsList.insertAll(insertIndex, songsToAdd);
        //
        // await musicService.setPlaylist(
        //   newSongsList,
        //   startIndex: currentIndex >= 0 ? currentIndex : 0,
        //   autoPlay: false,
        // );

        if(updateCount < 1){
          showSnackBar(
            context,
                () {},
            message: "Songs already added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
        else{
          showSnackBar(
            context,
                () {},
            message: "$updateCount songs added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
      }
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error adding genre to play next",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add genre to queue
  void _addGenreToQueue(Genre genre) async {
    try {
      final _repo = locator<GenreRepository>();
      List<SongsModel> genreSongs = (await _repo.getSongsForGenre(
        genre.id!,
      )).cast<SongsModel>();

      if (genreSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Genre has no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final newSongsList = List<SongsModel>.from(musicService.songs);
      int addedCount = 0;

      for (final song in genreSongs) {
        final existingIndex = newSongsList.indexWhere(
          (existingSong) => existingSong.id == song.id,
        );

        if (existingIndex == -1) {
          newSongsList.add(song);
          addedCount++;
        }
      }

      await musicService.setPlaylist(newSongsList, autoPlay: false);

      if (addedCount < 1) {
        showSnackBar(
          context,
          () {},
          message: "Songs already added to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      } else {
        showSnackBar(
          context,
          () {},
          message: "$addedCount songs from ${genre.name} added to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error adding genre to queue",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add genre to playlist
  void _addGenreToPlaylist(Genre genre) async {
    try {
      // Capture PlaylistBloc before async operations
      final playlistBloc = context.read<PlaylistBloc>();

      final _repo = locator<GenreRepository>();
      List<SongsModel> genreSongs = (await _repo.getSongsForGenre(
        genre.id!,
      )).cast<SongsModel>();

      if (genreSongs.isEmpty) {
        if (mounted) {
          showSnackBar(
            context,
            () {},
            message: "Genre has no songs",
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
            child: PlaylistBottomSheet(songsList: genreSongs),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error fetching songs from genre: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  Future<void> _handleGenreChangeCover(Genre genre) async {
    if (genre.id == null) return;
    final action = await _showGenreChangeCoverSheet();
    if (!mounted || action == null) return;

    if (action == _ChangeCoverAction.localGallery) {
      await _handleGenreLocalGalleryCover(genre);
    } else if (action == _ChangeCoverAction.searchOnline) {
      showSnackBar(
        context,
        () {},
        message: 'Search online feature coming soon',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  Future<_ChangeCoverAction?> _showGenreChangeCoverSheet() {
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
            padding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 24.h,
            ),
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
                    Navigator.pop(sheetContext, _ChangeCoverAction.localGallery);
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

  Future<void> _handleGenreLocalGalleryCover(Genre genre) async {
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

      final optimizedBytes = await _optimizeGenreCoverImage(croppedBytes);
      final savedFile =
          await _persistGenreCoverFile(genre.id!, optimizedBytes);

      await _cleanupGenreCover(genre.artworkPath);
      context.read<GenreBloc>().add(
            GenreEvent.updateGenreCover(
              genre.id!,
              savedFile.path,
            ),
          );

      if (!mounted) return;

      showSnackBar(
        context,
        () {},
        message: 'Genre cover updated successfully',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      log('Failed to update genre cover: $e');
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

  Future<Uint8List> _optimizeGenreCoverImage(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unsupported image format');
    }

    const maxDimension = 720;
    img.Image processed = decoded;
    final largestSide =
        decoded.width > decoded.height ? decoded.width : decoded.height;

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

    final optimizedBytes = img.encodeJpg(
      processed,
      quality: 85,
    );

    return Uint8List.fromList(optimizedBytes);
  }

  Future<File> _persistGenreCoverFile(int genreId, Uint8List bytes) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(
      p.join(documentsDir.path, 'covers', 'genres'),
    );

    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'genre_${genreId}_$timestamp.jpg';
    final filePath = p.join(coversDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _cleanupGenreCover(String? existingPath) async {
    if (existingPath == null || existingPath.isEmpty) {
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final coversDirPath = p.join(documentsDir.path, 'covers', 'genres');

      if (p.isWithin(coversDirPath, existingPath)) {
        final existingFile = File(existingPath);
        if (await existingFile.exists()) {
          await existingFile.delete();
        }
      }
    } catch (e) {
      log('Failed to remove previous genre cover: $e');
    }
  }
}

enum _ChangeCoverAction {
  localGallery,
  searchOnline,
}

