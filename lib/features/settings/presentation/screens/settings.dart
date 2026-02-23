import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:music_app/core/widgets/app_bar_with_icon_title.dart';
import 'package:music_app/core/widgets/textWidget.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/albums/presentation/bloc/album_bloc.dart';
import 'package:music_app/features/albums/domain/entities/album.dart';
import 'package:music_app/features/albums/domain/repositories/album_repository.dart';
import 'package:music_app/features/albums/domain/usecases/add_album.dart';
import 'package:music_app/features/albums/domain/usecases/add_song_to_album.dart';
import 'package:music_app/features/artists/presentation/bloc/artist_bloc.dart';
import 'package:music_app/features/artists/domain/entities/artist.dart';
import 'package:music_app/features/artists/domain/repositories/artist_repository.dart';
import 'package:music_app/features/artists/domain/usecases/add_artist.dart';
import 'package:music_app/features/artists/domain/usecases/add_song_to_artist.dart';
import 'package:music_app/features/folders/presentation/bloc/folder_bloc.dart';
import 'package:music_app/features/folders/domain/entities/folder.dart';
import 'package:music_app/features/folders/domain/repositories/folder_repository.dart';
import 'package:music_app/features/folders/domain/usecases/add_folder.dart';
import 'package:music_app/features/folders/domain/usecases/add_song_to_folder.dart';
import 'package:music_app/features/genres/presentation/bloc/genre_bloc.dart';
import 'package:music_app/features/genres/domain/entities/genre.dart';
import 'package:music_app/features/genres/domain/repositories/genre_repository.dart';
import 'package:music_app/features/genres/domain/usecases/add_genre.dart';
import 'package:music_app/features/genres/domain/usecases/add_song_to_genre.dart';
import 'package:music_app/features/songs/presentation/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/datasources/song_local_data_source.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/features/songs/domain/usecases/add_song.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/core/utils/globals.dart';
import 'package:music_app/core/utils/snack_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool keepScreenOn = false;
  bool lockScreenPlaying = false;
  bool pauseOnDetach = false;
  bool _isRefreshing = false;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  void _showComingSoonSnack() {
    showSnackBar(
      context,
      () {},
      message: "Coming soon",
      alertBannerLocation: AlertBannerLocation.bottom,
    );
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

  Future<void> _refreshLibrary() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        showSnackBar(
          context,
          () {},
          message: "Permission denied. Please grant storage permission.",
          backgroundColor: Colors.red,
          alertBannerLocation: AlertBannerLocation.bottom,
        );
        return;
      }

      showSnackBar(
        context,
        () {},
        message: "Refreshing library...",
        alertBannerLocation: AlertBannerLocation.bottom,
      );

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

      // Get songs from device and database
      List<SongModel> deviceSongs = await _audioQuery.querySongs();
      List<SongsModel> dbSongs = await localDataSource.getAllSongs(
        includeHidden: true,
      );

      // Find new and removed songs
      Set<int> deviceSongIds = deviceSongs.map((s) => s.id).toSet();
      Set<int> dbSongIds = dbSongs
          .map((s) => s.id ?? -1)
          .where((id) => id != -1)
          .toSet();
      Set<int> newSongIds = deviceSongIds.difference(dbSongIds);
      Set<int> removedSongIds = dbSongIds.difference(deviceSongIds);

      // Remove songs that are no longer on device
      for (int songId in removedSongIds) {
        await localDataSource.deleteSong(songId);
      }

      // Validate file existence
      final missingSongIds = await localDataSource
          .validateAndFindMissingFiles();
      for (int songId in missingSongIds) {
        await localDataSource.deleteSong(songId);
      }

      // Process new songs
      int addedCount = 0;
      Map<String, int> folderIds = {};
      Map<String, int> artistIds = {};
      Map<String, int> albumIds = {};
      Map<String, int> genreIds = {};
      final Set<int> touchedAlbumIds = {};

      for (final song in deviceSongs) {
        if (!newSongIds.contains(song.id)) continue;

        final String path = song.data;

        // Skip video files (MP4, AVI, etc.) that may have been incorrectly indexed as audio
        if (isVideoFile(path)) {
          log('Skipping video file: $path');
          continue;
        }

        if ((song.duration ?? 0) < 1000) continue;

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

        // Extract year
        int? songYear;
        try {
          final dateAdded = song.dateAdded ?? 0;
          if (dateAdded > 0) {
            songYear = DateTime.fromMillisecondsSinceEpoch(
              dateAdded * 1000,
            ).year;
          }
        } catch (e) {
          log('Failed to extract year: $e');
        }

        final Uint8List? artworkBytes = await _fetchBestArtwork(song);
        String? artworkPath;

        if (artworkBytes != null && artworkBytes.isNotEmpty) {
          final file = File(p.join(artworkDir.path, '${song.id}.jpg'));
          await file.writeAsBytes(artworkBytes);
          artworkPath = file.path;
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
        addedCount++;

        // Add to folder, artist, album (similar to sync_progress.dart)
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
                artworkPath: artworkPath,
                createdTime: DateTime.now(),
                updatedTime: DateTime.now(),
              );
              folderId = await addFolderUseCase(folder);
            }
            folderIds[folderName] = folderId;
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
      }

      // Refresh album metadata
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

      // Clean up orphaned entities
      await localDataSource.cleanupOrphanedEntities();

      // Update song relations
      final allSongs = await localDataSource.getAllSongs(includeHidden: true);
      for (final song in allSongs) {
        await localDataSource.updateSongWithRelations(song);
      }

      final removedCount = removedSongIds.length + missingSongIds.length;
      showSnackBar(
        context,
        () {},
        message: "Library refreshed: $addedCount added, $removedCount removed",
        alertBannerLocation: AlertBannerLocation.bottom,
      );

      context.read<SongsBloc>().add(const SongsEvent.getAllSongs());
      context.read<AlbumBloc>().add(const AlbumEvent.fetchAllAlbums());
      context.read<FolderBloc>().add(const FolderEvent.fetchAllFolders());
      context.read<ArtistBloc>().add(const ArtistEvent.fetchAllArtists());
      context.read<GenreBloc>().add(const GenreEvent.fetchAllGenres());
    } catch (e) {
      log('Error refreshing library: $e');
      showSnackBar(
        context,
        () {},
        message: "Failed to refresh library: ${e.toString()}",
        backgroundColor: Colors.red,
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBarWithIconTitle(
        title: "Settings",
        backgroundColor: AppColors.primaryOrange,
        titleColor: AppColors.white,
        centerTitle: false,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              children: [
                _optionTile(
                  asset: Assets.svgPremium,
                  title: "Go Premium ✨",
                  onTap: _showComingSoonSnack,
                ),
                _optionTile(
                  asset: Assets.svgScan,
                  title: "Scan Music",
                  subtitle: "Scan and add music from device",
                  onTap: () {
                    context.push('/dashboard/scan-music');
                  },
                ),
                _optionTile(
                  asset: Assets.svgScan,
                  title: "Refresh library",
                  subtitle: _isRefreshing
                      ? "Refreshing..."
                      : "Sync with device music",
                  trailing: _isRefreshing
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryOrange,
                            ),
                          ),
                        )
                      : null,
                  onTap: _isRefreshing ? null : _refreshLibrary,
                ),
                _optionTile(
                  asset: Assets.svgHidden,
                  title: "Hidden music",
                  onTap: () {
                    context.push('/dashboard/hidden-music');
                  },
                ),
                _optionTile(
                  asset: Assets.svgBackup,
                  title: "Backup & restore",
                  subtitle: "Last backup: 2025-08-25 13:52:14",
                  onTap: () {
                    _showComingSoonSnack();
                    // context.push('/dashboard/backup-restore');
                  },
                ),
                _sectionDivider(),
                _optionTile(
                  asset: Assets.svgBulb,
                  title: "Keep screen on",
                  subtitle: "Stay on while on the player screen",
                  trailing: _buildSwitch(
                    value: keepScreenOn,
                    onChanged: (value) {
                      // setState(() => keepScreenOn = value);
                      _showComingSoonSnack();
                    },
                  ),
                ),
                _optionTile(
                  asset: Assets.svgLock,
                  title: "Lock screen playing",
                  subtitle: "Show now playing when lock screen",
                  trailing: _buildSwitch(
                    value: lockScreenPlaying,
                    onChanged: (value) {
                      // setState(() => lockScreenPlaying = value);
                      _showComingSoonSnack();
                    },
                  ),
                ),
                _optionTile(
                  asset: Assets.svgPauseHead,
                  title: "Pause on detach",
                  subtitle: "Pause playback when headphone is detached",
                  trailing: _buildSwitch(
                    value: pauseOnDetach,
                    onChanged: (value) {
                      // setState(() => pauseOnDetach = value);
                      _showComingSoonSnack();
                    },
                  ),
                ),
                _sectionDivider(),
                _optionTile(
                  asset: Assets.svgFaq,
                  title: "FAQs",
                  onTap: _showComingSoonSnack,
                ),
                _optionTile(
                  asset: Assets.svgFeedback,
                  title: "Feedback",
                  onTap: _showComingSoonSnack,
                ),
                _optionTile(
                  asset: Assets.svgPrivacy,
                  title: "Privacy Policy",
                  onTap: _showComingSoonSnack,
                ),
                _optionTile(
                  asset: Assets.svgTermsDoc,
                  title: "Terms of use",
                  onTap: _showComingSoonSnack,
                ),
                _optionTile(
                  asset: Assets.svgVersion,
                  title: "Version",
                  subtitle: "3.8.1.541",
                  onTap: _showComingSoonSnack,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionTile({
    required String asset,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          crossAxisAlignment: subtitle != null
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 24.h,
              width: 24.w,
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: SvgPicture.asset(
                  asset,
                  colorFilter: ColorFilter.mode(
                    AppColors.textColor.withValues(alpha: 0.5),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            SizedBox(width: 17.5.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Texts(
                    title,
                    fontSize: 16.sp,
                    fontWeight: AppFontWeights.medium,
                    fontFamily: AppFonts.inter,
                    color: AppColors.textColor,
                  ),
                  if (subtitle != null) SizedBox(height: 4.h),
                  if (subtitle != null)
                    Texts(
                      subtitle,
                      fontSize: 12.sp,
                      fontWeight: AppFontWeights.regular,
                      fontFamily: AppFonts.inter,
                      color: AppColors.textColor.withOpacity(0.6),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.white,
      activeTrackColor: AppColors.primaryOrange,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.grey.shade300,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _sectionDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }
}
