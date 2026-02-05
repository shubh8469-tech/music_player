import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/commonWidgets/bottom_button_two.dart';
import 'package:music_app/features/playlists/bloc/playlist_bloc.dart';
import 'package:music_app/themes/font.dart';

import '../../../commonWidgets/textWidget.dart';
import '../../../commonWidgets/text_field_widget.dart';
import '../../../generated/assets.dart';
import '../../../l10n/l10n.dart';
import '../../../themes/color.dart';
import '../../../utills/playlist_validation.dart';

class CreateNewPlaylistBottomSheet extends StatefulWidget {
  const CreateNewPlaylistBottomSheet({super.key});

  @override
  _CreateNewPlaylistBottomSheetState createState() =>
      _CreateNewPlaylistBottomSheetState();
}

class _CreateNewPlaylistBottomSheetState
    extends State<CreateNewPlaylistBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController playlistNameController = TextEditingController();
  FocusNode playlistNameFocusNode = FocusNode();

  void _createPlaylist() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final playlistName = playlistNameController.text.trim();
    context.read<PlaylistBloc>().add(
          PlaylistEvent.addPlaylist(playlistName),
        );
    Navigator.pop(context);
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

    return SafeArea(
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
              validator: PlaylistValidation.validatePlaylistName,
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
  );
  }
}
