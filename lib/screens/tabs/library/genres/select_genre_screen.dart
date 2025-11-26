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
      final _repo = locator<GenreRepository>();
      List<SongsModel> allSongsFromGenres = [];

      for (var genre in selectedGenres) {
        List<SongsModel> genreSongs = (await _repo.getSongsForGenre(
          genre.id!,
        )).cast<SongsModel>();

        for (var song in genreSongs) {
          if (!allSongsFromGenres.any((s) => s.id == song.id)) {
            allSongsFromGenres.add(song);
          }
        }
      }

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
      final _repo = locator<GenreRepository>();
      List<SongsModel> allSongsFromGenres = [];

      for (var genre in selectedGenres) {
        List<SongsModel> genreSongs = (await _repo.getSongsForGenre(
          genre.id!,
        )).cast<SongsModel>();

        for (var song in genreSongs) {
          if (!allSongsFromGenres.any((s) => s.id == song.id)) {
            allSongsFromGenres.add(song);
          }
        }
      }

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
            cardIconAsset: Assets.svgMusicIcon,
            cardIconSize: 32.r,
            isSvgCardIcon: true,
            isSvgColorNeeded: false,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: 'Select Genres',
        isActionBtnDisplay: false,
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

