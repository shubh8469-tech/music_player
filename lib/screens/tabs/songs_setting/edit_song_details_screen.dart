import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/themes/font.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../commonWidgets/app_bar_with_icon_title.dart';
import '../../../commonWidgets/gradientCard.dart';
import '../../../commonWidgets/text_field_widget.dart';
import '../../../generated/assets.dart';
import '../../../l10n/l10n.dart';
import '../../../themes/color.dart';
import '../../../screens/common/image_crop_screen.dart';

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
  String? _artworkPath;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.song.title;
    albumController.text = widget.song.album;
    artistController.text = widget.song.artist;
    genreController.text = widget.song.genre;
    trackController.text = '';
    _artworkPath = widget.song.artwork_path;

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
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 25, horizontal: 15),
                    child: Column(
                      children: [
                        _buildCoverPreview(),
                        SizedBox(height: 20.h),
                        GestureDetector(
                          onTap: _handleChangeCover,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(80.r),
                              border: Border.all(
                                color: AppColors.black.withValues(alpha: 0.10),
                                width: 1.w,
                              ),
                            ),
                            height: 48.h,
                            width: 136.w,
                            child: Texts(
                              S.of(context).changeCover,
                              align: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(height: 33.h),
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
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
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
          fontWeight: AppFontWeights.regular,
          fontFamily: AppFonts.inter,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 10),
          child: TextFieldWidget(
            controller: titleController,
            fillColor: AppColors.textColor.withValues(alpha: .14),
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
            fillColor: AppColors.textColor.withValues(alpha: .14),
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
            fillColor: AppColors.textColor.withValues(alpha: .14),
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
            fillColor: AppColors.textColor.withValues(alpha: .14),
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

  Widget _buildCoverPreview() {
    final path = _artworkPath;
    final hasArtwork = path != null && path.isNotEmpty && File(path).existsSync();

    if (!hasArtwork) {
      return GradientCard(
        height: 140.h,
        width: 140.w,
        colors: [
          AppColors.mildOrange.withValues(alpha: 0.21),
          AppColors.primaryOrange,
        ],
        borderRadius: 16.r,
        iconAsset: Assets.svgIcTunes,
        iconSize: 80.r,
        title: "",
        margin: 10.w,
      );
    }

    return Container(
      height: 140.h,
      width: 140.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return GradientCard(
                  height: 140.h,
                  width: 140.w,
                  colors: [
                    AppColors.mildOrange.withValues(alpha: 0.21),
                    AppColors.primaryOrange,
                  ],
                  borderRadius: 16.r,
                  iconAsset: Assets.svgIcTunes,
                  iconSize: 80.r,
                  title: "",
                  margin: 10.w,
                );
              },
            ),
            // Positioned(
            //   bottom: 8,
            //   right: 8,
            //   child: Container(
            //     padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            //     decoration: BoxDecoration(
            //       color: Colors.black.withOpacity(0.6),
            //       borderRadius: BorderRadius.circular(12.r),
            //     ),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         const Icon(Icons.edit, size: 14, color: Colors.white),
            //         SizedBox(width: 4.w),
            //         Texts(
            //           S.of(context).changeCover,
            //           fontSize: 10.sp,
            //           color: Colors.white,
            //           fontFamily: AppFonts.inter,
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleChangeCover() async {
    if (widget.song.id == null) {
      _showSnack('No song selected', isError: true);
      return;
    }

    final action = await _showChangeCoverSelectionSheet();
    if (!mounted || action == null) return;

    if (action == _ChangeCoverAction.localGallery) {
      await _handleLocalGalleryCover();
    } else if (action == _ChangeCoverAction.searchOnline) {
      _showSnack('Search online feature coming soon');
    }
  }

  Future<_ChangeCoverAction?> _showChangeCoverSelectionSheet() {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding =
        viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    return showModalBottomSheet<_ChangeCoverAction>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: bottomPadding),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 18.h),
                Center(
                  child: Texts(
                    S.of(context).changeCover,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                ),
                SizedBox(height: 24.h),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 21.w,
                    height: 21.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: const Icon(Icons.photo_library_outlined, size: 16),
                  ),
                  title: Texts(
                    'Local gallery',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  onTap: () => Navigator.pop(sheetContext, _ChangeCoverAction.localGallery),
                ),
                Divider(color: Colors.black.withOpacity(0.08), height: 12.h, thickness: 0.8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 23.w,
                    height: 23.w,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: const Icon(Icons.search, size: 16),
                  ),
                  title: Texts(
                    'Search online',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  onTap: () => Navigator.pop(sheetContext, _ChangeCoverAction.searchOnline),
                ),
                SizedBox(height: 24.h),
                GestureDetector(
                  onTap: () => Navigator.pop(sheetContext),
                  child: Container(
                    alignment: Alignment.center,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Texts(
                      'Close',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: AppFonts.inter,
                      color: AppColors.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLocalGalleryCover() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      Uint8List? bytes = file.bytes;

      if (bytes == null && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) {
        _showSnack('Unable to read selected image', isError: true);
        return;
      }

      final croppedBytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (_) => ImageCropScreen(imageBytes: bytes!),
          fullscreenDialog: true,
        ),
      );

      if (croppedBytes == null) {
        return;
      }

      final optimizedBytes = await _optimizeImage(croppedBytes);
      final savedFile = await _persistCustomArtwork(optimizedBytes);
      await _cleanupPreviousCustomArtwork();
      await _updateSongArtworkPath(savedFile.path);

      if (!mounted) return;

      _showSnack('Cover updated successfully');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to update cover: $e', isError: true);
    }
  }

  Future<Uint8List> _optimizeImage(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Unsupported image format');
    }

    const maxDimension = 720;
    img.Image processed = decoded;
    final largestSide = decoded.width > decoded.height ? decoded.width : decoded.height;

    if (largestSide > maxDimension) {
      if (decoded.width >= decoded.height) {
        processed = img.copyResize(
          decoded,
          width: maxDimension,
          height: (decoded.height * maxDimension / decoded.width).round(),
        );
      } else {
        processed = img.copyResize(
          decoded,
          height: maxDimension,
          width: (decoded.width * maxDimension / decoded.height).round(),
        );
      }
    }

    final optimizedBytes = img.encodeJpg(processed, quality: 85);

    return Uint8List.fromList(optimizedBytes);
  }

  Future<File> _persistCustomArtwork(Uint8List bytes) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(documentsDir.path, 'covers'));

    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    final fileName =
        'cover_${widget.song.id ?? DateTime.now().millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = p.join(coversDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _cleanupPreviousCustomArtwork() async {
    final existingPath = _artworkPath;
    if (existingPath == null || existingPath.isEmpty) {
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final coversDirPath = p.join(documentsDir.path, 'covers');
      if (p.isWithin(coversDirPath, existingPath)) {
        final existingFile = File(existingPath);
        if (await existingFile.exists()) {
          await existingFile.delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to remove previous custom cover: $e');
    }
  }

  Future<void> _updateSongArtworkPath(String newPath) async {
    if (widget.song.id == null) {
      return;
    }

    context.read<SongsBloc>().add(
          SongsEvent.updateSongArtwork(
            songId: widget.song.id!,
            artworkPath: newPath,
          ),
        );

    setState(() {
      _artworkPath = newPath;
    });
  }
}

enum _ChangeCoverAction { localGallery, searchOnline }
