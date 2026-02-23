import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
// Note: metadata_god package available if needed for additional metadata extraction
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/core/services/app_state_service.dart';
import 'package:music_app/features/albums/presentation/bloc/album_bloc.dart';
import 'package:music_app/features/artists/presentation/bloc/artist_bloc.dart';
import 'package:music_app/features/folders/presentation/bloc/folder_bloc.dart';
import 'package:music_app/features/genres/presentation/bloc/genre_bloc.dart';
import 'package:music_app/features/songs/presentation/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/datasources/song_local_data_source.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/features/songs/domain/usecases/add_song.dart';
import 'package:music_app/features/folders/domain/entities/folder.dart';
import 'package:music_app/features/folders/domain/usecases/add_folder.dart';
import 'package:music_app/features/folders/domain/usecases/add_song_to_folder.dart';
import 'package:music_app/features/artists/domain/entities/artist.dart';
import 'package:music_app/features/artists/domain/usecases/add_artist.dart';
import 'package:music_app/features/artists/domain/usecases/add_song_to_artist.dart';
import 'package:music_app/features/albums/domain/entities/album.dart';
import 'package:music_app/features/albums/domain/usecases/add_album.dart';
import 'package:music_app/features/albums/domain/usecases/add_song_to_album.dart';
import 'package:music_app/features/genres/domain/entities/genre.dart';
import 'package:music_app/features/genres/domain/usecases/add_genre.dart';
import 'package:music_app/features/genres/domain/usecases/add_song_to_genre.dart';
import 'package:music_app/features/folders/domain/repositories/folder_repository.dart';
import 'package:music_app/features/artists/domain/repositories/artist_repository.dart';
import 'package:music_app/features/albums/domain/repositories/album_repository.dart';
import 'package:music_app/features/genres/domain/repositories/genre_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/core/utils/globals.dart';

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

  // Track scan start time
  DateTime? _scanStartTime;

  /// Check if a file path represents a video file

  Future<Uint8List?> _fetchBestArtwork(SongModel song) async {
    Future<Uint8List?> tryFetch(int? id, ArtworkType type) async {
      if (id == null) return null;
      try {
        final result = await _audioQuery.queryArtwork(id, type);
        if (result != null && result.isNotEmpty) {
          return result;
        }
      } catch (e) {
        log('Failed to fetch $type artwork for ${song.title}: $e');
      }
      return null;
    }

    Uint8List? bytes = await tryFetch(song.id, ArtworkType.AUDIO);

    if (bytes == null || bytes.isEmpty) {
      bytes = await tryFetch(song.albumId, ArtworkType.ALBUM);
    }

    if (bytes == null || bytes.isEmpty) {
      bytes = await tryFetch(song.artistId, ArtworkType.ARTIST);
    }

    return bytes;
  }

  /// Check if runtime permissions are actually granted
  Future<bool> _checkPermissions() async {
    if (Platform.isIOS) {
      return true; // iOS doesn't need explicit permission for media library
    }

    // Check actual runtime permission status
    final storageGranted = await Permission.storage.isGranted;
    final audioGranted = await Permission.audio.isGranted;

    if (storageGranted || audioGranted) {
      return true;
    }

    // If not granted, try to request
    PermissionStatus status;
    if (await Permission.storage.isGranted) {
      status = PermissionStatus.granted;
    } else {
      status = await Permission.audio.request();
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
    }

    return status.isGranted;
  }

  Future<void> scanMusicFiles() async {
    // Record scan start time
    _scanStartTime = DateTime.now();

    try {
      // Verify permissions before accessing library
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        log('Permission not granted, redirecting to permission screen');
        if (mounted) {
          // Reset permission flag since actual permission is not granted
          final appStateService = locator<AppStateService>();
          await appStateService.setPermissionGranted(false);
          context.go('/permission');
        }
        return;
      }

      final SongLocalDataSource localDataSource = locator();

      final AddSong addSongUseCase = locator();
      final AddFolder addFolderUseCase = locator();
      final AddSongToFolder addSongToFolderUseCase = locator();
      final AddArtist addArtistUseCase = locator();
      final AddSongToArtist addSongToArtistUseCase = locator();
      final AddAlbum addAlbumUseCase = locator();
      final AddSongToAlbum addSongToAlbumUseCase = locator();
      final AddGenre addGenreUseCase = locator();
      final AddSongToGenre addSongToGenreUseCase = locator();
      final FolderRepository folderRepository = locator();
      final ArtistRepository artistRepository = locator();
      final AlbumRepository albumRepository = locator();
      final GenreRepository genreRepository = locator();

      // Get songs from device
      List<SongModel> deviceSongs = await _audioQuery.querySongs();

      // Get songs from database
      List<SongsModel> dbSongs = await localDataSource.getAllSongs(
        includeHidden: true,
      );

      // Find new songs (in device but not in DB)
      Set<int> deviceSongIds = deviceSongs.map((s) => s.id).toSet();
      Set<int> dbSongIds = dbSongs
          .map((s) => s.id ?? -1)
          .where((id) => id != -1)
          .toSet();
      Set<int> newSongIds = deviceSongIds.difference(dbSongIds);

      // Find removed songs (in DB but not in device)
      Set<int> removedSongIds = dbSongIds.difference(deviceSongIds);

      log(
        'Incremental sync: ${newSongIds.length} new songs, ${removedSongIds.length} removed songs',
      );

      // Remove songs that are no longer on device
      for (int songId in removedSongIds) {
        await localDataSource.deleteSong(songId);
      }

      // Validate file existence for remaining songs
      final missingSongIds = await localDataSource
          .validateAndFindMissingFiles();
      for (int songId in missingSongIds) {
        await localDataSource.deleteSong(songId);
      }

      // Process new songs
      List<SongModel> songs = deviceSongs
          .where((s) => newSongIds.contains(s.id))
          .toList();

      scannedFiles.clear();
      groupedByFolder.clear();

      // Track unique folders, artists, albums, and genres
      Map<String, int> folderIds = {};
      Map<String, int> artistIds = {};
      Map<String, int> albumIds = {};
      Map<String, int> genreIds = {};
      final Set<int> touchedAlbumIds = {};

      for (final song in songs) {
        final String path = song.data;

        // Skip video files (MP4, AVI, etc.) that may have been incorrectly indexed as audio
        if (isVideoFile(path)) {
          log('Skipping video file: $path');
          continue;
        }

        final artworkBytes = await _fetchBestArtwork(song);

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
          // COMMENTED OUT: Not needed as on_audio_query provides year data
          // (metadata_god available if more detailed extraction needed in future)
          // if (!path.startsWith('content://')) {
          //   try {
          //     final file = File(path);
          //     if (await file.exists()) {
          //       final metadata = await MetadataRetriever.fromFile(file);
          //
          //       if (metadata.year != null) {
          //         final yearValue = metadata.year!;
          //
          //         // Validate year is in reasonable range
          //         if (yearValue > 1900 &&
          //             yearValue <= DateTime.now().year + 1) {
          //           songYear = yearValue;
          //           log(
          //             '✅ Year from audio metadata for ${song.title}: $songYear',
          //           );
          //         }
          //       }
          //     }
          //   } catch (e) {
          //     log('Failed to read audio metadata for ${song.title}: $e');
          //   }
          // }

          // FIRST PRIORITY (ACTIVE): Check dateAdded from media store
          try {
            final dateAdded = song.dateAdded ?? 0;
            if (dateAdded > 0) {
              final derivedYear = DateTime.fromMillisecondsSinceEpoch(
                dateAdded * 1000,
              ).year;
              songYear ??= derivedYear;
              log('Year from dateAdded for ${song.title}: $songYear');
            }
          } catch (e) {
            log('Failed to extract year from dateAdded for ${song.title}: $e');
          }

          // LAST RESORT: Use file's last modified date
          if (!path.startsWith('content://')) {
            try {
              final file = File(path);
              if (await file.exists()) {
                final hadYear = songYear != null;
                final lastModified = await file.lastModified();
                songYear ??= lastModified.year;
                if (!hadYear) {
                  log(
                    'Year from file modification for ${song.title}: $songYear',
                  );
                }
              }
            } catch (e) {
              log(
                'Failed to extract year from file system for ${song.title}: $e',
              );
            }
          }

          final model = SongsModel(
            id: song.id,
            title: song.title.trim(),
            artist: (song.artist ?? '').trim(),
            album: (song.album ?? '').trim(),
            genre: (song.genre ?? '').trim(),
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
          final artistName = (song.artist ?? 'Unknown Artist').trim();
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
          final albumName = (song.album ?? 'Unknown Album').trim();
          if (albumName.isNotEmpty) {
            // Group albums by album name only (not by artist)
            // This properly handles soundtracks/compilations with multiple artists
            // Trade-off: "Greatest Hits" by different artists will merge (rare case)
            final albumKey = albumName.toLowerCase().trim();

            int albumId;
            if (albumIds.containsKey(albumKey)) {
              // Album already processed in this session - reuse it
              albumId = albumIds[albumKey]!;
              log(
                '✓ Reusing album "$albumName" for "${song.title}" by $artistName',
              );
            } else {
              // First song from this album - create new album entry
              // Use "Various Artists" for the artist to indicate multiple artists may be present
              final album = Album(
                id: null,
                name: albumName,
                artist: 'Various Artists',
                songCount: 0,
                year: songYear,
                artworkPath: artworkPath.isNotEmpty ? artworkPath : null,
                createdTime: DateTime.now(),
                updatedTime: DateTime.now(),
              );
              albumId = await addAlbumUseCase(album);
              albumIds[albumKey] = albumId;
              log('✓ Created new album "$albumName" (Various Artists)');
            }
            touchedAlbumIds.add(albumId);
            await addSongToAlbumUseCase(albumId, song.id);
          }

          // Add to Genre
          final genreName = (song.genre ?? 'Unknown Genre').trim();
          if (genreName.isNotEmpty) {
            int genreId;
            if (genreIds.containsKey(genreName)) {
              genreId = genreIds[genreName]!;
            } else {
              final existingGenre = await genreRepository.getGenreByName(
                genreName,
              );
              if (existingGenre != null) {
                genreId = existingGenre.id!;
              } else {
                final genre = Genre(
                  id: null,
                  name: genreName,
                  songCount: 0,
                  artworkPath: artworkPath.isNotEmpty ? artworkPath : null,
                  createdTime: DateTime.now(),
                  updatedTime: DateTime.now(),
                );
                genreId = await addGenreUseCase(genre);
              }
              genreIds[genreName] = genreId;
            }
            await addSongToGenreUseCase(genreId, song.id);
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

      // Refresh cached artist metadata for albums touched in this sync
      for (final albumId in touchedAlbumIds) {
        await albumRepository.refreshAlbumCachedArtists(albumId);
      }

      // Update album counts for artists
      for (final entry in artistIds.entries) {
        final albums = await albumRepository.getAlbumsByArtist(entry.key);
        await artistRepository.updateArtistAlbumCount(
          entry.value,
          albums.length,
        );
      }

      // Clean up orphaned entities (folders, artists, albums with no songs)
      await localDataSource.cleanupOrphanedEntities();

      final allSongs = await localDataSource.getAllSongs(includeHidden: true);

      allSongs.forEach((song) {
        localDataSource.updateSongWithRelations(song);
      });

      if (mounted) {
        context.read<SongsBloc>().add(const SongsEvent.getAllSongs());
        context.read<AlbumBloc>().add(const AlbumEvent.fetchAllAlbums());
        context.read<FolderBloc>().add(const FolderEvent.fetchAllFolders());
        context.read<ArtistBloc>().add(const ArtistEvent.fetchAllArtists());
        context.read<GenreBloc>().add(const GenreEvent.fetchAllGenres());
      }


      // Debug output
      debugPrint("Found $scannedFiles");
      debugPrint("Found ${scannedFiles.length} songs");
      debugPrint("Found ${groupedByFolder.length} folders");
      debugPrint(
        "Sync completed: ${newSongIds.length} added, ${removedSongIds.length + missingSongIds.length} removed",
      );

      // Mark sync as successful
      _syncSuccessful = true;

      // Calculate actual scan duration and update animation
      if (_scanStartTime != null) {
        final scanDuration = DateTime.now().difference(_scanStartTime!);
        // Ensure minimum duration of 1 second for smooth animation
        final animationDuration = scanDuration.inMilliseconds < 1000
            ? const Duration(seconds: 1)
            : scanDuration;

        if (mounted) {
          // Reset controller with actual scan duration
          _controller.duration = animationDuration;
          _controller.reset();
          _controller.forward();
        }
      }
    } catch (e) {
      // Log error but don't mark sync as successful
      log('Error during sync: $e');
      _syncSuccessful = false;

      // Still update animation even on error
      if (_scanStartTime != null) {
        final scanDuration = DateTime.now().difference(_scanStartTime!);
        final animationDuration = scanDuration.inMilliseconds < 1000
            ? const Duration(seconds: 1)
            : scanDuration;

        if (mounted) {
          _controller.duration = animationDuration;
          _controller.reset();
          _controller.forward();
        }
      }

      // Check if it's a permission error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('missingpermissions') ||
          errorString.contains('permission') ||
          errorString.contains('access denied')) {
        log('Permission error detected, redirecting to permission screen');
        if (mounted) {
          // Reset permission flag since actual permission is not granted
          final appStateService = locator<AppStateService>();
          await appStateService.setPermissionGranted(false);
          context.go('/permission');
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize with a placeholder duration - will be updated after scan completes
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // placeholder, will be updated
    );

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
      backgroundColor: AppColors.white,
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
