import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/genres/presentation/bloc/genre_bloc.dart';
import 'package:music_app/features/genres/domain/entities/genre.dart';
import 'package:music_app/features/genres/domain/repositories/genre_repository.dart';
import 'package:music_app/features/songs/presentation/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:music_app/core/widgets/MusicListTile.dart';
import 'package:music_app/core/widgets/app_bar_with_icon_title.dart';
import 'package:music_app/core/widgets/common_functions.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/core/utils/globals.dart';
import 'package:music_app/core/utils/snack_bar.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_event.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/widgets/common_modal_bottom_sheet.dart';

class SelectGenreScreen extends StatefulWidget {
  const SelectGenreScreen({super.key});

  @override
  State<SelectGenreScreen> createState() => _SelectGenreScreenState();
}

class _SelectGenreScreenState extends State<SelectGenreScreen> {
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool isSelectedAll = false;
  Set<int> selectedGenreIds = {};
  String searchQuery = '';
  List<Genre> _cachedGenres = [];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.trim();
      });
    });

    context.read<GenreBloc>().add(const GenreEvent.fetchAllGenres());
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  List<Genre> _filterGenres(List<Genre> allGenres) {
    if (searchQuery.isEmpty) return allGenres;

    return allGenres.where((genre) {
      return genre.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  int get selectedCount => selectedGenreIds.length;

  void updateSelectAllState(List<Genre> filteredGenres) {
    if (filteredGenres.isEmpty) {
      isSelectedAll = false;
      return;
    }

    final allIds = filteredGenres.map((g) => g.id!).toSet();
    isSelectedAll = allIds.every((id) => selectedGenreIds.contains(id));
  }

  void toggleSelectAll(List<Genre> filteredGenres) {
    setState(() {
      if (isSelectedAll) {
        final filteredIds = filteredGenres.map((g) => g.id!).toSet();
        selectedGenreIds.removeAll(filteredIds);
      } else {
        selectedGenreIds.addAll(filteredGenres.map((g) => g.id!));
      }
      updateSelectAllState(filteredGenres);
    });
  }

  void toggleSelection(int genreId, List<Genre> filteredGenres) {
    setState(() {
      if (selectedGenreIds.contains(genreId)) {
        selectedGenreIds.remove(genreId);
      } else {
        selectedGenreIds.add(genreId);
      }
      updateSelectAllState(filteredGenres);
    });
  }

  List<Genre> _getSelectedGenres(List<Genre> allGenres) {
    return allGenres
        .where((genre) => selectedGenreIds.contains(genre.id))
        .toList();
  }

  Future<List<SongsModel>> _fetchSongsForGenres(List<Genre> genres) async {
    final repo = locator<GenreRepository>();
    final List<SongsModel> songs = [];

    for (final genre in genres) {
      final genreSongs = (await repo.getSongsForGenre(
        genre.id!,
      )).cast<SongsModel>();
      for (final song in genreSongs) {
        final alreadyAdded = songs.any(
          (existingSong) => existingSong.id == song.id,
        );
        if (!alreadyAdded) {
          songs.add(song);
        }
      }
    }

    return songs;
  }

  // Permanently delete songs belonging to selected genres (like _performDeleteFromEntity)
  Future<void> _deleteSongsFromSelectedGenres(List<Genre> allGenres) async {
    final selectedGenres = _getSelectedGenres(allGenres);

    if (selectedGenres.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No genres selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final allSongsFromGenres = await _fetchSongsForGenres(selectedGenres);

      if (allSongsFromGenres.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected genres contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final songCount = allSongsFromGenres.length;
      showCommonConfirmationBottomSheet(
        context: context,
        title: 'Delete Songs',
        message:
            'Are you sure you want to permanently delete these $songCount songs from the selected genres? This will remove them from your library.',
        onConfirm: (sheetContext) async {
          Navigator.pop(sheetContext);
          await _performDeleteSongsFromEntities(allSongsFromGenres, songCount);
        },
      );
    } catch (e) {
      log('Error deleting songs from genres: $e');
      showSnackBar(
        context,
        () {},
        message: "Error deleting songs from genres",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  Future<void> _performDeleteSongsFromEntities(
    List<SongsModel> songsToDelete,
    int songCount,
  ) async {
    final bloc = context.read<MusicPlayerBloc>();

    for (final song in songsToDelete) {
      final hasPermission = await _checkAndRequestPermission();
      if (!hasPermission) {
        showSnackBar(
          context,
          () {},
          message: 'Storage permission denied',
          backgroundColor: Colors.red,
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final file = File(song.filePath);
      if (await file.exists()) {
        await file.delete();
        log('File deleted: ${song.filePath}');
      }

      if (song.id != null) {
        context.read<SongsBloc>().add(SongsEvent.removeSong(song.id!));
        final currentSongs = List<SongsModel>.from(bloc.state.songs);
        currentSongs.removeWhere((element) => element.id == song.id);
        if (currentSongs.isNotEmpty) {
          bloc.add(RemoveDeletedSongFromQueueEvent(song.id!));
        } else {
          bloc.add(ResetPlaylistEvent(currentSongs.map((m) => m.toDomain()).toList()));
        }
      }
    }

    setState(() {
      selectedGenreIds.clear();
      isSelectedAll = false;
    });

    Navigator.pop(context);
    showSnackBar(
      context,
      () {},
      message: "$songCount songs deleted successfully!",
      alertBannerLocation: AlertBannerLocation.bottom,
    );
  }

  void _playSelectedGenres(List<Genre> allGenres) async {
    final selectedGenres = _getSelectedGenres(allGenres);

    if (selectedGenres.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No genres selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final bloc = context.read<MusicPlayerBloc>();
      final allSongsFromGenres = await _fetchSongsForGenres(selectedGenres);

      if (allSongsFromGenres.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected genres contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      showSnackBar(
        context,
        () {},
        message:
            "Playing ${allSongsFromGenres.length} songs from ${selectedGenres.length} genres",
        alertBannerLocation: AlertBannerLocation.bottom,
      );

      // if (mounted) {
      //   context.pop();
      // }

      bloc.add(SetPlaylistEvent(allSongsFromGenres.map((m) => m.toDomain()).toList(), startIndex: 0));
      bloc.add(const PlayEvent());
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error playing genres: $e",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  void _addSongsToSelectedGenres(List<Genre> allGenres) async {
    final selectedGenres = _getSelectedGenres(allGenres);

    if (selectedGenres.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No genres selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final allSongsFromGenres = await _fetchSongsForGenres(selectedGenres);

      if (allSongsFromGenres.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected genres contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      if (mounted) {
        showCommonAddToPlaylistBottomSheet(
          context,
          songsList: allSongsFromGenres,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error fetching songs from genres: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  List<Widget> _buildGenreSection(String title, List<Genre> genres) {
    if (genres.isEmpty) return [];

    return [
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        child: Row(
          children: [
            Texts(
              title,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.inter,
              color: AppColors.textColor,
            ),
          ],
        ),
      ),
      ...genres.map((genre) {
        final isSelected = selectedGenreIds.contains(genre.id);
        final hasArtwork = genre.artworkPath?.isNotEmpty ?? false;
        final genreArtworkPath = hasArtwork
            ? genre.artworkPath!
            : Assets.svgMusicIcon;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: MusicListTile(
            margin: 7.w,
            height: 66.h,
            borderRadius: 10.r,
            backgroundColor: AppColors.musicTileBackgroundColor,
            cardHeight: 50.h,
            cardWidth: 50.h,
            cardRadius: 100.r,
            cardIconAsset: genreArtworkPath,
            cardIconSize: 32.r,
            isSvgCardIcon: !hasArtwork,
            isSvgColorNeeded: false,
            cardContent: hasArtwork
                ? null
                : buildGenreInitialAvatar(genre.name, 20.sp),
            title: genre.name,
            subtitle: '${genre.songCount} Songs',
            trailingIconAsset: isSelected
                ? Assets.svgIcCheck
                : Assets.svgIcUncheck,
            trailingIconHeight: 20.h,
            trailingIconWidth: 10.w,
            trailingMargin: 2.w,
            onTap: () => toggleSelection(genre.id!, genres),
            onPlayTap: () => toggleSelection(genre.id!, genres),
          ),
        );
      }).toList(),
    ];
  }

  void _showPopupMenu(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    // Position the menu in the top right corner below the app bar
    final RelativeRect position = RelativeRect.fromLTRB(
      overlay.size.width - 200.w, // Left (200px from right edge)
      100.h, // Top (below app bar)
      0, // Right
      overlay.size.height - 100.h, // Bottom
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      color: AppColors.white,
      elevation: 8,
      items: [
        PopupMenuItem<String>(
          value: 'play_next',
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            child: Texts(
              'Play Next',
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              fontFamily: AppFonts.inter,
              color: AppColors.textColor,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'add_to_queue',
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            child: Texts(
              'Add To Queue',
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              fontFamily: AppFonts.inter,
              color: AppColors.textColor,
            ),
          ),
        ),
      ],
    ).then((String? value) {
      if (value != null) {
        _handlePopupMenuAction(value);
      }
    });
  }

  // Handle popup menu actions
  void _handlePopupMenuAction(String action) {
    switch (action) {
      case 'play_next':
        _playNextSelectedSongs();
        break;
      case 'add_to_queue':
        _addSelectedSongsToQueue();
        break;
    }
  }

  // Play next selected artists
  void _playNextSelectedSongs() async {
    final selectedGenres = _getSelectedGenres(_cachedGenres);

    if (selectedGenres.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No genres selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final bloc = context.read<MusicPlayerBloc>();
      final allSongsFromGenres = await _fetchSongsForGenres(selectedGenres);

      if (allSongsFromGenres.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected genres contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      // Check if there are existing songs in the queue
      if (bloc.state.songs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "${allSongsFromGenres.length} songs added to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );

        bloc.add(SetPlaylistEvent(allSongsFromGenres.map((m) => m.toDomain()).toList(), startIndex: 0));
        bloc.add(const PlayEvent());
      } else {
        bloc.add(PlayNextMultipleSongsEvent(allSongsFromGenres.map((m) => m.toDomain()).toList()));
        if (mounted) {
          showSnackBar(
            context,
            () {},
            message: "${allSongsFromGenres.length} songs from ${selectedGenres.length} genres added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding genres to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Add selected artists to queue
  void _addSelectedSongsToQueue() async {
    final selectedGenres = _getSelectedGenres(_cachedGenres);

    if (selectedGenres.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "No genres selected",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    try {
      final bloc = context.read<MusicPlayerBloc>();
      final allSongsFromGenres = await _fetchSongsForGenres(selectedGenres);

      if (allSongsFromGenres.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Selected genres contain no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      bloc.add(AddMultipleSongsToQueueEvent(allSongsFromGenres.map((m) => m.toDomain()).toList()));

      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "${allSongsFromGenres.length} songs from ${selectedGenres.length} genres added to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }

      // context.pop();

      // Create a copy of the existing songs list
      // final newSongsList = List<SongsModel>.from(musicService.songs);
      //
      // // Add each selected song to the queue if it's not already there
      // int addedCount = 0;
      // for (final song in allSongsFromGenres) {
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
      // final startIndex = musicService.currentIndex >= 0
      //     ? musicService.currentIndex
      //     : 0;
      // final shouldAutoPlay = musicService.isPlaying;
      //
      // await musicService.setPlaylist(
      //   newSongsList,
      //   startIndex: startIndex,
      //   autoPlay: shouldAutoPlay,
      // );
      //
      // if (mounted) {
      //
      //   if (addedCount < 1) {
      //     showSnackBar(
      //       context,
      //       () {},
      //       message: "Songs already added to queue",
      //       alertBannerLocation: AlertBannerLocation.bottom,
      //     );
      //   }
      //   else {
      //     showSnackBar(
      //       context,
      //       () {},
      //       message:
      //           "$addedCount songs from ${selectedGenres.length} genres added to queue",
      //       alertBannerLocation: AlertBannerLocation.bottom,
      //     );
      //   }
      //
      // }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error adding genres to queue",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: 'Select Genre',
        isActionBtnDisplay: true,
        onTapAction: () => _showPopupMenu(context),
      ),
      body: BlocBuilder<GenreBloc, GenreState>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text("Initializing...")),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
            loaded: (allGenres, _) {
              _cachedGenres = allGenres;
              final filteredGenres = _filterGenres(allGenres);

              updateSelectAllState(filteredGenres);

              if (allGenres.isEmpty) {
                return const Center(
                  child: Text(
                    "No genres available",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 20.h,
                    ),
                    child: Container(
                      height: 48.h,
                      width: 343.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        color: AppColors.black.withValues(alpha: .14),
                      ),
                      child: TextFormField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 14.w, right: 10.w),
                            child: SvgPicture.asset(Assets.svgIcSerach),
                          ),
                          hintText: 'Search Genre',
                          hintStyle: TextStyle(
                            color: AppColors.textColor.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFonts.inter,
                            fontSize: 15.sp
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (filteredGenres.isEmpty && searchQuery.isNotEmpty)
                    Expanded(
                      child: Center(
                        child: Texts(
                          "No genres match your search",
                          fontSize: 16.sp,
                          color: AppColors.textColor,
                        ),
                      ),
                    )
                  else ...[
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 5.h,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Texts(
                              "${selectedItemsCount(filteredGenres, selectedGenreIds) != 0 ? "${selectedItemsCount(filteredGenres, selectedGenreIds)} ${S.of(context).selected}" : ''} ",
                              // selectedCount != 0
                              //     ? "$selectedCount ${S.of(context).selected}"
                              //     : "",
                              fontSize: 14.sp,
                              fontFamily: AppFonts.inter,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textColor,
                            ),
                          ),
                          Texts(
                            S.of(context).selectAll,
                            fontSize: 14.sp,
                            fontFamily: AppFonts.inter,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textColor,
                          ),
                          SizedBox(width: 10.w),
                          GestureDetector(
                            onTap: () => toggleSelectAll(filteredGenres),
                            child: SvgPicture.asset(
                              isSelectedAll
                                  ? Assets.svgIcRadioCheckl
                                  : Assets.svgIcRadioUncheck,
                              height: 20.h,
                              width: 20.w,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ..._buildGenreSection(
                              'My Genres (${filteredGenres.length})',
                              filteredGenres,
                            ),
                            SizedBox(height: 90.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<GenreBloc, GenreState>(
        builder: (context, state) {
          return state.maybeWhen(
            loaded: (allGenres, _) {
              return Visibility(
                visible: selectedCount > 0,
                child: SafeArea(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    margin: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () => _playSelectedGenres(allGenres),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(Assets.svgIcNavPlay),
                              SizedBox(height: 3.h),
                              Texts(
                                S.of(context).play,
                                fontSize: 12.sp,
                                fontFamily: AppFonts.inter,
                                fontWeight: FontWeight.w400,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _addSongsToSelectedGenres(allGenres),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(Assets.svgIcNavPlaylist),
                              SizedBox(height: 3.h),
                              Texts(
                                S.of(context).addToPlaylist,
                                fontSize: 12.sp,
                                fontFamily: AppFonts.inter,
                                fontWeight: FontWeight.w400,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _deleteSongsFromSelectedGenres(allGenres),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(Assets.svgIcNavDelete),
                              SizedBox(height: 3.h),
                              Texts(
                                S.of(context).delete,
                                fontSize: 12.sp,
                                fontFamily: AppFonts.inter,
                                fontWeight: FontWeight.w400,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  Future<bool> _checkAndRequestPermission() async {
    if (Platform.isAndroid) {
      // Check if we have manage external storage permission (Android 11+)
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }

      // Request manage external storage permission
      PermissionStatus status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }

      // Fallback to storage permission (for older Android versions)
      if (await Permission.storage.isGranted) {
        return true;
      }

      status = await Permission.storage.request();
      return status.isGranted;
    }

    // For iOS and other platforms
    return true;
  }
}
