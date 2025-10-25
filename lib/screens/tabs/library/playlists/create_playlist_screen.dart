import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/playlists/bloc/playlist_bloc.dart';
import 'package:music_app/themes/font.dart';

import '../../../../themes/color.dart';
import '../../../../utills/snack_bar.dart';

/// CreatePlaylistScreen - A screen for creating a new playlist
///
/// Usage:
/// ```dart
/// // Navigate to CreatePlaylistScreen as full screen
/// context.push('/dashboard/create-playlist');
///
/// // Or show as bottom sheet (recommended)
/// CreatePlaylistScreen.showAsBottomSheet(context);
///
/// // Or show as modal
/// CreatePlaylistScreen.showAsModal(context);
/// ```
class CreatePlaylistScreen extends StatefulWidget {
  final bool isBottomSheet;

  const CreatePlaylistScreen({super.key, this.isBottomSheet = false});

  /// Show the CreatePlaylistScreen as a bottom sheet
  static void showAsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => const CreatePlaylistScreen(isBottomSheet: true),
    );
  }

  /// Show the CreatePlaylistScreen as a modal
  static void showAsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: true,
      builder: (context) => const CreatePlaylistScreen(),
    );
  }

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
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

    final playlistName = playlistNameController.text.trim();

    if (playlistName.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: "Please enter a playlist name",
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

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
                .lastOrNull;
          },
          orElse: () {},
        );

        if (newPlaylist == null) {
          throw Exception('Failed to get newly created playlist');
        }

        // showSnackBar(
        //   context,
        //   () {},
        //   message: "Playlist '$playlistName' created successfully!",
        //   alertBannerLocation: AlertBannerLocation.bottom,
        // );

        // Navigate to AddSongsScreen with the actual created playlist
        context.pushReplacement('/dashboard/add-songs', extra: newPlaylist);
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
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // If it's a bottom sheet, return the content directly
    if (widget.isBottomSheet) {
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

            SizedBox(height: 30.h),

            // Input field
            Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: TextField(
                controller: playlistNameController,
                focusNode: playlistNameFocusNode,
                decoration: InputDecoration(
                  border: InputBorder.none,
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
                ),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontFamily: AppFonts.inter,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _createPlaylist(),
              ),
            ),

            SizedBox(height: 30.h),

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
                        borderRadius: BorderRadius.circular(8.r),
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
                        borderRadius: BorderRadius.circular(8.r),
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

            SizedBox(height: 16.h),
          ],
        ),
      );
    }

    // Full screen layout
    return Scaffold(
      backgroundColor: Colors.grey[800], // Dark gray background
      body: SafeArea(
        child: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            constraints: BoxConstraints(maxWidth: 400.w, maxHeight: 0.7.sh),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
                bottomLeft: Radius.circular(10.r),
                bottomRight: Radius.circular(10.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top handle bar
                Container(
                  margin: EdgeInsets.only(top: 8.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                SizedBox(height: 30.h),

                // Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    'Create new playlist',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: AppFonts.inter,
                      color: AppColors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 30.h),

                // Input field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: TextField(
                      controller: playlistNameController,
                      focusNode: playlistNameFocusNode,
                      decoration: InputDecoration(
                        border: InputBorder.none,
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
                      ),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontFamily: AppFonts.inter,
                        fontWeight: FontWeight.w400,
                        color: AppColors.black,
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _createPlaylist(),
                    ),
                  ),
                ),

                SizedBox(height: 30.h),

                // Action buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: GestureDetector(
                          onTap: _cancel,
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.r),
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
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: _isCreating
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
