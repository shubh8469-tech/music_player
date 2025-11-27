import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/genres/bloc/genre_bloc.dart';
import 'package:music_app/features/genres/domain/entities/genre.dart';
import 'package:music_app/features/genres/domain/repositories/genre_repository.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';

import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/app_bar_with_icon_title.dart';
import '../../../../commonWidgets/common_functions.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../themes/color.dart';
import '../../../../utills/snack_bar.dart';
import '../../music_service.dart';
import 'package:go_router/go_router.dart';
import '../../../play_song/widget/playlist_bottomsheet.dart';

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
      final genreSongs =
          (await repo.getSongsForGenre(genre.id!)).cast<SongsModel>();
      for (final song in genreSongs) {
        final alreadyAdded =
            songs.any((existingSong) => existingSong.id == song.id);
        if (!alreadyAdded) {
          songs.add(song);
        }
      }
    }

    return songs;
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
      final musicService = MusicPlayerService();
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

      await musicService.setPlaylist(allSongsFromGenres, startIndex: 0);
      await musicService.play();

      showSnackBar(
        context,
        () {},
        message:
            "Playing ${allSongsFromGenres.length} songs from ${selectedGenres.length} genres",
        alertBannerLocation: AlertBannerLocation.bottom,
      );

      if (mounted) {
        context.pop();
      }
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
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
          ),
          isScrollControlled: true,
          builder: (_) => PlaylistBottomSheet(songsList: allSongsFromGenres),
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
        final genreArtworkPath =
            hasArtwork ? genre.artworkPath! : Assets.svgMusicIcon;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: MusicListTile(
            margin: 7.w,
            height: 66.h,
            borderRadius: 10.r,
            backgroundColor: AppColors.musicTileBackgroundColor,
            cardHeight: 50.h,
            cardWidth: 50.w,
            cardRadius: 100.r,
            cardIconAsset: genreArtworkPath,
            cardIconSize: 32.r,
            isSvgCardIcon: !hasArtwork,
            isSvgColorNeeded: false,
            cardContent: hasArtwork
                ? null
                : buildGenreInitialAvatar(
              genre.name,
              20.sp,
            ),
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
      final musicService = MusicPlayerService();
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
      if (musicService.songs.isEmpty) {
        await musicService.setPlaylist(allSongsFromGenres, startIndex: 0);
        await musicService.play();
      } else {
        final currentIndex = musicService.currentIndex;
        final insertIndex = currentIndex >= 0 ? currentIndex + 1 : 0;

        final newSongsList = List<SongsModel>.from(musicService.songs);

        final songsToAdd = allSongsFromGenres.where((song) {
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

      if (mounted) {
        showSnackBar(
          context,
          () {},
          message:
              "${allSongsFromGenres.length} songs from ${selectedGenres.length} genres added to play next",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        context.pop();
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
      final musicService = MusicPlayerService();
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

      // Create a copy of the existing songs list
      final newSongsList = List<SongsModel>.from(musicService.songs);

      // Add each selected song to the queue if it's not already there
      int addedCount = 0;
      for (final song in allSongsFromGenres) {
        final existingIndex = newSongsList.indexWhere(
          (existingSong) => existingSong.id == song.id,
        );

        if (existingIndex == -1) {
          newSongsList.add(song);
          addedCount++;
        }
      }

      final startIndex = musicService.currentIndex >= 0
          ? musicService.currentIndex
          : 0;
      final shouldAutoPlay = musicService.isPlaying;

      await musicService.setPlaylist(
        newSongsList,
        startIndex: startIndex,
        autoPlay: shouldAutoPlay,
      );

      if (mounted) {

        if (addedCount < 1) {
          showSnackBar(
            context,
            () {},
            message: "Songs already added to queue",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
        else {
          showSnackBar(
            context,
            () {},
            message:
                "$addedCount songs from ${selectedGenres.length} genres added to queue",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }

      }
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
        title: 'Select Genres',
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
                          hintText: 'Search Genres',
                          hintStyle: TextStyle(
                            color: AppColors.textColor,
                            fontWeight: FontWeight.w400,
                            fontFamily: AppFonts.inter,
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
                              selectedCount != 0
                                  ? "$selectedCount ${S.of(context).selected}"
                                  : "",
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
}

