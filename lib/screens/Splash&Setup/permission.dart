import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../../commonWidgets/buton.dart';
import '../../commonWidgets/textWidget.dart';
import '../../core/di/injection.dart';
import '../../features/songs/data/models/song_model.dart';
import '../../features/songs/domain/usecases/add_song.dart';
import '../../generated/assets.dart';
import '../../themes/color.dart';
import '../../themes/font.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  // All scanned files
  List<Map<String, String>> scannedFiles = [];

  // Grouped by folder
  final Map<String, List<Map<String, String>>> groupedByFolder = {};

  Future<void> scanMusicFiles() async {

    final AddSong addSongUseCase = locator();

    if (Platform.isAndroid) {
      PermissionStatus status;
      if (await Permission.storage.isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.audio.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      }

      if (!status.isGranted) {
        openAppSettings();
        return;
      }
    }

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

    // Debug output
    debugPrint("Found $scannedFiles");
    debugPrint("Found ${scannedFiles.length} songs");
    debugPrint("Found ${groupedByFolder.length} folders");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.17),
            Image.asset(
              Assets.pngMusicDirectory,
              height: 74.h,
              width: 64.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 25.h),
            Texts(
              'Permission Required',
              fontFamily: AppFonts.manrope,
              fontWeight: AppFontWeights.bold,
              fontSize: 20.sp,
            ),
            SizedBox(height: 17.h),
            Texts(
              'To play your songs, we need permission to access music files stored on your device.',
              fontFamily: AppFonts.inter,
              fontWeight: AppFontWeights.regular,
              fontSize: 14.sp,
            ),
            SizedBox(height: 25.h),
            Texts(
              'This allows the app to:',
              fontFamily: AppFonts.inter,
              fontWeight: AppFontWeights.semiBold,
              fontSize: 16.sp,
            ),
            SizedBox(height: 20.h),
            Column(
              children: [
                Row(
                  children: [
                    checkIconWidget(),
                    SizedBox(width: 5.w),
                    Texts(
                      'Detect and list your offline music files',
                      fontFamily: AppFonts.inter,
                      fontWeight: AppFontWeights.regular,
                      fontSize: 14.sp,
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    checkIconWidget(),
                    SizedBox(width: 5.w),
                    Texts(
                      'Play songs stored on your device',
                      fontFamily: AppFonts.inter,
                      fontWeight: AppFontWeights.regular,
                      fontSize: 14.sp,
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    checkIconWidget(),
                    SizedBox(width: 5.w),
                    Texts(
                      'Keep your playlists organized automatically',
                      fontFamily: AppFonts.inter,
                      fontWeight: AppFontWeights.regular,
                      fontSize: 14.sp,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 45.h),
            Center(
              child: OvalButton(
                text: "Open Settings",
                onPressed: () async {
                  await scanMusicFiles(); // 🔹 Scan in background
                  context.go('/sync'); // 🔹 Navigate as before
                },
                backgroundColor: AppColors.primaryOrange,
                textColor: AppColors.white,
                borderRadius: 50.r,
                height: 48.h,
                width: 343.w,
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget checkIconWidget() => Icon(
    Icons.check_circle_outline,
    color: AppColors.primaryOrange,
    size: 20.sp,
  );
}
