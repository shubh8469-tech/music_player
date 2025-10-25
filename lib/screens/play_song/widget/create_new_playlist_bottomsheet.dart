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

class CreateNewPlaylistBottomSheet extends StatefulWidget {
  const CreateNewPlaylistBottomSheet({super.key});

  @override
  _CreateNewPlaylistBottomSheetState createState() =>
      _CreateNewPlaylistBottomSheetState();
}

class _CreateNewPlaylistBottomSheetState
    extends State<CreateNewPlaylistBottomSheet> {
  TextEditingController playlistNameController = TextEditingController();
  FocusNode playlistNameFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final double minHeight = 0.35.sh;

    // Handle keyboard visibility and safe area (especially for Samsung One UI 7.0)
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
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
          SizedBox(height: 30.h),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: 15.0.h, top: 10.h),
              child: TextFieldWidget(
                controller: playlistNameController,
                fillColor: AppColors.textColor.withValues(alpha: .2),
                wantListeners: true,
                cursorColor: AppColors.textColor,
                textStyleColor: AppColors.textColor,
                textInputAction: TextInputAction.done,
                hintText: "Enter Playlist Name",
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  fontFamily: AppFonts.inter,
                  fontWeight: FontWeight.w400,
                ),
                focusNode: playlistNameFocusNode,
                hasFocus: playlistNameFocusNode.hasFocus,
                onFieldSubmitted: (value) {
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
          ),
          SizedBox(height: 25.h),

          BottomButtonTwo(
            leftBtnTitle: S.of(context).cancel,
            rightBtnTitle: "Create",
            lefBtnTap: () {},
            rightBtnTap: () {
              context.read<PlaylistBloc>().add(
                PlaylistEvent.addPlaylist(playlistNameController.text),
              );
            },
          ),
        ],
      ),
    );
  }
}
