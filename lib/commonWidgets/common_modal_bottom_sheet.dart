import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_app/features/playlists/bloc/playlist_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import 'textWidget.dart';
import '../screens/play_song/widget/playlist_bottomsheet.dart';

/// A common confirmation bottom sheet for delete, hide, and similar actions.
/// Use [showCommonConfirmationBottomSheet] to display it with consistent styling.
class CommonConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmButtonText;
  final String? cancelButtonText;
  final Future<void> Function(BuildContext sheetContext)? onConfirm;
  final VoidCallback? onConfirmSync;

  const CommonConfirmationBottomSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmButtonText,
    this.cancelButtonText,
    this.onConfirm,
    this.onConfirmSync,
  }) : assert(
         onConfirm != null || onConfirmSync != null,
         'Either onConfirm or onConfirmSync must be provided',
       ),
       assert(
         onConfirm == null || onConfirmSync == null,
         'Cannot provide both onConfirm and onConfirmSync',
       );

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    final confirmText = confirmButtonText ?? S.of(context).delete;
    final cancelText = cancelButtonText ?? S.of(context).cancel;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 10.h,
          bottom: 20.h,
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
              title,
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.inter,
              color: AppColors.textColor,
            ),
            SizedBox(height: 30.h),
            Texts(
              message,
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
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Center(
                        child: Texts(
                          cancelText,
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
                    onTap: () async {
                      if (onConfirm != null) {
                        await onConfirm!(context);
                      } else if (onConfirmSync != null) {
                        onConfirmSync!();
                      }
                    },
                    child: Container(
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Center(
                        child: Texts(
                          confirmText,
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
          ],
        ),
      ),
    );
  }
}

/// Shows a common confirmation bottom sheet with consistent styling.
/// Use for delete, hide, and similar confirmation dialogs.
void showCommonConfirmationBottomSheet({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmButtonText,
  String? cancelButtonText,
  Future<void> Function(BuildContext sheetContext)? onConfirm,
  VoidCallback? onConfirmSync,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
    ),
    isScrollControlled: true,
    builder: (sheetContext) => CommonConfirmationBottomSheet(
      title: title,
      message: message,
      confirmButtonText: confirmButtonText,
      cancelButtonText: cancelButtonText,
      onConfirm: onConfirm,
      onConfirmSync: onConfirmSync,
    ),
  );
}

/// Shows the Add to Playlist bottom sheet with consistent modal styling.
/// Pass either [songId] for a single song or [songsList] for multiple songs.
void showCommonAddToPlaylistBottomSheet(
  BuildContext context, {
  int? songId,
  List<SongsModel>? songsList,
  PlaylistBloc? playlistBloc,
}) {
  assert(
    songId != null || (songsList != null && songsList.isNotEmpty),
    'Either songId or non-empty songsList must be provided',
  );

  final bloc = playlistBloc ?? context.read<PlaylistBloc>();

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
    ),
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: PlaylistBottomSheet(songId: songId, songsList: songsList),
    ),
  );
}
