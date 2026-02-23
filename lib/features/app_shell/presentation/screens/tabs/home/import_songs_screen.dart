import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:music_app/core/widgets/MusicListTile.dart';
import 'package:music_app/core/widgets/app_bar_with_icon_title.dart';
import 'package:music_app/core/widgets/buton.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/core/services/import_songs_service.dart';
import 'package:music_app/features/playlists/presentation/bloc/playlist_bloc.dart';
import 'package:music_app/features/songs/presentation/bloc/songs_bloc.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

class ImportSongsScreen extends StatefulWidget {
  const ImportSongsScreen({super.key});

  @override
  State<ImportSongsScreen> createState() => _ImportSongsScreenState();
}

// Class to hold file preview information
class FilePreview {
  final PlatformFile file;
  final String title;
  final String subtitle;
  final String? artworkPath;

  FilePreview({
    required this.file,
    required this.title,
    required this.subtitle,
    this.artworkPath,
  });
}

class _ImportSongsScreenState extends State<ImportSongsScreen> {
  final ImportSongsService _importService = ImportSongsService();

  bool _isImporting = false;
  bool _importComplete = false;
  int _currentProgress = 0;
  int _totalFiles = 0;
  int _successCount = 0;
  int _failedCount = 0;
  int _skippedCount = 0;
  List<String> _failedFiles = [];
  List<String> _skippedFiles = [];
  List<PlatformFile>? _selectedFiles;
  List<FilePreview>? _filePreviews;
  bool _isLoadingPreviews = false;

  Future<void> _pickFiles() async {
    final files = await _importService.pickAudioFiles();
    if (files != null && files.isNotEmpty) {
      setState(() {
        _selectedFiles = files;
        _importComplete = false;
        _isLoadingPreviews = true;
      });

      // Extract metadata for preview
      await _extractFilePreviews(files);
    }
  }

  Future<void> _extractFilePreviews(List<PlatformFile> files) async {
    List<FilePreview> previews = [];
    final appDocDir = await getApplicationDocumentsDirectory();
    final tempArtworkDir = Directory(p.join(appDocDir.path, 'temp_artworks'));

    // Create temp artwork directory if it doesn't exist
    if (!await tempArtworkDir.exists()) {
      await tempArtworkDir.create(recursive: true);
    }

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      String title = p.basenameWithoutExtension(file.name);
      String subtitle = _formatBytes(file.size);
      String? artworkPath;

      try {
        if (file.path != null) {
          final sourceFile = File(file.path!);
          if (await sourceFile.exists()) {
            // Extract metadata
            final metadata = await MetadataGod.readMetadata(file: file.path!);

            // Get title and artist
            if (metadata.title != null && metadata.title!.isNotEmpty) {
              title = metadata.title!;
            }

            String artist = 'Unknown Artist';
            if (metadata.artist != null && metadata.artist!.isNotEmpty) {
              artist = metadata.artist!;
            }
            subtitle = artist;

            // Extract artwork
            if (metadata.picture != null && metadata.picture!.data.isNotEmpty) {
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final artworkFile = File(
                p.join(tempArtworkDir.path, 'preview_${timestamp}_$i.jpg'),
              );
              await artworkFile.writeAsBytes(metadata.picture!.data);
              artworkPath = artworkFile.path;
            }
          }
        }
      } catch (e) {
        // If metadata extraction fails, use file name
        subtitle = _formatBytes(file.size);
      }

      previews.add(
        FilePreview(
          file: file,
          title: title,
          subtitle: subtitle,
          artworkPath: artworkPath,
        ),
      );
    }

    setState(() {
      _filePreviews = previews;
      _isLoadingPreviews = false;
    });
  }

  Future<void> _cleanupTempArtworks() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final tempArtworkDir = Directory(p.join(appDocDir.path, 'temp_artworks'));

      if (await tempArtworkDir.exists()) {
        await tempArtworkDir.delete(recursive: true);
      }
    } catch (e) {
      // Silently fail - cleanup is not critical
    }
  }

  Future<void> _startImport() async {
    if (_selectedFiles == null || _selectedFiles!.isEmpty) return;

    setState(() {
      _isImporting = true;
      _currentProgress = 0;
      _totalFiles = _selectedFiles!.length;
      _importComplete = false;
    });

    final result = await _importService.importFiles(
      _selectedFiles!,
      onProgress: (current, total) {
        setState(() {
          _currentProgress = current;
          _totalFiles = total;
        });
      },
    );

    setState(() {
      _isImporting = false;
      _importComplete = true;
      _successCount = result['success'] ?? 0;
      _failedCount = result['failed'] ?? 0;
      _skippedCount = result['skipped'] ?? 0;
      _failedFiles = List<String>.from(result['failedFiles'] ?? []);
      _skippedFiles = List<String>.from(result['skippedFiles'] ?? []);
    });

    // Clean up temp artwork files after import
    await _cleanupTempArtworks();

    // Refresh the songs list and playlists after successful import
    if (_successCount > 0 && mounted) {
      context.read<SongsBloc>().add(const SongsEvent.getAllSongs());
      context.read<PlaylistBloc>().add(const PlaylistEvent.fetchAllPlaylists());
    }
  }

  @override
  void dispose() {
    // Clean up temp artworks when widget is disposed
    _cleanupTempArtworks();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: 'Import Music',
        backgroundColor: AppColors.white,
        titleColor: Colors.black,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        showBackButton: false,
        elevation: 0,
      ),
      body: Padding(padding: EdgeInsets.all(16.0.r), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_importComplete) {
      return _buildCompleteView();
    } else if (_isImporting) {
      return _buildImportingView();
    } else if (_selectedFiles != null && _selectedFiles!.isNotEmpty) {
      return _buildSelectedFilesView();
    } else {
      return _buildInitialView();
    }
  }

  Widget _buildInitialView() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              Assets.pngMusicDirectory,
              height: 100.h,
              width: 100.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 30.h),
            Texts(
              'Import Your Music',
              fontFamily: AppFonts.manrope,
              fontWeight: AppFontWeights.bold,
              fontSize: 24.sp,
            ),
            SizedBox(height: 16.h),
            Texts(
              'Browse and select audio files from your device to add them to your library',
              fontFamily: AppFonts.inter,
              fontWeight: AppFontWeights.regular,
              fontSize: 14.sp,
              color: Colors.grey[600] ?? Colors.grey,
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.blue[200] ?? Colors.blue,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Texts(
                        'How to import music:',
                        fontFamily: AppFonts.inter,
                        fontWeight: AppFontWeights.semiBold,
                        fontSize: 14.sp,
                        color: Colors.blue[900] ?? Colors.blue,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildInfoStep('1', 'Tap "Browse Files" below'),
                  SizedBox(height: 8.h),
                  _buildInfoStep(
                    '2',
                    'Navigate to your music files (Downloads, iCloud Drive, etc.)',
                  ),
                  SizedBox(height: 8.h),
                  _buildInfoStep('3', 'Select one or multiple audio files'),
                  SizedBox(height: 8.h),
                  _buildInfoStep(
                    '4',
                    'Tap "Import" to add them to your library',
                  ),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            OvalButton(
              text: "Browse Files",
              onPressed: _pickFiles,
              backgroundColor: AppColors.primaryOrange,
              textColor: AppColors.white,
              borderRadius: 50.r,
              height: 50.h,
              width: 220.w,
              icon: Icons.folder_open,
            ),
            SizedBox(height: 16.h),
            Texts(
              'Supported formats: MP3, M4A, WAV, AAC, FLAC',
              fontFamily: AppFonts.inter,
              fontWeight: AppFontWeights.regular,
              fontSize: 12.sp,
              color: Colors.grey[500] ?? Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Texts(
              number,
              fontFamily: AppFonts.inter,
              fontWeight: AppFontWeights.bold,
              fontSize: 11.sp,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Texts(
            text,
            fontFamily: AppFonts.inter,
            fontWeight: AppFontWeights.regular,
            fontSize: 13.sp,
            color: Colors.blue[900] ?? Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedFilesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Texts(
          'Selected Files (${_selectedFiles!.length})',
          fontFamily: AppFonts.manrope,
          fontWeight: AppFontWeights.bold,
          fontSize: 18.sp,
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: _isLoadingPreviews
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryOrange),
                      SizedBox(height: 16.h),
                      Texts(
                        'Loading file previews...',
                        fontFamily: AppFonts.inter,
                        fontSize: 14.sp,
                        color: Colors.grey[600] ?? Colors.grey,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filePreviews?.length ?? _selectedFiles!.length,
                  itemBuilder: (context, index) {
                    final preview = _filePreviews?[index];
                    final file = _selectedFiles![index];

                    // If preview is available, use it; otherwise show basic info
                    final title =
                        preview?.title ?? p.basenameWithoutExtension(file.name);
                    final subtitle =
                        preview?.subtitle ?? _formatBytes(file.size);
                    final artworkPath = preview?.artworkPath;

                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: MusicListTile(
                        margin: 0,
                        height: 70.h,
                        borderRadius: 10.r,
                        backgroundColor: AppColors.musicTileBackgroundColor,
                        cardHeight: 50.h,
                        cardWidth: 50.h,
                        cardRadius: 7.r,
                        cardIconAsset: artworkPath ?? Assets.svgMusicIcon,
                        cardIconSize: artworkPath != null ? 50.r : 28.r,
                        isSvgCardIcon: artworkPath == null,
                        isSvgColorNeeded: artworkPath == null,
                        title: title,
                        titleSize: 15,
                        subtitle: subtitle,
                        subtitleSize: 12,
                        trailingIconAsset: Assets.svgMusicIcon,
                        trailingIconHeight: 24.h,
                        trailingIconWidth: 24.w,
                        trailingMargin: 2.w,
                        onTap: () {
                          // Optional: show file details
                        },
                      ),
                    );
                  },
                ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: OvalButton(
                text: "Cancel",
                onPressed: () async {
                  await _cleanupTempArtworks();
                  setState(() {
                    _selectedFiles = null;
                    _filePreviews = null;
                  });
                },
                backgroundColor: Colors.grey[300]!,
                textColor: Colors.black87,
                borderRadius: 50.r,
                height: 48.h,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: OvalButton(
                text: "Import",
                onPressed: _startImport,
                backgroundColor: AppColors.primaryOrange,
                textColor: AppColors.white,
                borderRadius: 50.r,
                height: 48.h,
                icon: Icons.download,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImportingView() {
    final progress = _totalFiles > 0 ? _currentProgress / _totalFiles : 0.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 100.h,
            width: 100.w,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: AppColors.mediumDarkGrey,
              color: AppColors.primaryOrange,
            ),
          ),
          SizedBox(height: 30.h),
          Texts(
            'Importing...',
            fontFamily: AppFonts.manrope,
            fontWeight: AppFontWeights.bold,
            fontSize: 20.sp,
          ),
          SizedBox(height: 8.h),
          Texts(
            'Extracting metadata & artwork',
            fontFamily: AppFonts.inter,
            fontWeight: AppFontWeights.regular,
            fontSize: 14.sp,
            color: Colors.grey[500] ?? Colors.grey,
          ),
          SizedBox(height: 16.h),
          Texts(
            '$_currentProgress of $_totalFiles files',
            fontFamily: AppFonts.inter,
            fontWeight: AppFontWeights.regular,
            fontSize: 16.sp,
            color: Colors.grey[600] ?? Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteView() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _failedCount == 0 ? Icons.check_circle : Icons.warning,
              color: _failedCount == 0 ? Colors.green : Colors.orange,
              size: 100.r,
            ),
            SizedBox(height: 30.h),
            Texts(
              'Import Complete!',
              fontFamily: AppFonts.manrope,
              fontWeight: AppFontWeights.bold,
              fontSize: 24.sp,
            ),
            SizedBox(height: 16.h),
            Texts(
              'Successfully imported $_successCount file${_successCount != 1 ? 's' : ''}',
              fontFamily: AppFonts.inter,
              fontWeight: AppFontWeights.regular,
              fontSize: 16.sp,
              color: Colors.grey[600] ?? Colors.grey,
            ),
            if (_skippedCount > 0) ...[
              SizedBox(height: 8.h),
              Texts(
                'Skipped $_skippedCount duplicate${_skippedCount != 1 ? 's' : ''}',
                fontFamily: AppFonts.inter,
                fontWeight: AppFontWeights.regular,
                fontSize: 14.sp,
                color: Colors.blue[600] ?? Colors.blue,
              ),
            ],
            if (_failedCount > 0) ...[
              SizedBox(height: 8.h),
              Texts(
                'Failed to import $_failedCount file${_failedCount != 1 ? 's' : ''}',
                fontFamily: AppFonts.inter,
                fontWeight: AppFontWeights.regular,
                fontSize: 14.sp,
                color: Colors.red[600] ?? Colors.red,
              ),
              if (_failedFiles.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Texts(
                        'Failed files:',
                        fontFamily: AppFonts.inter,
                        fontWeight: AppFontWeights.semiBold,
                        fontSize: 14.sp,
                      ),
                      SizedBox(height: 8.h),
                      ..._failedFiles.map(
                        (file) => Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Texts(
                            '• $file',
                            fontFamily: AppFonts.inter,
                            fontWeight: AppFontWeights.regular,
                            fontSize: 12.sp,
                            color: Colors.grey[700] ?? Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            if (_skippedFiles.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 16.r,
                        ),
                        SizedBox(width: 8.w),
                        Texts(
                          'Already imported (skipped):',
                          fontFamily: AppFonts.inter,
                          fontWeight: AppFontWeights.semiBold,
                          fontSize: 14.sp,
                          color: Colors.blue[900] ?? Colors.blue,
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ..._skippedFiles
                        .take(5)
                        .map(
                          (file) => Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: Texts(
                              '• $file',
                              fontFamily: AppFonts.inter,
                              fontWeight: AppFontWeights.regular,
                              fontSize: 12.sp,
                              color: Colors.grey[700] ?? Colors.grey,
                            ),
                          ),
                        ),
                    if (_skippedFiles.length > 5)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Texts(
                          '... and ${_skippedFiles.length - 5} more',
                          fontFamily: AppFonts.inter,
                          fontWeight: AppFontWeights.regular,
                          fontSize: 12.sp,
                          color: Colors.grey[600] ?? Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 40.h),
            OvalButton(
              text: "Done",
              onPressed: () => context.pop(),
              backgroundColor: AppColors.primaryOrange,
              textColor: AppColors.white,
              borderRadius: 50.r,
              height: 48.h,
              width: 200.w,
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
