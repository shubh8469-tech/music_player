import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';
import '../../../commonWidgets/app_bar_with_icon_title.dart';
import '../../../commonWidgets/gradientCard.dart';
import '../../../commonWidgets/text_field_widget.dart';
import '../../../generated/assets.dart';
import '../../../l10n/l10n.dart';
import '../../../themes/color.dart';

class EditSongDetailsScreen extends StatefulWidget {
  final SongsModel song;

  const EditSongDetailsScreen({
    super.key,
    required this.song,
  });

  @override
  State<EditSongDetailsScreen> createState() => _EditSongDetailsScreenState();
}

class _EditSongDetailsScreenState extends State<EditSongDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController albumController = TextEditingController();
  final TextEditingController artistController = TextEditingController();
  final TextEditingController genreController = TextEditingController();
  final TextEditingController trackController = TextEditingController();

  final FocusNode titleFocusNode = FocusNode();
  final FocusNode albumFocusNode = FocusNode();
  final FocusNode artistFocusNode = FocusNode();
  final FocusNode trackFocusNode = FocusNode();

  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.song.title;
    albumController.text = widget.song.album;
    artistController.text = widget.song.artist;
    genreController.text = widget.song.genre;
    trackController.text = '';

    for (final controller in [
      titleController,
      albumController,
      artistController,
      genreController,
      trackController,
    ]) {
      controller.addListener(_onValueChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      titleController,
      albumController,
      artistController,
      genreController,
      trackController,
    ]) {
      controller
        ..removeListener(_onValueChanged)
        ..dispose();
    }

    titleFocusNode.dispose();
    albumFocusNode.dispose();
    artistFocusNode.dispose();
    trackFocusNode.dispose();
    super.dispose();
  }

  void _onValueChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _handleCancel() {
    if (_isSaving) return;
    Navigator.pop(context);
  }

  void _handleSave() {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final trimmedTitle = titleController.text.trim();
    final trimmedAlbum = albumController.text.trim();
    final trimmedArtist = artistController.text.trim();
    final trimmedGenre = genreController.text.trim();

    final resolvedAlbum =
        trimmedAlbum.isEmpty ? widget.song.album : trimmedAlbum;
    final resolvedArtist =
        trimmedArtist.isEmpty ? widget.song.artist : trimmedArtist;
    final resolvedGenre =
        trimmedGenre.isEmpty ? widget.song.genre : trimmedGenre;

    if (!_hasChanges &&
        trimmedTitle == widget.song.title &&
        resolvedAlbum == widget.song.album &&
        resolvedArtist == widget.song.artist &&
        resolvedGenre == widget.song.genre) {
      _showSnack('No changes to save');
      return;
    }

    final updatedSong = SongsModel(
      id: widget.song.id,
      title: trimmedTitle,
      artist: resolvedArtist,
      album: resolvedAlbum,
      genre: resolvedGenre,
      year: widget.song.year,
      duration: widget.song.duration,
      filePath: widget.song.filePath,
      folder: widget.song.folder,
      artwork_path: widget.song.artwork_path,
      createdTime: widget.song.createdTime,
      updatedTime: DateTime.now().toIso8601String(),
      playCount: widget.song.playCount,
      lastPlayed: widget.song.lastPlayed,
      isFavorite: widget.song.isFavorite,
      isHidden: widget.song.isHidden,
    );

    setState(() {
      _isSaving = true;
    });

    context.read<SongsBloc>().add(
          SongsEvent.updateSongDetails(updatedSong),
        );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : AppColors.primaryOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SongsBloc, SongsState>(
      listenWhen: (_, __) => _isSaving,
      listener: (context, state) {
        state.maybeWhen(
          loaded: (_) {
            if (!_isSaving) return;
            setState(() {
              _isSaving = false;
            });
            Navigator.pop(context, true);
          },
          error: (message) {
            if (!_isSaving) return;
            setState(() {
              _isSaving = false;
            });
            _showSnack(message, isError: true);
          },
          orElse: () {},
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBarWithIconTitle(title: S.of(context).editDetails),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 25, horizontal: 15),
                  child: Column(
                    children: [
                      GradientCard(
                        height: 100.h,
                        width: 100.w,
                        colors: [
                          AppColors.mildOrange.withValues(alpha: 0.21),
                          AppColors.primaryOrange,
                        ],
                        borderRadius: 8.r,
                        iconAsset: Assets.svgIcTunes,
                        iconSize: 80.r,
                        title: "",
                        onTap: () {
                          _showSnack(
                            'Change cover feature coming soon',
                          );
                        },
                        margin: 10.w,
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(80.r),
                          border: Border.all(
                            color: AppColors.black.withValues(alpha: 0.10),
                            width: 1.w,
                          ),
                        ),
                        height: 50.h,
                        width: 150.w,
                        child: Texts(
                          S.of(context).changeCover,
                          align: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 50.h),
                      _buildTitleField(),
                      _buildAlbumField(),
                      _buildArtistField(),
                      _buildTrackField(),
                    ],
                  ),
                ),
              ),
            ),
            if (_isSaving)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(vertical: 25.0),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _isSaving ? null : _handleCancel,
                  borderRadius: BorderRadius.circular(80.r),
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
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: InkWell(
                  onTap: _isSaving ? null : _handleSave,
                  borderRadius: BorderRadius.circular(80.r),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isSaving
                          ? AppColors.primaryOrange.withValues(alpha: 0.6)
                          : AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(80),
                      border: Border.all(
                        color: AppColors.black.withValues(alpha: 0.10),
                        width: 1,
                      ),
                    ),
                    height: 50.w,
                    child: Texts(
                      S.of(context).save,
                      fontSize: 14.sp,
                      align: TextAlign.center,
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFonts.medium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texts(
          S.of(context).title,
          fontSize: 14.sp,
          color: AppColors.textColor,
          fontWeight: FontWeight.w400,
          fontFamily: AppFonts.inter,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 10),
          child: TextFieldWidget(
            controller: titleController,
            fillColor: AppColors.textColor.withValues(alpha: .2),
            wantListeners: true,
            cursorColor: AppColors.textColor,
            textStyleColor: AppColors.textColor,
            textInputAction: TextInputAction.next,
            focusNode: titleFocusNode,
            hasFocus: titleFocusNode.hasFocus,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(albumFocusNode);
            },
            onTextChanged: (_) => _onValueChanged(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title cannot be empty';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texts(
          S.of(context).album,
          fontSize: 14.sp,
          color: AppColors.textColor,
          fontWeight: FontWeight.w400,
          fontFamily: AppFonts.inter,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 10),
          child: TextFieldWidget(
            controller: albumController,
            fillColor: AppColors.textColor.withValues(alpha: .2),
            wantListeners: true,
            cursorColor: AppColors.textColor,
            textStyleColor: AppColors.textColor,
            textInputAction: TextInputAction.next,
            focusNode: albumFocusNode,
            hasFocus: albumFocusNode.hasFocus,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(artistFocusNode);
            },
            onTextChanged: (_) => _onValueChanged(),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texts(
          S.of(context).artist,
          fontSize: 14.sp,
          color: AppColors.textColor,
          fontWeight: FontWeight.w400,
          fontFamily: AppFonts.inter,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 10),
          child: TextFieldWidget(
            controller: artistController,
            fillColor: AppColors.textColor.withValues(alpha: .2),
            wantListeners: true,
            cursorColor: AppColors.textColor,
            textStyleColor: AppColors.textColor,
            textInputAction: TextInputAction.next,
            focusNode: artistFocusNode,
            hasFocus: artistFocusNode.hasFocus,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(trackFocusNode);
            },
            onTextChanged: (_) => _onValueChanged(),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texts(
          S.of(context).trackNumber,
          fontSize: 14.sp,
          color: AppColors.textColor,
          fontWeight: FontWeight.w400,
          fontFamily: AppFonts.inter,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 10),
          child: TextFieldWidget(
            controller: trackController,
            fillColor: AppColors.textColor.withValues(alpha: .2),
            wantListeners: true,
            cursorColor: AppColors.textColor,
            textStyleColor: AppColors.textColor,
            textInputAction: TextInputAction.done,
            focusNode: trackFocusNode,
            hasFocus: trackFocusNode.hasFocus,
            onFieldSubmitted: (_) => _handleSave(),
            onTextChanged: (_) => _onValueChanged(),
          ),
        ),
      ],
    );
  }
}
