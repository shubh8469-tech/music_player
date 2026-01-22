import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/themes/color.dart';
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/folders/bloc/folder_bloc.dart';
import '../../../../features/folders/domain/entities/folder.dart' as domain;
import '../../../../features/folders/domain/repositories/folder_repository.dart';
import '../../../../features/folders/domain/usecases/update_folder_hidden_status.dart';
import '../../../../features/playlists/bloc/playlist_bloc.dart';
import '../../../../features/songs/bloc/songs_bloc.dart';
import '../../../../features/songs/data/models/song_model.dart';
import '../../../../generated/assets.dart';
import '../../../../l10n/l10n.dart';
import '../../../../model/song_menu_model.dart';
import '../../../../themes/font.dart';
import '../../../../utills/globals.dart';
import '../../../../utills/snack_bar.dart';
import '../../music_service.dart';
import '../../../play_song/widget/playlist_bottomsheet.dart';
import 'sort_by_bottomsheet.dart';

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  int selectedIndex = 0; // Default to Folder Name
  int selectedOrder = 0; // 0 = ascending, 1 = descending
  String selectedFolderSort = folderSortByItems[0].title;
  var musicService = MusicPlayerService();

  @override
  void initState() {
    super.initState();
    context.read<FolderBloc>().add(const FolderEvent.fetchAllFolders());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SongsBloc, SongsState>(
      listenWhen: (previous, current) {
        // Listen to all loaded states to catch song deletions
        // We'll check if the song count changed by comparing state
        return current.maybeWhen(loaded: (_) => true, orElse: () => false);
      },
      listener: (context, state) {
        // When a song is deleted, refresh folders to update song counts
        state.maybeWhen(
          loaded: (songs) async {
            // Wait for database triggers to complete, then refresh folders
            await Future.delayed(const Duration(milliseconds: 800));
            if (mounted) {
              // Force refresh folders from database
              final folderBloc = context.read<FolderBloc>();
              folderBloc.add(const FolderEvent.fetchAllFolders());
            }
          },
          orElse: () {},
        );
      },
      child: Scaffold(
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
                        context.push('/dashboard/select-folder');
                      },
                      child: SvgPicture.asset(Assets.svgSongsCount),
                    ),
                    SizedBox(width: 10.w),
                    BlocBuilder<FolderBloc, FolderState>(
                      builder: (context, state) {
                        return state.maybeWhen(
                          loaded: (folders, _) => Texts(
                            '${folders.length} Folders',
                            fontSize: 14.sp,
                            fontWeight: AppFontWeights.regular,
                            color: AppColors.textColor,
                          ),
                          orElse: () => Texts(
                            '0 Folders',
                            fontSize: 14.sp,
                            fontWeight: AppFontWeights.regular,
                            color: AppColors.textColor,
                          ),
                        );
                      },
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
                            value: context.read<FolderBloc>(),
                            child: FolderSortByBottomSheet(
                              selectedIndex: selectedIndex,
                              selectedOrder: selectedOrder,
                              onItemSelected: (index, order) {
                                setState(() {
                                  selectedIndex = index;
                                  selectedOrder = order;
                                  selectedFolderSort =
                                      folderSortByItems[index].title;
                                });
                                // Trigger Bloc sort event
                                context.read<FolderBloc>().add(
                                  FolderEvent.sortFolders(index, order),
                                );
                                // Close bottom sheet safely
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
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
                BlocBuilder<FolderBloc, FolderState>(
                  buildWhen: (previous, current) {
                    // Always rebuild when folders are loaded to ensure counts update
                    final isLoaded = current.maybeWhen(
                      loaded: (_, __) => true,
                      orElse: () => false,
                    );
                    // Rebuild if state is loaded (this will catch all folder updates)
                    return isLoaded;
                  },
                  builder: (context, state) {
                    return state.when(
                      initial: () => const SizedBox(),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      loaded: (folders, _) {
                        if (folders.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50.h),
                              child: Texts(
                                'No folders found',
                                fontSize: 16.sp,
                                color: AppColors.mediumDarkGrey,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: folders.map((folder) {
                            return MusicListTile(
                              margin: 7.w,
                              height: 66.h,
                              borderRadius: 10.r,
                              backgroundColor:
                                  AppColors.musicTileBackgroundColor,
                              cardHeight: 50.h,
                              cardWidth: 50.w,
                              cardRadius: 7.r,
                              cardIconAsset: Assets.svgDirectory,
                              cardIconSize: 32.r,
                              isSvgColorNeeded: false,
                              title: folder.name,
                              subtitle: '${folder.songCount} Songs',
                              trailingIconAsset: Assets.svgMenuIcon,
                              trailingIconHeight: 19.5.h,
                              trailingIconWidth: 3.w,
                              trailingMargin: 10.w,
                              onTap: () {
                                context.push(
                                  '/dashboard/folder-detail',
                                  extra: folder,
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
                                      _buildFolderMenu(context, folder),
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
      ),
    );
  }

  Widget _buildFolderMenu(BuildContext context, domain.Folder folder) {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;
    final menuItems = _buildFolderMenuItems(folder);

    return Container(
      constraints: BoxConstraints(maxHeight: 0.62.sh),
      padding: EdgeInsets.only(top: 10.h, bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 10.h),
          Flexible(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length + 1,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {

                      if(index == 0){
                        // Folder info
                        return Padding(
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
                              AppColors.mildYellow.withValues(alpha: 0.21),
                              AppColors.mildYellow,
                            ],
                            cardIconAsset: Assets.svgDirectory,
                            cardIconSize: 32.r,
                            isSvgCardIcon: true,
                            title: folder.name,
                            subtitle: '${folder.songCount} Songs',
                            trailingIconAsset: Assets.svgIcShare,
                            trailingIconHeight: 25.h,
                            trailingIconWidth: 25.w,
                            trailingMargin: 2.w,
                            onTap: () {
                              showSnackBar(
                                context,
                                    () {},
                                message: 'Share folder feature coming soon',
                                alertBannerLocation: AlertBannerLocation.bottom,
                              );
                            },
                            onPlayTap: () {
                              showSnackBar(
                                context,
                                    () {},
                                message: 'Play folder feature coming soon',
                                alertBannerLocation: AlertBannerLocation.bottom,
                              );
                            },
                          ),
                        );
                      }

                      final menuItem = menuItems[index - 1];
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
                              _handleFolderMenuAction(menuItem.title, folder);
                            },
                          ),
                          if (index - 1 == 3) ...[
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
                SizedBox(height: 44.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<SongMenuItem> _buildFolderMenuItems(domain.Folder folder) {
    final localization = S.of(context);
    final hideTitle =
        folder.isHidden ? localization.unhideFolder : localization.hideFolder;

    return [
      SongMenuItem(
        icon: Assets.svgPlayBlackBorder,
        title: localization.play,
      ),
      SongMenuItem(
        icon: Assets.svgIcMenuPlaynext,
        title: localization.playNext,
      ),
      SongMenuItem(
        icon: Assets.svgIcMenuQueue,
        title: localization.addToQueue,
      ),
      SongMenuItem(
        icon: Assets.svgIcMenuPlaylist,
        title: localization.addToPlaylist,
      ),
      SongMenuItem(
        icon: Assets.svgIcHide,
        title: hideTitle,
      ),
    ];
  }

  void _handleFolderMenuAction(String menuTitle, domain.Folder folder) {
    if (menuTitle == S.of(context).play) {
      _playFolder(folder);
    } else if (menuTitle == S.of(context).playNext) {
      _playNextFolder(folder);
    } else if (menuTitle == S.of(context).addToQueue) {
      _addFolderToQueue(folder);
    } else if (menuTitle == S.of(context).addToPlaylist) {
      _addFolderToPlaylist(folder);
    } else if (menuTitle == S.of(context).hideFolder ||
        menuTitle == S.of(context).unhideFolder) {
      final hide = menuTitle == S.of(context).hideFolder;
      _updateFolderHiddenStatus(folder, hide);
    } else if (menuTitle == S.of(context).deleteFolder) {
      _deleteFolder(folder);
    }
  }

  // Play folder
  void _playFolder(domain.Folder folder) async {
    try {
      final _repo = locator<FolderRepository>();
      List<SongsModel> folderSongs = (await _repo.getSongsForFolder(
        folder.id!,
      )).cast<SongsModel>();

      if (folderSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Folder contains no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      await musicService.setPlaylist(folderSongs, startIndex: 0);
      await musicService.play();

      showSnackBar(
        context,
        () {},
        message: "Playing ${folderSongs.length} songs from ${folder.name}",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error playing folder: $e",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Play next folder
  void _playNextFolder(domain.Folder folder) async {
    try {
      final _repo = locator<FolderRepository>();
      List<SongsModel> folderSongs = (await _repo.getSongsForFolder(
        folder.id!,
      )).cast<SongsModel>();

      if (folderSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Folder contains no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      if (musicService.songs.isEmpty) {
        await musicService.setPlaylist(folderSongs, startIndex: 0);
        await musicService.play();
      } else {
        final updateCount = await musicService.playNextMultipleSongs(folderSongs);
        // final currentIndex = musicService.currentIndex;
        // final insertIndex = currentIndex + 1;
        // final newSongsList = List<SongsModel>.from(musicService.songs);
        //
        // final songsToAdd = folderSongs.where((song) {
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
        message: "Error adding folder to play next",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add folder to queue
  void _addFolderToQueue(domain.Folder folder) async {
    try {
      final _repo = locator<FolderRepository>();
      List<SongsModel> folderSongs = (await _repo.getSongsForFolder(
        folder.id!,
      )).cast<SongsModel>();

      if (folderSongs.isEmpty) {
        showSnackBar(
          context,
          () {},
          message: "Folder contains no songs",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      final addedSong = await musicService.addMultipleSongsToQueue(folderSongs);

      if (mounted) {
        if (addedSong < 1) {
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
            message: "$addedSong songs added to queue",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
      }

      // final newSongsList = List<SongsModel>.from(musicService.songs);
      // int addedCount = 0;
      //
      // for (final song in folderSongs) {
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
      //   if(addedCount < 1){
      //     showSnackBar(
      //       context,
      //           () {},
      //       message: "Songs already added to queue",
      //       alertBannerLocation: AlertBannerLocation.bottom,
      //     );
      //   }
      //   else{
      //     showSnackBar(
      //       context,
      //           () {},
      //       message: "$addedCount songs from ${folder.name} added to queue",
      //       alertBannerLocation: AlertBannerLocation.bottom,
      //     );
      //   }

    } catch (e) {
      showSnackBar(
        context,
        () {},
        message: "Error adding folder to queue",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Add folder to playlist
  void _addFolderToPlaylist(domain.Folder folder) async {
    try {
      // Capture PlaylistBloc before async operations
      final playlistBloc = context.read<PlaylistBloc>();

      final _repo = locator<FolderRepository>();
      List<SongsModel> folderSongs = (await _repo.getSongsForFolder(
        folder.id!,
      )).cast<SongsModel>();

      if (folderSongs.isEmpty) {
        if (mounted) {
          showSnackBar(
            context,
            () {},
            message: "Folder contains no songs",
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
            child: PlaylistBottomSheet(songsList: folderSongs),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error fetching songs from folder: $e",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    }
  }

  // Hide/Unhide folder
  Future<void> _updateFolderHiddenStatus(
    domain.Folder folder,
    bool hide,
  ) async {
    if (folder.id == null) return;

    try {
      final updateHiddenStatus = locator<UpdateFolderHiddenStatus>();
      final repo = locator<FolderRepository>();
      final songs = await repo.getSongsForFolder(folder.id!);
      await updateHiddenStatus(folder.id!, hide);
      for(final song in songs){
        await musicService.removeDeletedSongFromQueue(song.id!);
      }
      if (!mounted) return;
      context.read<FolderBloc>().add(const FolderEvent.fetchAllFolders());
      context.read<SongsBloc>().add(const SongsEvent.getAllSongs());
      showSnackBar(
        context,
        () {},
        message: hide
            ? '"${folder.name}" hidden successfully'
            : '"${folder.name}" is visible again',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        context,
        () {},
        message: 'Failed to update folder: $e',
        backgroundColor: Colors.red,
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  // Delete folder
  void _deleteFolder(domain.Folder folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      isScrollControlled: true,
      builder: (_) => _buildDeleteConfirmationDialog(folder),
    );
  }

  Widget _buildDeleteConfirmationDialog(domain.Folder folder) {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Container(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 10.h,
        bottom: bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 30.h),
          Texts(
            'Delete Folder',
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          SizedBox(height: 30.h),
          Texts(
            'Are you sure you want to delete "${folder.name}"?',
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
            align: TextAlign.center,
          ),
          SizedBox(height: 25.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Texts(
                        S.of(context).cancel,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.inter,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.read<FolderBloc>().add(
                      FolderEvent.deleteFolder(folder.id!),
                    );
                    Navigator.pop(context);
                    showSnackBar(
                      context,
                      () {},
                      message: "Folder deleted successfully!",
                      alertBannerLocation: AlertBannerLocation.bottom,
                    );
                  },
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Texts(
                        S.of(context).delete,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.inter,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
