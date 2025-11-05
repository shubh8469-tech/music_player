import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../features/songs/data/models/song_model.dart';
import '../../features/songs/data/dataSource/song_local_data_source.dart';
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
import '../di/injection.dart';

class ImportSongsService {
  /// Pick audio files from device
  Future<List<PlatformFile>?> pickAudioFiles() async {
    try {
      // Try with audio type first
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'm4a',
          'wav',
          'aac',
          'flac',
          'ogg',
          'wma',
          'aiff',
          'opus',
        ],
        allowMultiple: true,
        allowCompression: false,
        withData: false, // Don't load data into memory
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        log('Successfully picked ${result.files.length} files');
        for (var file in result.files) {
          log('File: ${file.name}, Path: ${file.path}');
        }
        return result.files;
      }

      log('No files selected');
      return null;
    } catch (e) {
      log('Error picking files: $e');
      // Try fallback with any file type if custom doesn't work
      try {
        FilePickerResult? fallbackResult = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: true,
          allowCompression: false,
        );

        if (fallbackResult != null) {
          // Filter only audio files
          final audioFiles = fallbackResult.files.where((file) {
            final extension = file.extension?.toLowerCase() ?? '';
            return [
              'mp3',
              'm4a',
              'wav',
              'aac',
              'flac',
              'ogg',
              'wma',
              'aiff',
              'opus',
            ].contains(extension);
          }).toList();

          if (audioFiles.isNotEmpty) {
            log(
              'Fallback: Successfully picked ${audioFiles.length} audio files',
            );
            return audioFiles;
          }
        }
      } catch (fallbackError) {
        log('Fallback error: $fallbackError');
      }
      return null;
    }
  }

  /// Import selected audio files to app directory and database
  Future<Map<String, dynamic>> importFiles(
    List<PlatformFile> files, {
    Function(int current, int total)? onProgress,
  }) async {
    int successCount = 0;
    int failedCount = 0;
    int skippedCount = 0;
    List<String> failedFiles = [];
    List<String> skippedFiles = [];

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

      // Get app directories
      final appDocDir = await getApplicationDocumentsDirectory();
      final artworkDir = Directory(p.join(appDocDir.path, 'artworks'));

      // Create artwork directory if it doesn't exist
      if (!await artworkDir.exists()) {
        await artworkDir.create(recursive: true);
      }

      // Get existing songs to check for duplicates
      final songDataSource = locator<SongLocalDataSource>();
      final existingSongs = await songDataSource.getAllSongs();
      final existingPaths = existingSongs.map((s) => s.filePath).toSet();

      log(
        'Checking for duplicates against ${existingPaths.length} existing songs',
      );

      // Track unique folders, artists, and albums
      Map<String, int> folderIds = {};
      Map<String, int> artistIds = {};
      Map<String, int> albumIds = {};

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        onProgress?.call(i + 1, files.length);

        try {
          if (file.path == null) {
            failedCount++;
            failedFiles.add(file.name);
            continue;
          }

          final sourceFile = File(file.path!);
          if (!await sourceFile.exists()) {
            failedCount++;
            failedFiles.add(file.name);
            continue;
          }

          // Check if this file is already imported (duplicate detection)
          if (existingPaths.contains(file.path!)) {
            skippedCount++;
            skippedFiles.add(file.name);
            log('⏭️  Skipping duplicate: ${file.name}');
            continue;
          }

          // Use the original file path (don't copy to save storage)
          final audioFilePath = file.path!;
          final timestamp = DateTime.now().millisecondsSinceEpoch;

          // Extract metadata from audio file
          String title = p.basenameWithoutExtension(file.name);
          String artist = 'Unknown Artist';
          String album = 'Unknown Album';
          String genre = '';
          int duration = 0;
          int? year;
          String artworkPath = '';

          try {
            // Extract metadata using metadata_god
            final metadata = await MetadataGod.readMetadata(
              file: audioFilePath,
            );

            // Extract text metadata
            if (metadata.title != null && metadata.title!.isNotEmpty) {
              title = metadata.title!;
            }
            if (metadata.artist != null && metadata.artist!.isNotEmpty) {
              artist = metadata.artist!;
            }
            if (metadata.album != null && metadata.album!.isNotEmpty) {
              album = metadata.album!;
            }
            if (metadata.genre != null && metadata.genre!.isNotEmpty) {
              genre = metadata.genre!;
            }
            if (metadata.durationMs != null) {
              duration = metadata.durationMs!.toInt();
            }

            // Try to extract year from various sources
            if (metadata.year != null && metadata.year! > 0) {
              year = metadata.year;
              log('Year from metadata.year: $year');
            }

            // If year is still null, try to parse from file modification date as fallback
            if (year == null) {
              try {
                final fileStats = await sourceFile.stat();
                year = fileStats.modified.year;
                log('Year from file modification date: $year');
              } catch (statError) {
                log('Could not get file stats for year: $statError');
              }
            }

            // Extract and save album artwork
            if (metadata.picture != null && metadata.picture!.data.isNotEmpty) {
              try {
                final artworkFile = File(
                  p.join(artworkDir.path, '${timestamp + i}.jpg'),
                );
                await artworkFile.writeAsBytes(metadata.picture!.data);
                artworkPath = artworkFile.path;
                log('✓ Extracted artwork for ${file.name}');
              } catch (artError) {
                log('✗ Failed to save artwork for ${file.name}: $artError');
              }
            } else {
              log('No artwork found in ${file.name}');
            }

            log(
              '✓ Metadata extracted - Title: $title | Artist: $artist | Album: $album | Year: $year | Duration: ${duration}ms',
            );
          } catch (e) {
            log('✗ Could not extract metadata from ${file.name}: $e');
            // Use file stats as fallback for year
            if (year == null) {
              try {
                final fileStats = await sourceFile.stat();
                year = fileStats.modified.year;
                log('Using file modification year as fallback: $year');
              } catch (statError) {
                log('Could not get file stats: $statError');
                // Last resort: use current year
                year = DateTime.now().year;
                log('Using current year as last fallback: $year');
              }
            }
          }

          // Generate a unique song ID (timestamp-based)
          final songId = timestamp + i;

          // Use the original file's folder name
          final folderName = p.basename(p.dirname(audioFilePath));
          final folderPath = p.dirname(audioFilePath);

          // Ensure year is never null
          year ??= DateTime.now().year;
          log('Final year value: $year');

          final model = SongsModel(
            id: songId,
            title: title,
            artist: artist,
            album: album,
            genre: genre,
            year: year,
            duration: duration,
            filePath: audioFilePath, // Use original path, not copied
            folder: folderName,
            artwork_path: artworkPath.isNotEmpty ? artworkPath : null,
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
                  artworkPath: null,
                  createdTime: DateTime.now(),
                  updatedTime: DateTime.now(),
                );
                folderId = await addFolderUseCase(folder);
              }
              folderIds[folderName] = folderId;
            }
            await addSongToFolderUseCase(folderId, songId);
          }

          // Add to Artist
          if (artist.isNotEmpty) {
            int artistId;
            if (artistIds.containsKey(artist)) {
              artistId = artistIds[artist]!;
            } else {
              final existingArtist = await artistRepository.getArtistByName(
                artist,
              );
              if (existingArtist != null) {
                artistId = existingArtist.id!;
              } else {
                final artistEntity = Artist(
                  id: null,
                  name: artist,
                  songCount: 0,
                  albumCount: 0,
                  artworkPath: null,
                  createdTime: DateTime.now(),
                  updatedTime: DateTime.now(),
                );
                artistId = await addArtistUseCase(artistEntity);
              }
              artistIds[artist] = artistId;
            }
            await addSongToArtistUseCase(artistId, songId);
          }

          // Add to Album
          if (album.isNotEmpty) {
            final albumKey = '$album|$artist';
            int albumId;
            if (albumIds.containsKey(albumKey)) {
              albumId = albumIds[albumKey]!;
            } else {
              final existingAlbum = await albumRepository
                  .getAlbumByNameAndArtist(album, artist);
              if (existingAlbum != null) {
                albumId = existingAlbum.id!;
              } else {
                final albumEntity = Album(
                  id: null,
                  name: album,
                  artist: artist,
                  songCount: 0,
                  year: year,
                  artworkPath: null,
                  createdTime: DateTime.now(),
                  updatedTime: DateTime.now(),
                );
                albumId = await addAlbumUseCase(albumEntity);
              }
              albumIds[albumKey] = albumId;
            }
            await addSongToAlbumUseCase(albumId, songId);
          }

          successCount++;
          log('Successfully imported: ${file.name}');
        } catch (e) {
          log('Error importing ${file.name}: $e');
          failedCount++;
          failedFiles.add(file.name);
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

      return {
        'success': successCount,
        'failed': failedCount,
        'skipped': skippedCount,
        'failedFiles': failedFiles,
        'skippedFiles': skippedFiles,
      };
    } catch (e) {
      log('Error during import: $e');
      return {
        'success': successCount,
        'failed': failedCount,
        'skipped': skippedCount,
        'failedFiles': failedFiles,
        'skippedFiles': skippedFiles,
        'error': e.toString(),
      };
    }
  }
}
