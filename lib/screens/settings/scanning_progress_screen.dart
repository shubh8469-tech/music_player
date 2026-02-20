import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../commonWidgets/app_bar_with_icon_title.dart';
import '../../commonWidgets/textWidget.dart';
import '../../core/di/injection.dart';
import '../../features/albums/bloc/album_bloc.dart';
import '../../features/albums/domain/entities/album.dart';
import '../../features/albums/domain/repositories/album_repository.dart';
import '../../features/albums/domain/usecases/add_album.dart';
import '../../features/albums/domain/usecases/add_song_to_album.dart';
import '../../features/artists/bloc/artist_bloc.dart';
import '../../features/artists/domain/entities/artist.dart';
import '../../features/artists/domain/repositories/artist_repository.dart';
import '../../features/artists/domain/usecases/add_artist.dart';
import '../../features/artists/domain/usecases/add_song_to_artist.dart';
import '../../features/folders/bloc/folder_bloc.dart';
import '../../features/folders/domain/entities/folder.dart';
import '../../features/folders/domain/repositories/folder_repository.dart';
import '../../features/folders/domain/usecases/add_folder.dart';
import '../../features/folders/domain/usecases/add_song_to_folder.dart';
import '../../features/genres/bloc/genre_bloc.dart';
import '../../features/genres/domain/entities/genre.dart';
import '../../features/genres/domain/repositories/genre_repository.dart';
import '../../features/genres/domain/usecases/add_genre.dart';
import '../../features/genres/domain/usecases/add_song_to_genre.dart';
import '../../features/songs/bloc/songs_bloc.dart';
import '../../features/songs/data/dataSource/song_local_data_source.dart';
import '../../features/songs/data/models/song_model.dart';
import '../../features/songs/domain/usecases/add_song.dart';
import '../../generated/assets.dart';
import '../../themes/color.dart';
import '../../themes/font.dart';
import '../../utills/globals.dart';

class ScanningProgressScreen extends StatefulWidget {
  const ScanningProgressScreen({super.key});

  @override
  State<ScanningProgressScreen> createState() => _ScanningProgressScreenState();
}

class _ScanningProgressScreenState extends State<ScanningProgressScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  double _progress = 0.0;
  int _totalSongs = 0;
  int _processedSongs = 0;
  bool _isScanning = false;
  int _sizeFilterBytes = 50000;
  Set<String> _selectedFolders = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  Future<bool> _checkPermissions() async {
    if (Platform.isIOS) {
      return true;
    }
    final storageGranted = await Permission.storage.isGranted;
    final audioGranted = await Permission.audio.isGranted;
    if (storageGranted || audioGranted) {
      return true;
    }
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

  Future<void> _startScan() async {
    if (_isScanning) return;

    final state = GoRouterState.of(context);
    final extra = state.extra;
    final args = extra as Map<String, dynamic>?;
    if (args == null) {
      context.pop();
      return;
    }

    final durationFilter = args['durationFilter'] as int? ?? 30000;
    _sizeFilterBytes = args['sizeFilter'] as int? ?? 50000;
    final folderExtra = args['selectedFolders'];
    if (folderExtra is Set<String>) {
      _selectedFolders = {...folderExtra};
    } else if (folderExtra is List<String>) {
      _selectedFolders = folderExtra.toSet();
    } else {
      _selectedFolders = {};
    }

    final Set<String> normalizedSelectedFolders = _selectedFolders
        .map((name) => name.toLowerCase().trim())
        .where((name) => name.isNotEmpty)
        .toSet();

    setState(() {
      _isScanning = true;
      _progress = 0.0;
    });

    try {
      final hasPermission = await _checkPermissions();
      log('hasPermission ---> $hasPermission');
      if (!hasPermission) {
        if (mounted) {
          context.pop();
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
      final List<SongModel> deviceSongs = await _audioQuery.querySongs();
      log('Total device songs: ${deviceSongs.length}');
      log('Selected folders: $_selectedFolders');
      log('Normalized folders: $normalizedSelectedFolders');
      log('Duration filter: $durationFilter ms');
      log('Size filter: $_sizeFilterBytes bytes');

      // Get existing songs from database
      final List<SongsModel> dbSongs = await localDataSource.getAllSongs(
        includeHidden: true,
      );
      log('Total DB songs: ${dbSongs.length}');

      final Set<int> dbSongIds = dbSongs
          .map((s) => s.id ?? -1)
          .where((id) => id != -1)
          .toSet();
      final Set<int> allDeviceSongIds = deviceSongs.map((s) => s.id).toSet();

      // Remove songs that no longer exist on the device
      final Set<int> removedSongIds = dbSongIds.difference(allDeviceSongIds);
      for (final songId in removedSongIds) {
        await localDataSource.deleteSong(songId);
      }

      // Remove songs whose backing files are gone
      final missingSongIds = await localDataSource
          .validateAndFindMissingFiles();
      for (final songId in missingSongIds) {
        await localDataSource.deleteSong(songId);
      }

      final Map<int, _FolderInfo> folderInfoCache = {};
      int folderMatchCount = 0;
      int durationMatchCount = 0;
      int sizeMatchCount = 0;
      int allFiltersMatchCount = 0;
      final Set<String> sampleFolderNames = {};

      bool matchesSelectedFolders(SongModel song) {
        if (normalizedSelectedFolders.isEmpty) {
          return true;
        }
        final info = folderInfoCache.putIfAbsent(
          song.id,
          () => _resolveFolderInfo(song.data),
        );
        if (sampleFolderNames.length < 10) {
          sampleFolderNames.add(info.name);
        }
        final matches = normalizedSelectedFolders.contains(
          info.name.toLowerCase(),
        );
        if (matches) folderMatchCount++;
        return matches;
      }

      // Sample a few songs to see what folder names we're getting
      if (deviceSongs.isNotEmpty && normalizedSelectedFolders.isNotEmpty) {
        for (int i = 0; i < deviceSongs.length && i < 5; i++) {
          final info = _resolveFolderInfo(deviceSongs[i].data);
          sampleFolderNames.add(info.name);
        }
        log('Sample folder names from songs: ${sampleFolderNames.toList()}');
      }

      // Filter songs based on folder selection, duration, and size
      int folderRejectCount = 0;
      int durationRejectCount = 0;
      int sizeRejectCount = 0;

      final List<SongModel> filteredSongs = deviceSongs.where((song) {

        final duration = song.duration ?? 0;
        final size = (song.size as int?) ?? 0;
        final passesDuration = duration >= durationFilter;
        final passesSize = size == 0 || size >= _sizeFilterBytes;
        final passesFolder = matchesSelectedFolders(song);

        if (passesDuration) durationMatchCount++;
        if (passesSize) sizeMatchCount++;
        if (!passesFolder && normalizedSelectedFolders.isNotEmpty)
          folderRejectCount++;
        if (!passesDuration) durationRejectCount++;
        if (!passesSize && size > 0) sizeRejectCount++;
        if (passesFolder && passesDuration && passesSize)
          allFiltersMatchCount++;

        return passesFolder && passesDuration && passesSize && !isVideoFile(song.data);
      }).toList();

      log('Rejection counts:');
      log('  - Folder rejects: $folderRejectCount');
      log('  - Duration rejects: $durationRejectCount');
      log('  - Size rejects: $sizeRejectCount');

      log('After filtering:');
      log('  - Folder matches: $folderMatchCount');
      log('  - Duration matches (>= $durationFilter ms): $durationMatchCount');
      log(
        '  - Size matches (>= $_sizeFilterBytes bytes or 0): $sizeMatchCount',
      );
      log('  - All filters match: $allFiltersMatchCount');
      log('  - Filtered songs count: ${filteredSongs.length}');

      final Set<int> filteredSongIds = filteredSongs.map((s) => s.id).toSet();
      final Set<int> newSongIds = filteredSongIds.difference(dbSongIds);
      log('  - New songs (not in DB): ${newSongIds.length}');

      final List<SongModel> songsToProcess = filteredSongs
          .where((song) => newSongIds.contains(song.id))
          .toList();

      final int filteredCount = filteredSongs.length;
      _totalSongs = songsToProcess.length;
      _processedSongs = 0;
      _progress = 0.0;
      if (mounted) {
        setState(() {});
      }
      log('  - Songs to process: $_totalSongs');
      
      // Allow UI to update with initial state
      await Future.delayed(const Duration(milliseconds: 50));

      if (_totalSongs == 0) {
        log('');
        log('=== SCAN SUMMARY ===');
        log('Total device songs: ${deviceSongs.length}');
        log('Songs in database: ${dbSongs.length}');
        log('Songs matching filters: ${filteredSongs.length}');
        log('New songs to add: 0');
        log('');
        if (filteredSongs.length > 0 &&
            filteredSongs.length == dbSongs.length) {
          log(
            '✓ All ${filteredSongs.length} songs matching your criteria are already in the database.',
          );
          log(
            '  The other ${deviceSongs.length - filteredSongs.length} songs on your device',
          );
          log(
            '  don\'t match your filters (duration < $durationFilter ms or size < $_sizeFilterBytes bytes).',
          );
          log('');
          log('To find more songs, try:');
          log(
            '  - Lowering the duration filter (currently ${durationFilter ~/ 1000}s)',
          );
          log(
            '  - Lowering the size filter (currently ${_sizeFilterBytes ~/ 1000}KB)',
          );
        } else if (filteredSongs.length == 0) {
          log('✗ No songs match your filters.');
          log('  - Duration filter: >= ${durationFilter ~/ 1000}s');
          log('  - Size filter: >= ${_sizeFilterBytes ~/ 1000}KB');
          log(
            '  - Folder filter: ${normalizedSelectedFolders.isEmpty ? "All folders" : "${normalizedSelectedFolders.length} selected folders"}',
          );
          log('');
          log('Try adjusting your filters to find songs.');
        }
        log('===================');
        await localDataSource.cleanupOrphanedEntities();
        await _finalizeScan(0, filteredSongs.length);
        return;
      }

      final Map<String, int> folderIds = {};
      final Map<String, int> artistIds = {};
      final Map<String, int> albumIds = {};
      final Map<String, int> genreIds = {};
      final Set<int> touchedAlbumIds = {};

      final appDocDir = await getApplicationDocumentsDirectory();
      final artworkDir = Directory(p.join(appDocDir.path, 'artworks'));
      if (!await artworkDir.exists()) {
        await artworkDir.create(recursive: true);
      }

      int addedCount = 0;

      for (final song in songsToProcess) {

        final String path = song.data;

        // Skip video files (MP4, AVI, etc.) that may have been incorrectly indexed as audio
        if (isVideoFile(path)) {
          log('Skipping video file: $path');
          continue;
        }

        final info = folderInfoCache.putIfAbsent(
          song.id,
          () => _resolveFolderInfo(song.data),
        );

        final Uint8List? artworkBytes = await _fetchBestArtwork(song);
        String? artworkPath;

        if (artworkBytes != null && artworkBytes.isNotEmpty) {
          final file = File(p.join(artworkDir.path, '${song.id}.jpg'));
          await file.writeAsBytes(artworkBytes);
          artworkPath = file.path;
        }

        final int? songYear = await _deriveSongYear(song);

        final model = SongsModel(
          id: song.id,
          title: song.title.trim(),
          artist: (song.artist ?? '').trim(),
          album: (song.album ?? '').trim(),
          genre: (song.genre ?? '').trim(),
          year: songYear,
          duration: song.duration ?? 0,
          filePath: song.data,
          folder: info.name,
          artwork_path: artworkPath,
        );

        await addSongUseCase(model);
        addedCount++;

        if (info.name.isNotEmpty) {
          int folderId;
          if (folderIds.containsKey(info.name)) {
            folderId = folderIds[info.name]!;
          } else {
            final existingFolder = await folderRepository.getFolderByName(
              info.name,
            );
            if (existingFolder != null) {
              folderId = existingFolder.id!;
            } else {
              final folder = Folder(
                id: null,
                name: info.name,
                path: info.path,
                songCount: 0,
                artworkPath: artworkPath,
                createdTime: DateTime.now(),
                updatedTime: DateTime.now(),
              );
              folderId = await addFolderUseCase(folder);
            }
            folderIds[info.name] = folderId;
          }
          await addSongToFolderUseCase(folderId, song.id);
        }

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
                artworkPath: artworkPath,
                createdTime: DateTime.now(),
                updatedTime: DateTime.now(),
              );
              artistId = await addArtistUseCase(artist);
            }
            artistIds[artistName] = artistId;
          }
          await addSongToArtistUseCase(artistId, song.id);
        }

        final albumName = (song.album ?? 'Unknown Album').trim();
        if (albumName.isNotEmpty) {
          final albumKey = albumName.toLowerCase().trim();
          int albumId;
          if (albumIds.containsKey(albumKey)) {
            albumId = albumIds[albumKey]!;
          } else {
            final album = Album(
              id: null,
              name: albumName,
              artist: 'Various Artists',
              songCount: 0,
              year: songYear,
              artworkPath: artworkPath,
              createdTime: DateTime.now(),
              updatedTime: DateTime.now(),
            );
            albumId = await addAlbumUseCase(album);
            albumIds[albumKey] = albumId;
          }
          touchedAlbumIds.add(albumId);
          await addSongToAlbumUseCase(albumId, song.id);
        }

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
                artworkPath: artworkPath,
                createdTime: DateTime.now(),
                updatedTime: DateTime.now(),
              );
              genreId = await addGenreUseCase(genre);
            }
            genreIds[genreName] = genreId;
          }
          await addSongToGenreUseCase(genreId, song.id);
        }

        _processedSongs++;
        _updateProgress();
        
        // Allow UI to update after each song - delay to make progress visible
        // Use adaptive delay: shorter for large batches, longer for small batches
        if (_totalSongs > 20) {
          await Future.delayed(const Duration(milliseconds: 20));
        } else if (_totalSongs > 5) {
          await Future.delayed(const Duration(milliseconds: 50));
        } else {
          // For very small batches, use longer delay so user can see progress
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      for (final albumId in touchedAlbumIds) {
        await albumRepository.refreshAlbumCachedArtists(albumId);
      }

      for (final entry in artistIds.entries) {
        final albums = await albumRepository.getAlbumsByArtist(entry.key);
        await artistRepository.updateArtistAlbumCount(
          entry.value,
          albums.length,
        );
      }

      await localDataSource.cleanupOrphanedEntities();

      final allSongs = await localDataSource.getAllSongs(includeHidden: true);
      for (final song in allSongs) {
        await localDataSource.updateSongWithRelations(song);
      }

      await _finalizeScan(addedCount, filteredCount);

      context.read<SongsBloc>().add(const SongsEvent.getAllSongs());
      context.read<AlbumBloc>().add(const AlbumEvent.fetchAllAlbums());
      context.read<FolderBloc>().add(const FolderEvent.fetchAllFolders());
      context.read<ArtistBloc>().add(const ArtistEvent.fetchAllArtists());
      context.read<GenreBloc>().add(const GenreEvent.fetchAllGenres());

    } catch (e) {
      log('Error scanning: $e');
      if (mounted) {
        context.pop();
      }
    }
  }

  Future<void> _finalizeScan(int addedCount, int filteredCount) async {
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _progress = 1.0;
    });
    log(
      'Scan complete. Added $addedCount songs. Filtered: $filteredCount songs.',
    );
    context.go(
      '/dashboard/scan-complete',
      extra: {'addedCount': addedCount, 'filteredCount': filteredCount},
    );
  }

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

  Future<int?> _deriveSongYear(SongModel song) async {
    int? songYear;
    try {
      final dateAdded = song.dateAdded ?? 0;
      if (dateAdded > 0) {
        songYear = DateTime.fromMillisecondsSinceEpoch(dateAdded * 1000).year;
      }
    } catch (e) {
      log('Failed to derive year from dateAdded for ${song.title}: $e');
    }

    if (!song.data.startsWith('content://')) {
      try {
        final file = File(song.data);
        if (await file.exists()) {
          songYear ??= (await file.lastModified()).year;
        }
      } catch (e) {
        log('Failed to derive year from file system for ${song.title}: $e');
      }
    }
    return songYear;
  }

  _FolderInfo _resolveFolderInfo(String path) {
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
    return _FolderInfo(name: folderName, path: folderPath);
  }

  void _updateProgress() {
    if (mounted && _totalSongs > 0) {
      final newProgress = _processedSongs / _totalSongs;
      if (newProgress != _progress) {
        setState(() {
          _progress = newProgress.clamp(0.0, 1.0);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercentage = (_progress * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: "Scan Music",
        backgroundColor: AppColors.primaryOrange,
        titleColor: AppColors.white,
        centerTitle: false,
        onBack: _isScanning ? null : () => context.pop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.only(top: 50.h, bottom: 20.h),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              Assets.svgScanning,
              width: 106.w,
              height: 106.h,
            ),
          ),
          Texts(
            "$progressPercentage%",
            fontSize: 32.sp,
            fontWeight: AppFontWeights.semiBold,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          SizedBox(height: 8.h),
          // Texts(
          //   _isScanning ? "Scanning your library..." : "Finishing up",
          //   fontSize: 14.sp,
          //   fontWeight: AppFontWeights.regular,
          //   fontFamily: AppFonts.inter,
          //   color: AppColors.textColor.withOpacity(0.7),
          // ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50.r),
              ),
              disabledBackgroundColor: AppColors.primaryOrange,
            ),
            child: Texts(
              "Scanning",
              fontSize: 16.sp,
              fontWeight: AppFontWeights.medium,
              fontFamily: AppFonts.inter,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _FolderInfo {
  const _FolderInfo({required this.name, required this.path});

  final String name;
  final String path;
}
