import 'dart:developer' as logS;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/folders/bloc/folder_bloc.dart';
import 'package:music_app/features/folders/domain/entities/folder.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/song_menu_screen.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../features/folders/domain/repositories/folder_repository.dart';
import '../../../../generated/assets.dart';
import '../../../../core/di/injection.dart';
import '../../../../utills/globals.dart';
import '../../../../utills/snack_bar.dart';
import '../widgets/mini_player_bar.dart';

class FolderDetailScreen extends StatefulWidget {
  final Folder folder;
  const FolderDetailScreen({super.key, required this.folder});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  final _repo = locator<FolderRepository>();
  final _player = MusicPlayerService();

  List<SongsModel> _songs = [];
  List<SongsModel> _baseSongs = [];
  Folder _currentFolder = Folder(
    id: 0,
    name: '',
    path: '',
    songCount: 0,
    createdTime: DateTime.now(),
    updatedTime: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _currentFolder = widget.folder;
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await _repo.getSongsForFolder(_currentFolder.id!);
    if (mounted) {
      setState(() {
        _songs = songs.cast<SongsModel>();
        _baseSongs = List<SongsModel>.from(_songs);
      });
    }
  }

  Future<void> _refreshFolderData() async {
    // Refresh folder data to get updated song count
    final folderBloc = context.read<FolderBloc>();
    folderBloc.add(const FolderEvent.fetchAllFolders());
  }

  Widget _songTile(List<SongsModel> list, int index) {
    final song = list[index];
    return StreamBuilder<int?>(
      stream: _player.currentSongIdStream,
      initialData: _player.currentSongId,
      builder: (context, idSnap) {
        final currentId = idSnap.data;
        final isCurrent = song.id == currentId;
        return Material(
          key: ValueKey(song.id),
          color: Colors.transparent,
          child: Column(
            children: [
              MusicListTile(
                margin: 7.w,
                height: 66.h,
                borderRadius: 10.r,
                backgroundColor: AppColors.musicTileBackgroundColor,
                cardHeight: 50.h,
                cardWidth: 50.w,
                cardRadius: 7.r,
                cardIconAsset: song.artwork_path ?? Assets.svgMusicIcon,
                cardIconSize: 32.r,
                isSvgCardIcon: (song.artwork_path ?? '').contains('.svg') || song.artwork_path == null,
                title: song.title,
                subtitle: song.artist,
                trailingIconAsset: Assets.svgMenuIcon,
                trailingIconHeight: 19.5.h,
                trailingIconWidth: 3.w,
                trailingMargin: 10.w,
                isGifLoad: isCurrent,
                onTap: () async {
                  await _player.setPlaylist(list, startIndex: index);
                  await _player.play();
                },
                onPlayTap: () async {
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
                    builder: (_) => SongMenuScreen(
                      songMenuList: songMenuItems,
                      isPlaying: false,
                      currentSong: song,
                      songIndex: index,
                      songsList: list,
                      maxHeight: 0.87.sh,
                      systemKeyOrId: _currentFolder.id.toString(),
                      isSystemPlaylist: false,
                      from: 'folder_in',
                      onSongDeleted: () {
                        // Immediately remove the song from local list for instant UI update
                        final songId = song.id;
                        setState(() {
                          _songs.removeWhere((s) => s.id == songId);
                          _baseSongs.removeWhere((s) => s.id == songId);
                          // Decrement folder count temporarily (will be synced from DB)
                          _currentFolder = Folder(
                            id: _currentFolder.id,
                            name: _currentFolder.name,
                            path: _currentFolder.path,
                            songCount: _currentFolder.songCount - 1,
                            artworkPath: _currentFolder.artworkPath,
                            createdTime: _currentFolder.createdTime,
                            updatedTime: _currentFolder.updatedTime,
                          );
                        });

                        // Wait for database operations and triggers to complete, then sync with DB
                        Future.delayed(
                          const Duration(milliseconds: 800),
                          () async {
                            if (mounted) {
                              await _loadSongs();
                              _refreshFolderData();
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Custom delete folder confirmation bottom sheet
  Widget _buildDeleteFolderConfirmationDialog() {
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
          // Top handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 30.h),

          // Title
          Texts(
            'Delete Folder',
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          SizedBox(height: 30.h),

          // Message
          Texts(
            'Are you sure you want to delete this folder?',
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
            align: TextAlign.center,
          ),
          SizedBox(height: 25.h),

          // Action buttons
          Row(
            children: [
              // Cancel button
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
                        'Cancel',
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

              // Delete button
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    Navigator.pop(context); // Close bottom sheet

                    // Delete folder
                    final folderBloc = context.read<FolderBloc>();
                    folderBloc.add(
                      FolderEvent.deleteFolder(_currentFolder.id!),
                    );

                    // Show success message
                    showSnackBar(
                      context,
                      () {},
                      message: 'Folder deleted successfully',
                      alertBannerLocation: AlertBannerLocation.bottom,
                    );

                    // Navigate back to previous screen
                    context.pop();
                  },
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Texts(
                        'Delete',
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<FolderBloc, FolderState>(
          listener: (context, state) {
            // Update current folder when folders are refreshed
            state.maybeWhen(
              loaded: (folders, folderSongs) {
                // Find the updated folder with new song count
                final updatedFolder = folders.firstWhere(
                  (folder) => folder.id == _currentFolder.id,
                  orElse: () => _currentFolder,
                );
                // Update folder if it exists and has changed
                if (updatedFolder.id == _currentFolder.id) {
                  final oldSongCount = _currentFolder.songCount;
                  final newSongCount = updatedFolder.songCount;
                  final songCountChanged = newSongCount != oldSongCount;
                  final hasChanged =
                      songCountChanged ||
                      updatedFolder.name != _currentFolder.name ||
                      updatedFolder.updatedTime != _currentFolder.updatedTime;

                  if (hasChanged && mounted) {
                    setState(() {
                      _currentFolder = updatedFolder;
                    });
                    // Only reload songs if the count actually decreased (song was deleted)
                    // This prevents unnecessary reloads when folder is just refreshed
                    if (songCountChanged && newSongCount < oldSongCount) {
                      _loadSongs();
                    }
                  }
                }
              },
              orElse: () {},
            );
          },
        ),
        BlocListener<SongsBloc, SongsState>(
          listener: (context, state) {
            // When a song is successfully removed, refresh folder data
            state.maybeWhen(
              loaded: (songs) {
                // Wait a bit for database trigger to update folder count, then refresh
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _refreshFolderData();
                  }
                });
              },
              orElse: () {},
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryOrange,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.white,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          title: Texts(
            _currentFolder.name,
            fontSize: 18.sp,
            fontWeight: AppFontWeights.medium,
            fontFamily: AppFonts.inter,
            color: AppColors.white,
          ),
          actions: [
            GestureDetector(
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
                  builder: (_) => _buildDeleteFolderConfirmationDialog(),
                );
              },
              child: Padding(
                padding: EdgeInsets.only(right: 12.w),
                child: SvgPicture.asset(
                  Assets.svgIcDelete,
                  colorFilter: const ColorFilter.mode(
                    AppColors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            StreamBuilder<List<SongsModel>>(
              stream: _player.songsChanged,
              initialData: _player.songs,
              builder: (context, snapshot) {
                // Always check the current state, not just the snapshot
                final hasAny = _player.songs.isNotEmpty;
                final showMiniPlayer = hasAny;

                return Padding(
                  padding: EdgeInsets.only(
                    left: 20.w,
                    right: 20.w,
                    top: 10.h,
                    bottom: showMiniPlayer
                        ? 74.h
                        : 10.h, // Space for MiniPlayerBar (which includes system nav bar padding)
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 15.h),
                      GradientCard(
                        height: 150.h,
                        width: 150.w,
                        colors: [
                          AppColors.mildOrange.withValues(alpha: 0.21),
                          AppColors.primaryOrange,
                        ],
                        borderRadius: 13.r,
                        iconAsset: Assets.svgDirectory,
                        iconSize: 60.r,
                        margin: 10.w,
                      ),
                      SizedBox(height: 14.h),
                      Texts(
                        _currentFolder.name,
                        fontSize: 20.sp,
                        fontWeight: AppFontWeights.medium,
                        fontFamily: AppFonts.inter,
                        color: AppColors.textColor,
                      ),

                      SizedBox(height: 25.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (_songs.isEmpty) return;

                              await _player.setPlaylist(
                                _songs,
                                autoPlay: false,
                              );
                              await _player
                                  .ensureShuffleOnAndReshuffleOnlyIndexNotAllSongsPosition();

                              // Wait until the player has fully updated its index
                              await _player.player.currentIndexStream
                                  .firstWhere((idx) => idx != null && idx != 0);

                              // Now play
                              await _player.play();

                              logS.log("Shuffle Play started");
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: 40.h,
                              width: 165.w,
                              decoration: BoxDecoration(
                                color: AppColors.shuffleBackground,
                                borderRadius: BorderRadius.circular(100.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    Assets.svgShuffle,
                                    height: 16.79.h,
                                    width: 17.77.w,
                                  ),
                                  SizedBox(width: 10.w),
                                  Texts(
                                    'Shuffle',
                                    fontWeight: AppFontWeights.medium,
                                    fontSize: 14.sp,
                                    color: AppColors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (_baseSongs.isEmpty) return;
                              await _player.ensureShuffleOff();

                              // Start from the first song of the folder
                              await _player.setPlaylist(
                                List<SongsModel>.from(_baseSongs),
                                startIndex: 0,
                                autoPlay: true,
                              );
                              await _player.play();
                            },
                            child: Container(
                              height: 40.h,
                              width: 165.w,
                              decoration: BoxDecoration(
                                color: AppColors.primaryOrange,
                                borderRadius: BorderRadius.circular(100.r),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    Assets.svgPlay,
                                    height: 16.79.h,
                                    width: 17.77.w,
                                  ),
                                  SizedBox(width: 10.w),
                                  Texts(
                                    'Play',
                                    fontWeight: AppFontWeights.medium,
                                    fontSize: 14.sp,
                                    color: AppColors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 25.h),

                      // Song count header
                      Row(
                        children: [
                          // Bullets icon and song count
                          GestureDetector(
                            onTap: () {
                              // Navigate to select song screen for folder management
                              context.push(
                                '/dashboard/select-song',
                                extra: {
                                  'folder': _currentFolder,
                                  'songs': _songs,
                                  'isSystemPlaylist': false,
                                },
                              );
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(Assets.svgSongsCount),
                                SizedBox(width: 8.w),
                                Texts(
                                  '${_currentFolder.songCount} songs',
                                  fontSize: 16.sp,
                                  fontWeight: AppFontWeights.medium,
                                  fontFamily: AppFonts.inter,
                                  color: AppColors.textColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 37.h),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            if (_songs.isEmpty) {
                              return Center(
                                child: Texts(
                                  'No songs available',
                                  fontSize: 16,
                                  fontWeight: AppFontWeights.regular,
                                  fontFamily: AppFonts.inter,
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: _songs.length,
                              itemBuilder: (context, index) {
                                return _songTile(_songs, index);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayerBar()),
          ],
        ),
      ),
    );
  }
}
