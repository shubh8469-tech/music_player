import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/playlists/presentation/bloc/playlist_bloc.dart';
import 'package:music_app/themes/font.dart';

import 'package:music_app/themes/color.dart';
import 'package:music_app/core/utils/playlist_validation.dart';
import 'package:music_app/core/utils/snack_bar.dart';

/// CreatePlaylistBottomSheet - A bottom sheet for creating a new playlist
///
/// Usage:
/// ```dart
/// CreatePlaylistBottomSheet.show(context);
/// ```
class CreatePlaylistBottomSheet extends StatefulWidget {
  const CreatePlaylistBottomSheet({super.key});

  /// Show the CreatePlaylistBottomSheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
      ),
      isScrollControlled: true,
      builder: (_) => const CreatePlaylistBottomSheet(),
    );
  }

  @override
  State<CreatePlaylistBottomSheet> createState() =>
      _CreatePlaylistBottomSheetState();
}

class _CreatePlaylistBottomSheetState extends State<CreatePlaylistBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController playlistNameController = TextEditingController();
  FocusNode playlistNameFocusNode = FocusNode();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      playlistNameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    playlistNameController.dispose();
    playlistNameFocusNode.dispose();
    super.dispose();
  }

  void _createPlaylist() async {
    if (_isCreating) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final playlistName = playlistNameController.text.trim();

    setState(() {
      _isCreating = true;
    });

    try {
      final playlistBloc = context.read<PlaylistBloc>();

      // Create the playlist using the bloc
      playlistBloc.add(PlaylistEvent.addPlaylist(playlistName));

      // Wait for the state to update and get the newly created playlist
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Get the newly created playlist from the bloc state
        final state = playlistBloc.state;

        dynamic newPlaylist;
        state.maybeWhen(
          loaded: (playlists, systemPlaylistSongs) {
            // Find the playlist with the matching name (should be the most recent one)

            newPlaylist = playlists
                .where((p) => p.name == playlistName && p.isSystem != true)
                .firstOrNull;
          },
          orElse: () {},
        );

        if (newPlaylist == null) {
          throw Exception('Failed to get newly created playlist');
        }

        // Close the bottom sheet first
        Navigator.of(context).pop();

        // showSnackBar(
        //   context,
        //   () {},
        //   message: "Playlist '$playlistName' created successfully!",
        //   alertBannerLocation: AlertBannerLocation.bottom,
        // );

        // Navigate to AddSongsScreen with the actual created playlist
        context.push('/dashboard/add-songs', extra: newPlaylist);
      }
    } catch (e) {
      log('Error creating playlist: $e');
      if (mounted) {
        showSnackBar(
          context,
          () {},
          message: "Error creating playlist",
          alertBannerLocation: AlertBannerLocation.bottom,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 20.h
        : (viewPadding > 0 ? viewPadding : 20.h); // + 16.h;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 10.h,
          bottom: bottomPadding, //20.h,
        ),
        child: Form(
          key: _formKey,
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
            Text(
              'Create new playlist',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.inter,
                color: AppColors.black,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 35.h),

            // Input field
            TextFormField(
              controller: playlistNameController,
              focusNode: playlistNameFocusNode,
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
            ),

            SizedBox(height: 37.h),

            // Action buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: GestureDetector(
                    onTap: _cancel,
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
                    onTap: _isCreating ? null : _createPlaylist,
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: _isCreating
                            ? Colors.grey[400]
                            : AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Center(
                        child: _isCreating
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              )
                            : Text(
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
    );
  }
}
