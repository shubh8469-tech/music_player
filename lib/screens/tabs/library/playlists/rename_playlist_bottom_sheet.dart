import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../features/playlists/bloc/playlist_bloc.dart';
import '../../../../features/playlists/domain/entities/playlist.dart' as domain;
import '../../../../themes/color.dart';
import '../../../../themes/font.dart';
import '../../../../l10n/l10n.dart';
import '../../../../utills/snack_bar.dart';

class RenamePlaylistBottomSheet extends StatefulWidget {
  final domain.Playlist playlist;

  const RenamePlaylistBottomSheet({super.key, required this.playlist});

  @override
  State<RenamePlaylistBottomSheet> createState() =>
      _RenamePlaylistBottomSheetState();
}

class _RenamePlaylistBottomSheetState extends State<RenamePlaylistBottomSheet> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isRenaming = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.playlist.name);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRename() async {
    if (_isRenaming) return;

    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      showSnackBar(
        context,
        () {},
        message: 'Please enter a playlist name',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    if (newName == widget.playlist.name) {
      Navigator.of(context).pop();
      return;
    }

    final playlistId = widget.playlist.id;
    if (playlistId == null) {
      showSnackBar(
        context,
        () {},
        message: 'Playlist information missing',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
      return;
    }

    setState(() => _isRenaming = true);

    try {
      final playlistBloc = context.read<PlaylistBloc>();
      playlistBloc.add(PlaylistEvent.renamePlaylist(playlistId, newName));
      Navigator.of(context).pop(newName);
    } catch (e) {
      setState(() => _isRenaming = false);
      showSnackBar(
        context,
        () {},
        message: 'Unable to rename playlist',
        backgroundColor: Colors.red,
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0
        ? viewInsets + 16.h
        : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return Padding(
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
          Text(
            'Rename Playlist',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              fontFamily: AppFonts.inter,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                hintText: 'Enter new playlist name',
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
                color: AppColors.textColor,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleRename(),
            ),
          ),
          SizedBox(height: 30.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    child: Center(
                      child: Text(
                        S.of(context).cancel,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.inter,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: _isRenaming ? null : _handleRename,
                  child: Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: _isRenaming
                          ? Colors.grey[400]
                          : AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    child: Center(
                      child: _isRenaming
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
                              S.of(context).rename,
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
          // SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
