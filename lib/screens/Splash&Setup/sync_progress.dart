import 'dart:developer';
import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import '../../core/di/injection.dart';
import '../../features/songs/data/models/song_model.dart';
import '../../features/songs/domain/usecases/add_song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/themes/color.dart';
import '../../commonWidgets/textWidget.dart';
import '../../generated/assets.dart';
import '../../l10n/l10n.dart';
import '../../themes/font.dart';

class SyncProgress extends StatefulWidget {
  const SyncProgress({super.key});

  @override
  _SyncProgressState createState() => _SyncProgressState();
}

class _SyncProgressState extends State<SyncProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final OnAudioQuery _audioQuery = OnAudioQuery();

  // All scanned files
  List<Map<String, String>> scannedFiles = [];

  // Grouped by folder
  final Map<String, List<Map<String, String>>> groupedByFolder = {};

  Future<void> scanMusicFiles() async {

    final AddSong addSongUseCase = locator();

    List<SongModel> songs = await _audioQuery.querySongs();

    scannedFiles.clear();
    groupedByFolder.clear();

    for (final song in songs) {
      final String path = song.data;

      final artworkBytes = await _audioQuery.queryArtwork(
        song.id,
        ArtworkType.AUDIO, // or ArtworkType.ALBUM
      );

      final appDocDir = await getApplicationDocumentsDirectory();
      final artworkDir = Directory(p.join(appDocDir.path, 'artworks'));
      if (!await artworkDir.exists()) {
        await artworkDir.create();
      }

      String folderPath = '';
      String folderName = '';

      try {
        if (path.startsWith('content://')) {
          final uri = Uri.parse(path);
          if (uri.pathSegments.length >= 2) {
            folderPath = uri.pathSegments
                .sublist(0, uri.pathSegments.length - 1)
                .join('/');
            folderName = uri.pathSegments[uri.pathSegments.length - 2];
          } else {
            final idx = path.lastIndexOf('/');
            folderName = idx >= 0 ? path.substring(idx + 1) : path;
            folderPath = path;
          }
        } else {
          folderPath = p.dirname(path);
          folderName = p.basename(folderPath);
        }
      } catch (e) {
        folderPath = '';
        folderName = '';
      }

      String artworkPath = '';
      if (artworkBytes != null && artworkBytes.isNotEmpty) {
        // 🔹 Save original bytes directly (no resizing)
        final file = File(p.join(artworkDir.path, '${song.id}.jpg'));
        await file.writeAsBytes(artworkBytes);
        artworkPath = file.path;
      }

      log('songs duration: ${song.duration} ${song.title}');

      if((song.duration ?? 0) >= 1000) {

        final model = SongsModel(
            id: song.id,
            title: song.title,
            artist: song.artist ?? '',
            album: song.album ?? '',
            genre: song.genre ?? '',
            duration: song.duration ?? 0,
            filePath: path,
            folder: folderName,
            artwork_path: artworkPath
        );

        await addSongUseCase(model);

        final item = {
          'title': song.title,
          'path': path,
          'folderPath': folderPath,
          'folderName': folderName,
        };

        scannedFiles.add(item);
        groupedByFolder.putIfAbsent(folderPath, () => []).add(item);
      }
    }

    // Debug output
    debugPrint("Found $scannedFiles");
    debugPrint("Found ${scannedFiles.length} songs");
    debugPrint("Found ${groupedByFolder.length} folders");
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // total time to reach 100%
    )..forward(); // start animation

    scanMusicFiles();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) context.go('/dashboard');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(Assets.pngLogo, height: 113.h, width: 113.w),
                  SizedBox(height: 16.h),
                  Texts(
                    S.of(context).musicPlayer,
                    fontSize: 24.sp,
                    fontFamily: AppFonts.manrope,
                    fontWeight: AppFontWeights.semiBold,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0, // 👈 add this to stretch horizontally
              bottom: 100,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 40.w,
                      vertical: 10.h,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Texts(
                              "Scanning files...",
                              fontSize: 14.sp,
                              fontFamily: AppFonts.manrope,
                              fontWeight: AppFontWeights.semiBold,
                              color: Colors.black87,
                            ),
                            Spacer(),
                            Texts(
                              "${(_controller.value * 100).toStringAsFixed(0)}%",
                              fontSize: 14.sp,
                              fontFamily: AppFonts.manrope,
                              fontWeight: AppFontWeights.semiBold,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _controller.value,
                            minHeight: 10.h,
                            backgroundColor: AppColors.mediumDarkGrey,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
