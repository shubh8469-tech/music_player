import 'dart:developer';
import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import '../../core/di/injection.dart';
import '../../core/services/app_state_service.dart';
import '../../features/songs/data/models/song_model.dart';
import '../../features/songs/domain/usecases/add_song.dart';
import '../../features/folders/domain/entities/folder.dart';
import '../../features/folders/domain/usecases/add_folder.dart';
import '../../features/folders/domain/usecases/add_song_to_folder.dart';
import '../../features/artists/domain/entities/artist.dart';
import '../../features/artists/domain/usecases/add_artist.dart';
import '../../features/artists/domain/usecases/add_song_to_artist.dart';
import '../../features/albums/domain/entities/album.dart';
import '../../features/albums/domain/usecases/add_album.dart';
import '../../features/albums/domain/usecases/add_song_to_album.dart';
import '../../features/folders/domain/repositories/folder_repository.dart';
import '../../features/artists/domain/repositories/artist_repository.dart';
import '../../features/albums/domain/repositories/album_repository.dart';
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

  // Track if sync was successful
  bool _syncSuccessful = false;

  Future<void> scanMusicFiles() async {
    try {
      final AddSong addSongUseCase = locator();
      final AddFolder addFolderUseCase = locator();
      final AddSongToFolder addSongToFolderUseCase = locator();
      final AddArtist addArtistUseCase = locator();
      final AddSongToArtist addSongToArtistUseCase = locator();
      final AddAlbum addAlbumUseCase = locator();
      final AddSongToAlbum addSongToAlbumUseCase = locator();
      final FolderRepository folderRepository = locator();
      final ArtistRepository artistRepository = locator();
      final AlbumRepository albumRepository = locator();

      // Clear existing data before sync
      await folderRepository.clearAllFolders();
      await artistRepository.clearAllArtists();
      await albumRepository.clearAllAlbums();

      List<SongModel> songs = await _audioQuery.querySongs();

      scannedFiles.clear();
      groupedByFolder.clear();

      // Track unique folders, artists, and albums
      Map<String, int> folderIds = {};
      Map<String, int> artistIds = {};
      Map<String, int> albumIds = {};

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

        if ((song.duration ?? 0) >= 1000) {
          // Try to extract year from song metadata
          int? songYear;

          // FIRST PRIORITY: Try to read year from audio file metadata (ID3 tags, etc.)
          // This only works for regular file paths (not content:// URIs)
          if (!path.startsWith('content://')) {
            try {
              final file = File(path);
              if (await file.exists()) {
                final metadata = await MetadataRetriever.fromFile(file);

                if (metadata.year != null) {
                  final yearValue = metadata.year!;

                  // Validate year is in reasonable range
                  if (yearValue > 1900 &&
                      yearValue <= DateTime.now().year + 1) {
                    songYear = yearValue;
                    log(
                      '✅ Year from audio metadata for ${song.title}: $songYear',
                    );
                  }
                }
              }
            } catch (e) {
              log('Failed to read audio metadata for ${song.title}: $e');
            }
          }

          // SECOND PRIORITY: Check dateAdded from media store
          if (songYear == null) {
            try {
              if (song.dateAdded != null && song.dateAdded! > 0) {
                songYear =
                    DateTime.fromMillisecondsSinceEpoch(
                      song.dateAdded! * 1000,
                    ).year;
                log('Year from dateAdded for ${song.title}: $songYear');
              }
            } catch (e) {
              log(
                'Failed to extract year from dateAdded for ${song.title}: $e',
              );
            }
          }

          // LAST RESORT: Use file's last modified date
          if (songYear == null && !path.startsWith('content://')) {
            try {
              final file = File(path);
              if (await file.exists()) {
                final lastModified = await file.lastModified();
                songYear = lastModified.year;
                log('Year from file modification for ${song.title}: $songYear');
              }
            } catch (e) {
              log(
                'Failed to extract year from file system for ${song.title}: $e',
              );
            }
          }

          final model = SongsModel(
            id: song.id,
            title: song.title,
            artist: song.artist ?? '',
            album: song.album ?? '',
            genre: song.genre ?? '',
            year: songYear,
            duration: song.duration ?? 0,
            filePath: path,
            folder: folderName,
            artwork_path: artworkPath,
          );

          await addSongUseCase(model);

          // Add to Folder
          if (folderName.isNotEmpty) {
            int folderId;
            if (folderIds.containsKey(folderName)) {
              folderId = folderIds[folderName]!;
            } else {
              final existingFolder = await folderRepository.getFolderByName(
                folderName,
              );
              if (existingFolder != null) {
                folderId = existingFolder.id!;
              } else {
                final folder = Folder(
                  id: null,
                  name: folderName,
                  path: folderPath,
                  songCount: 0,
                  artworkPath: artworkPath.isNotEmpty ? artworkPath : null,
                  createdTime: DateTime.now(),
                  updatedTime: DateTime.now(),
                );
                folderId = await addFolderUseCase(folder);
              }
              folderIds[folderName] = folderId;
            }
            await addSongToFolderUseCase(folderId, song.id);
          }

          // Add to Artist
          final artistName = song.artist ?? 'Unknown Artist';
          if (artistName.isNotEmpty) {
            int artistId;
            if (artistIds.containsKey(artistName)) {
              artistId = artistIds[artistName]!;
            } else {
              final existingArtist = await artistRepository.getArtistByName(
                artistName,
              );
              if (existingArtist != null) {
                artistId = existingArtist.id!;
              } else {
                final artist = Artist(
                  id: null,
                  name: artistName,
                  songCount: 0,
                  albumCount: 0,
                  artworkPath: artworkPath.isNotEmpty ? artworkPath : null,
                  createdTime: DateTime.now(),
                  updatedTime: DateTime.now(),
                );
                artistId = await addArtistUseCase(artist);
              }
              artistIds[artistName] = artistId;
            }
            await addSongToArtistUseCase(artistId, song.id);
          }

          // Add to Album
          final albumName = song.album ?? 'Unknown Album';
          if (albumName.isNotEmpty) {
            final albumKey = '$albumName|${song.artist ?? ""}';
            int albumId;
            if (albumIds.containsKey(albumKey)) {
              albumId = albumIds[albumKey]!;
            } else {
              final existingAlbum = await albumRepository
                  .getAlbumByNameAndArtist(albumName, song.artist);
              if (existingAlbum != null) {
                albumId = existingAlbum.id!;
              } else {
                final album = Album(
                  id: null,
                  name: albumName,
                  artist: song.artist,
                  songCount: 0,
                  year: songYear,
                  artworkPath: artworkPath.isNotEmpty ? artworkPath : null,
                  createdTime: DateTime.now(),
                  updatedTime: DateTime.now(),
                );
                albumId = await addAlbumUseCase(album);
              }
              albumIds[albumKey] = albumId;
            }
            await addSongToAlbumUseCase(albumId, song.id);
          }

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

      // Update album counts for artists
      for (final entry in artistIds.entries) {
        final albums = await albumRepository.getAlbumsByArtist(entry.key);
        await artistRepository.updateArtistAlbumCount(
          entry.value,
          albums.length,
        );
      }

      // Debug output
      debugPrint("Found $scannedFiles");
      debugPrint("Found ${scannedFiles.length} songs");
      debugPrint("Found ${groupedByFolder.length} folders");

      // Mark sync as successful
      _syncSuccessful = true;
    } catch (e) {
      // Log error but don't mark sync as successful
      log('Error during sync: $e');
      _syncSuccessful = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // total time to reach 100%
    )..forward(); // start animation

    scanMusicFiles();

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        // Only save sync completed state if sync was successful
        if (_syncSuccessful) {
          final appStateService = locator<AppStateService>();
          await appStateService.setSyncCompleted(true);
        }

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
