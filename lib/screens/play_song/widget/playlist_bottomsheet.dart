import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/themes/font.dart';
import '../../../../features/playlists/domain/entities/playlist.dart' as domain;
import '../../../commonWidgets/MusicListTile.dart';
import '../../../commonWidgets/bottom_button_two.dart';
import '../../../commonWidgets/textWidget.dart';
import '../../../features/playlists/bloc/playlist_bloc.dart';
import '../../../features/songs/data/models/song_model.dart';
import '../../../generated/assets.dart';
import '../../../l10n/l10n.dart';
import '../../../themes/color.dart';
import 'create_new_playlist_bottomsheet.dart';

class PlaylistBottomSheet extends StatefulWidget {
  const PlaylistBottomSheet({super.key, this.songId, this.songsList})
    : assert(
        songId != null || songsList != null,
        'Either songId or songsList must be provided',
      );

  final int? songId;
  final List<SongsModel>? songsList;

  @override
  _PlaylistBottomSheetState createState() => _PlaylistBottomSheetState();
}

class _PlaylistBottomSheetState extends State<PlaylistBottomSheet> {
  int selectedPlaylist = 0;
  bool _isAddingSongs = false;

  @override
  Widget build(BuildContext context) {
    final double maxHeight = 0.75.sh;

    return BlocBuilder<PlaylistBloc, PlaylistState>(
      builder: (context, state) {
        return state.maybeWhen(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (message) => Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),

          loaded: (allPlayLists, systemPlaylistSongs) {
            final playlists = allPlayLists
                .where((p) => (p.isSystem != true))
                .cast<domain.Playlist>()
                .toList();

            return Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                top: 10.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(Assets.svgIcLineBottom),
                  SizedBox(height: 20.h),
                  Texts(
                    'Add to playlist',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.inter,
                  ),
                  SizedBox(height: 16.h),

                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          leading: SvgPicture.asset(Assets.svgIcPlus),
                          title: Texts(
                            'Create new playlist',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFonts.inter,
                          ),
                          onTap: () {
                            // Navigator.of(context).pop();
                            createNewPlayListWidget();
                          },
                        ),
                        SizedBox(height: 8.h),
                        Column(
                          children: List.generate(playlists.length, (index) {
                            final playlist = playlists[index];
                            final isSelected = selectedPlaylist == playlist.id;

                            return Column(
                              children: [
                                MusicListTile(
                                  margin: 7.w,
                                  height: 66.h,
                                  borderRadius: 10.r,
                                  backgroundColor:
                                      AppColors.musicTileBackgroundColor,
                                  cardHeight: 50.h,
                                  cardWidth: 50.w,
                                  cardRadius: 7.r,
                                  noLogoGradientColor: [
                                    AppColors.mildOrange.withValues(
                                      alpha: 0.21,
                                    ),
                                    AppColors.primaryOrange,
                                  ],
                                  cardIconAsset: Assets.svgMusicIcon,
                                  cardIconSize: 32.r,
                                  title: playlist.name,
                                  subtitle:
                                      "${playlist.songCount} Songs", // <-- fixed subtitle
                                  trailingIconAsset: isSelected
                                      ? Assets.svgIcCheck
                                      : Assets.svgIcUncheck,
                                  trailingIconHeight: 20.h,
                                  trailingIconWidth: 10.w,
                                  trailingMargin: 2.w,
                                  onTap: () => setState(() {
                                    if (selectedPlaylist == playlist.id) {
                                      selectedPlaylist = 0;
                                    } else {
                                      selectedPlaylist = playlist.id!;
                                    }
                                  }),
                                ),

                                if (index == playlists.length - 1) ...[
                                  SizedBox(height: 12.h),
                                  BottomButtonTwo(
                                    leftBtnTitle: S.of(context).cancel,
                                    rightBtnTitle: "Add",
                                    lefBtnTap: () {},
                                    rightBtnTap: () {
                                      addSongToPlaylist(
                                        playlistId: selectedPlaylist,
                                        position: playlist.songCount,
                                      );
                                    },
                                  ),
                                  SizedBox(height: 16.h),
                                ],
                              ],
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          orElse: () => Container(child: Text('$state')),
        );
      },
    );
  }

  void addSongToPlaylist({
    required int playlistId,
    required int position,
  }) async {
    // Prevent multiple simultaneous executions
    if (_isAddingSongs) return;
    _isAddingSongs = true;

    try {
      // Store the bloc reference before any async operations
      final playlistBloc = context.read<PlaylistBloc>();

      if (widget.songsList != null && widget.songsList!.isNotEmpty) {
        // Add multiple songs using the new batch method
        log('Adding ${widget.songsList!.length} songs to playlist $playlistId');
        final songIds = widget.songsList!.map((song) => song.id!).toList();
        playlistBloc.add(
          PlaylistEvent.addMultipleSongsToPlaylist(playlistId, songIds),
        );
      } else if (widget.songId != null) {
        // Add single song
        if (!mounted) return;

        log(
          'Adding song ${widget.songId} to playlist $playlistId at position $position',
        );
        playlistBloc.add(
          PlaylistEvent.addSongToPlaylist(playlistId, widget.songId!, position),
        );
      }

      // Close the bottom sheet if still mounted
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      log('Error adding songs to playlist: $e');
    } finally {
      _isAddingSongs = false;
    }
  }

  void createNewPlayListWidget() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      isScrollControlled: true,
      builder: (_) => CreateNewPlaylistBottomSheet(),
    );
  }
}
