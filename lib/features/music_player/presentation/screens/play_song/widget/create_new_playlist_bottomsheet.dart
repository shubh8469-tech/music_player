import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/core/widgets/bottom_button_two.dart';
import 'package:music_app/features/playlists/presentation/bloc/playlist_bloc.dart';
import 'package:music_app/themes/font.dart';

import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/core/widgets/text_field_widget.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/core/utils/playlist_validation.dart';
import 'package:music_app/core/utils/snack_bar.dart';

class CreateNewPlaylistBottomSheet extends StatefulWidget {
  final int? songId;
  final List<SongsModel>? songsList;
  final void Function({required int playlistId, required int position,})? onPlaylistCreated;
  const CreateNewPlaylistBottomSheet({super.key, this.songId, this.songsList, this.onPlaylistCreated});

  @override
  _CreateNewPlaylistBottomSheetState createState() =>
      _CreateNewPlaylistBottomSheetState();
}

class _CreateNewPlaylistBottomSheetState
    extends State<CreateNewPlaylistBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController playlistNameController = TextEditingController();
  FocusNode playlistNameFocusNode = FocusNode();

  /// Set when we dispatch addPlaylist; BlocListener uses these to add songs and pop once loaded.
  String? _pendingPlaylistName;
  List<int>? _pendingSongIds;

  void _createPlaylist() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final playlistName = playlistNameController.text.trim();

    List<int> songIds = [];
    if (widget.songsList != null) {
      for (var song in widget.songsList!) {
        if (song.id != null) songIds.add(song.id!);
      }
    }

    setState(() {
      _pendingPlaylistName = playlistName;
      _pendingSongIds = songIds.isEmpty ? null : songIds;
    });

    context.read<PlaylistBloc>().add(PlaylistEvent.addPlaylist(playlistName));
  }

  @override
  Widget build(BuildContext context) {
    final double minHeight = 0.35.sh;

    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 20.h
        : (viewPadding > 0 ? viewPadding : 20.h);

    return BlocListener<PlaylistBloc, PlaylistState>(
      listenWhen: (previous, current) {
        if (_pendingPlaylistName == null) return false;
        return current.maybeWhen(loaded: (_, __) => true, orElse: () => false);
      },
      listener: (context, state) {
        if (_pendingPlaylistName == null || !mounted) return;
        state.maybeWhen(
          loaded: (playlists, systemPlaylistSongs) {
            final name = _pendingPlaylistName!;
            final songIds = _pendingSongIds;
            final songId = widget.songId;
            final playlist = playlists
                .where((p) =>
                    p.name.toLowerCase().trim() == name.toLowerCase().trim())
                .firstOrNull;
            if (playlist == null) return;
            final playlistId = playlist.id;
            if (playlistId == null) return;

            setState(() {
              _pendingPlaylistName = null;
              _pendingSongIds = null;
            });

            if (songIds != null && songIds.isNotEmpty && mounted) {
              context.read<PlaylistBloc>().add(
                    PlaylistEvent.addMultipleSongsToPlaylist(playlistId, songIds),
                  );
              showSnackBar(
                context,
                () {},
                message: "${songIds.length} songs added to playlist",
                alertBannerLocation: AlertBannerLocation.bottom,
              );
            }
            else if (widget.songId != null) {
              context.read<PlaylistBloc>().add(
                PlaylistEvent.addSongToPlaylist(playlistId, widget.songId!, playlist.songCount),
              );
              showSnackBar(
                context,
                    () {},
                message: "1 songs added to playlist",
                alertBannerLocation: AlertBannerLocation.bottom,
              );
            }
            if (mounted){
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            }
          },
          orElse: () {},
        );
      },
      child: SafeArea(
      child: Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 10.h,
          bottom: bottomPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(Assets.svgIcLineBottom),
            SizedBox(height: 30.h),
            Texts(
              'Create new playlist',
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.inter,
            ),
            SizedBox(height: 35.h),
            TextFormField(
              controller: playlistNameController,
              // validator: PlaylistValidation.validatePlaylistName,
              validator: (value){
                const int maxNameLength = 100;

                final playlistBloc = context.read<PlaylistBloc>();

                bool status = false;

                playlistBloc.state.maybeWhen(
                  loaded: (playlists, systemPlaylistSongs) {
                    // Find the playlist with the matching name (should be the most recent one)

                    status = playlists.any((playlist) {
                      return playlist.name.toLowerCase().trim() == value?.toLowerCase().trim();
                    },);
                  },
                  orElse: () {},
                );

                if (value == null) {
                  return 'Please enter a playlist name';
                }

                final trimmed = value.trim();

                if (trimmed.isEmpty) {
                  return 'Please enter a playlist name';
                }

                if (trimmed.length > maxNameLength) {
                  return 'Playlist name must be at most $maxNameLength characters';
                }

                if(status){
                  return 'The name already exists, please try another name';
                }

                return null;
              },
              maxLength: PlaylistValidation.maxNameLength,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                suffixIconConstraints: const BoxConstraints(
                  minHeight: 0,
                  minWidth: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                hintText: 'Enter Playlist Name',
                hintStyle: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: AppFonts.inter,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
                errorStyle: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: AppFonts.inter,
                  color: Colors.red,
                ),
              ),
              style: TextStyle(
                fontSize: 16.sp,
                fontFamily: AppFonts.inter,
                fontWeight: FontWeight.w400,
                color: AppColors.black,
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _createPlaylist(),
              focusNode: playlistNameFocusNode,
            ),
            SizedBox(height: 37.h),

            Row(
              children: [
                // Cancel button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFonts.inter,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Create button
                Expanded(
                  child: GestureDetector(
                    onTap: _createPlaylist,
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Center(
                        child: Text(
                          'Create',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppFonts.inter,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    ),
  );
  }
}
