import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/features/albums/presentation/bloc/album_bloc.dart';
import 'package:music_app/features/albums/domain/entities/album.dart';
import 'package:music_app/themes/font.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:music_app/core/widgets/app_bar_with_icon_title.dart';
import 'package:music_app/core/widgets/gradientCard.dart';
import 'package:music_app/core/widgets/text_field_widget.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/core/screens/common/image_crop_screen.dart';
import 'package:music_app/core/utils/snack_bar.dart';

class EditAlbumTagsScreen extends StatefulWidget {
  final Album album;

  const EditAlbumTagsScreen({
    super.key,
    required this.album,
  });

  @override
  State<EditAlbumTagsScreen> createState() => _EditAlbumTagsScreenState();
}

class _EditAlbumTagsScreenState extends State<EditAlbumTagsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController albumTitleController = TextEditingController();
  final FocusNode albumTitleFocusNode = FocusNode();

  bool _isSaving = false;
  bool _hasChanges = false;
  String? _artworkPath;

  @override
  void initState() {
    super.initState();
    albumTitleController.text = widget.album.name;
    _artworkPath = widget.album.artworkPath;
    albumTitleController.addListener(_onValueChanged);
  }

  @override
  void dispose() {
    albumTitleController
      ..removeListener(_onValueChanged)
      ..dispose();
    albumTitleFocusNode.dispose();
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

    final trimmedTitle = albumTitleController.text.trim();

    if (trimmedTitle.isEmpty) {
      _showSnack('Album title cannot be empty', isError: true);
      return;
    }

    if (!_hasChanges && trimmedTitle == widget.album.name) {
      _showSnack('No changes to save');
      return;
    }

    if (widget.album.id == null) {
      _showSnack('Invalid album', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Update album name
    if (trimmedTitle != widget.album.name) {
      context.read<AlbumBloc>().add(
            AlbumEvent.updateAlbumName(
              widget.album.id!,
              trimmedTitle,
            ),
          );
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    showSnackBar(
      context,
      () {},
      message: message,
      backgroundColor: isError ? Colors.red : AppColors.primaryOrange,
      alertBannerLocation: AlertBannerLocation.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AlbumBloc, AlbumState>(
      listenWhen: (_, __) => _isSaving,
      listener: (context, state) {
        state.maybeWhen(
          loaded: (_, __) {
            if (!_isSaving) return;
            setState(() {
              _isSaving = false;
            });
            Navigator.pop(context, true);
            _showSnack('Album updated successfully');
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
        appBar: AppBarWithIconTitle(title: S.of(context).editTags),
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
                        _buildAlbumTitleField(),
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

  Widget _buildAlbumTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texts(
          S.of(context).albumTitle,
          fontSize: 14.sp,
          color: AppColors.textColor,
          fontWeight: FontWeight.w400,
          fontFamily: AppFonts.inter,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0, top: 10),
          child: TextFieldWidget(
            controller: albumTitleController,
            fillColor: AppColors.textColor.withValues(alpha: .14),
            wantListeners: true,
            cursorColor: AppColors.textColor,
            textStyleColor: AppColors.textColor,
            textInputAction: TextInputAction.done,
            focusNode: albumTitleFocusNode,
            hasFocus: albumTitleFocusNode.hasFocus,
            onFieldSubmitted: (_) => _handleSave(),
            onTextChanged: (_) => _onValueChanged(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Album title cannot be empty';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCoverPreview() {
    final path = _artworkPath;
    final hasArtwork = path != null &&
        path.isNotEmpty &&
        File(path).existsSync();

    if (!hasArtwork) {
      return GradientCard(
        height: 140.h,
        width: 140.w,
        colors: [
          AppColors.mildOrange.withValues(alpha: 0.21),
          AppColors.primaryOrange,
        ],
        borderRadius: 16.r,
        iconAsset: Assets.svgAlbum,
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
                  iconAsset: Assets.svgAlbum,
                  iconSize: 80.r,
                  title: "",
                  margin: 10.w,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleChangeCover() async {
    if (widget.album.id == null) {
      _showSnack('No album selected', isError: true);
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
      final savedFile = await _persistAlbumCoverFile(optimizedBytes);
      await _cleanupPreviousAlbumCover();
      await _updateAlbumCoverPath(savedFile.path);

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

  Future<File> _persistAlbumCoverFile(Uint8List bytes) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(documentsDir.path, 'covers', 'albums'));

    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'album_${widget.album.id}_$timestamp.jpg';
    final filePath = p.join(coversDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _cleanupPreviousAlbumCover() async {
    final existingPath = _artworkPath;
    if (existingPath == null || existingPath.isEmpty) {
      return;
    }

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final coversDirPath = p.join(documentsDir.path, 'covers', 'albums');
      if (p.isWithin(coversDirPath, existingPath)) {
        final existingFile = File(existingPath);
        if (await existingFile.exists()) {
          await existingFile.delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to remove previous album cover: $e');
    }
  }

  Future<void> _updateAlbumCoverPath(String newPath) async {
    if (widget.album.id == null) {
      return;
    }

    context.read<AlbumBloc>().add(
          AlbumEvent.updateAlbumCover(
            widget.album.id!,
            newPath,
          ),
        );

    setState(() {
      _artworkPath = newPath;
    });
  }
}

enum _ChangeCoverAction { localGallery, searchOnline }

