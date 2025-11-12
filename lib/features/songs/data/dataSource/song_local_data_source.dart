import 'package:sqflite/sqflite.dart';
import '../models/song_model.dart';

abstract class SongLocalDataSource {
  Future<int> insertSong(SongsModel song);
  Future<List<SongsModel>> getAllSongs({bool includeHidden = false});
  Future<List<SongsModel>> getHiddenSongs();
  Future<int> updateSongHiddenStatus(int id, bool isHidden);
  Future<void> refreshRelatedEntityCounts();
  Future<int> deleteSong(int id);
  Future<int> updateSong(SongsModel song);
  Future<void> updateSongWithRelations(SongsModel updatedSong);
}

class SongLocalDataSourceImpl implements SongLocalDataSource {
  final Database db;

  SongLocalDataSourceImpl(this.db);

  @override
  Future<int> insertSong(SongsModel song) async {
    return await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore, // or replace
    );
  }

  @override
  Future<List<SongsModel>> getAllSongs({bool includeHidden = false}) async {
    final result = await db.query(
      'songs',
      where: includeHidden ? null : 'is_hidden = ?',
      whereArgs: includeHidden ? null : [0],
    );
    return result.map((map) => SongsModel.fromMap(map)).toList();
  }

  @override
  Future<List<SongsModel>> getHiddenSongs() async {
    final result = await db.query(
      'songs',
      where: 'is_hidden = ?',
      whereArgs: [1],
    );
    return result.map((map) => SongsModel.fromMap(map)).toList();
  }

  @override
  Future<int> updateSongHiddenStatus(int id, bool isHidden) async {
    final result = await db.transaction((txn) async {
      final now = DateTime.now().toIso8601String();
      final updatedRows = await txn.update(
        'songs',
        {'is_hidden': isHidden ? 1 : 0, 'updated_time': now},
        where: 'id = ?',
        whereArgs: [id],
      );

      final folderRows = await txn.query(
        'folder_songs',
        columns: ['folder_id'],
        where: 'song_id = ?',
        whereArgs: [id],
      );

      if (folderRows.isNotEmpty) {
        final folderIds = folderRows
            .map((row) => row['folder_id'] as int)
            .toSet()
            .toList();

        if (isHidden) {
          for (final folderId in folderIds) {
            final visibleCountResult = await txn.rawQuery(
              '''
              SELECT COUNT(*) as visible_count
              FROM folder_songs fs
              INNER JOIN songs s ON s.id = fs.song_id
              WHERE fs.folder_id = ? AND s.is_hidden = 0
              ''',
              [folderId],
            );
            final visibleCount = Sqflite.firstIntValue(visibleCountResult) ?? 0;
            if (visibleCount == 0) {
              await txn.update(
                'folders',
                {'is_hidden': 1, 'updated_time': now},
                where: 'id = ?',
                whereArgs: [folderId],
              );
            }
          }
        } else {
          final placeholders = List.filled(folderIds.length, '?').join(', ');
          await txn.rawUpdate(
            '''
            UPDATE folders
            SET is_hidden = 0,
                updated_time = ?
            WHERE id IN ($placeholders)
            ''',
            [now, ...folderIds],
          );
        }
      }

      return updatedRows;
    });

    await refreshRelatedEntityCounts();
    return result;
  }

  @override
  Future<void> refreshRelatedEntityCounts() async {
    await db.transaction((txn) async {
      await txn.rawUpdate('''
        UPDATE playlists
        SET song_count = (
          SELECT COUNT(*)
          FROM playlist_songs ps
          INNER JOIN songs s ON s.id = ps.song_id
          WHERE ps.playlist_id = playlists.id AND s.is_hidden = 0
        )
      ''');

      await txn.rawUpdate('''
        UPDATE folders
        SET song_count = (
          SELECT COUNT(*)
          FROM folder_songs fs
          INNER JOIN songs s ON s.id = fs.song_id
          WHERE fs.folder_id = folders.id AND s.is_hidden = 0
        )
      ''');

      await txn.rawUpdate('''
        UPDATE albums
        SET song_count = (
          SELECT COUNT(*)
          FROM album_songs als
          INNER JOIN songs s ON s.id = als.song_id
          WHERE als.album_id = albums.id AND s.is_hidden = 0
        )
      ''');

      await txn.rawUpdate('''
        UPDATE artists
        SET song_count = (
          SELECT COUNT(*)
          FROM artist_songs ars
          INNER JOIN songs s ON s.id = ars.song_id
          WHERE ars.artist_id = artists.id AND s.is_hidden = 0
        )
      ''');
    });
  }

  @override
  Future<int> deleteSong(int id) async {
    return await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> updateSong(SongsModel song) async {
    return await db.update(
      'songs',
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  @override
  Future<void> updateSongWithRelations(SongsModel updatedSong) async {
    await db.transaction((txn) async {
      final songId = updatedSong.id;
      if (songId == null) {
        throw ArgumentError('Cannot update a song without an id');
      }

      final existingSongResult = await txn.query(
        'songs',
        where: 'id = ?',
        whereArgs: [songId],
        limit: 1,
      );

      if (existingSongResult.isEmpty) {
        throw Exception('Song with id $songId not found');
      }

      final existingSong = SongsModel.fromMap(existingSongResult.first);
      final nowIso = DateTime.now().toIso8601String();

      final oldAlbumLink = await txn.query(
        'album_songs',
        columns: ['album_id'],
        where: 'song_id = ?',
        whereArgs: [songId],
        limit: 1,
      );
      final int? oldAlbumId =
          oldAlbumLink.isNotEmpty ? oldAlbumLink.first['album_id'] as int : null;

      final oldArtistLink = await txn.query(
        'artist_songs',
        columns: ['artist_id'],
        where: 'song_id = ?',
        whereArgs: [songId],
        limit: 1,
      );
      final int? oldArtistId = oldArtistLink.isNotEmpty
          ? oldArtistLink.first['artist_id'] as int
          : null;

      final trimmedTitle = updatedSong.title.trim().isEmpty
          ? existingSong.title
          : updatedSong.title.trim();
      final trimmedAlbum = updatedSong.album.trim();
      final trimmedArtist = updatedSong.artist.trim();

      final resolvedAlbumName = await _updateAlbumRelations(
        txn: txn,
        songId: songId,
        oldAlbumId: oldAlbumId,
        existingSong: existingSong,
        newAlbumName: trimmedAlbum.isEmpty ? 'Unknown Album' : trimmedAlbum,
        newArtistName:
            trimmedArtist.isEmpty ? 'Unknown Artist' : trimmedArtist,
        nowIso: nowIso,
      );

      final artistUpdateResult = await _updateArtistRelations(
        txn: txn,
        songId: songId,
        oldArtistId: oldArtistId,
        existingSong: existingSong,
        newArtistName:
            trimmedArtist.isEmpty ? 'Unknown Artist' : trimmedArtist,
        nowIso: nowIso,
      );

      final updatedFields = <String, Object?>{
        'title': trimmedTitle,
        'album': resolvedAlbumName,
        'artist': artistUpdateResult.canonicalName,
        'updated_time': nowIso,
      };

      if (updatedSong.genre.trim().isNotEmpty) {
        updatedFields['genre'] = updatedSong.genre.trim();
      }

      await txn.update(
        'songs',
        updatedFields,
        where: 'id = ?',
        whereArgs: [songId],
      );

      for (final artistId in artistUpdateResult.affectedArtistIds) {
        final albumCountResult = await txn.rawQuery(
          '''
          SELECT COUNT(DISTINCT als.album_id) as album_count
          FROM artist_songs ars
          LEFT JOIN album_songs als ON ars.song_id = als.song_id
          INNER JOIN songs s ON s.id = ars.song_id
          WHERE ars.artist_id = ? AND s.is_hidden = 0
          ''',
          [artistId],
        );
        final albumCount = Sqflite.firstIntValue(albumCountResult) ?? 0;
        await txn.update(
          'artists',
          {
            'album_count': albumCount,
            'updated_time': nowIso,
          },
          where: 'id = ?',
          whereArgs: [artistId],
        );
      }
    });

    await refreshRelatedEntityCounts();
  }

  Future<String?> _updateAlbumRelations({
    required Transaction txn,
    required int songId,
    required int? oldAlbumId,
    required SongsModel existingSong,
    required String newAlbumName,
    required String newArtistName,
    required String nowIso,
  }) async {
    final sanitizedAlbum = newAlbumName.trim().isEmpty
        ? 'Unknown Album'
        : newAlbumName.trim();

    // Remove album relations if user cleared the album value.
    if (sanitizedAlbum.isEmpty) {
      if (oldAlbumId != null) {
        final oldAlbumCount = Sqflite.firstIntValue(
              await txn.rawQuery(
                'SELECT COUNT(*) FROM album_songs WHERE album_id = ?',
                [oldAlbumId],
              ),
            ) ??
            0;

        await txn.delete(
          'album_songs',
          where: 'song_id = ?',
          whereArgs: [songId],
        );

        if (oldAlbumCount == 1) {
          await txn.delete(
            'albums',
            where: 'id = ?',
            whereArgs: [oldAlbumId],
          );
        }
      }
      return null;
    }

    final normalizedAlbum = sanitizedAlbum.toLowerCase();
    final normalizedExistingAlbum = existingSong.album.trim().toLowerCase();
    final albumChanged = normalizedAlbum != normalizedExistingAlbum;

    int? existingAlbumId;
    String? existingAlbumCanonicalName;
    final existingAlbumRow = await txn.query(
      'albums',
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
      whereArgs: [sanitizedAlbum],
      limit: 1,
    );

    if (existingAlbumRow.isNotEmpty) {
      existingAlbumId = existingAlbumRow.first['id'] as int;
      existingAlbumCanonicalName = existingAlbumRow.first['name'] as String;
    }

    if (oldAlbumId == null) {
      final targetAlbumId = existingAlbumId ??
          await _insertAlbum(
            txn,
            sanitizedAlbum,
            newArtistName,
            existingSong,
            nowIso,
          );

      await txn.insert(
        'album_songs',
        {'album_id': targetAlbumId, 'song_id': songId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      return existingAlbumCanonicalName ?? sanitizedAlbum;
    }

    final oldAlbumCount = Sqflite.firstIntValue(
          await txn.rawQuery(
            'SELECT COUNT(*) FROM album_songs WHERE album_id = ?',
            [oldAlbumId],
          ),
        ) ??
        0;

    if (!albumChanged) {
      if (existingAlbumCanonicalName != null &&
          existingAlbumCanonicalName != existingSong.album) {
        await txn.update(
          'songs',
          {'album': existingAlbumCanonicalName},
          where: 'id = ?',
          whereArgs: [songId],
        );
        return existingAlbumCanonicalName;
      }

      if (oldAlbumCount == 1 && sanitizedAlbum != existingSong.album) {
        // Only song for this album. Rename the album record.
        await txn.update(
          'albums',
          {
            'name': sanitizedAlbum,
            'artist': newArtistName.isNotEmpty ? newArtistName : 'Various Artists',
            'updated_time': nowIso,
          },
          where: 'id = ?',
          whereArgs: [oldAlbumId],
        );
        return sanitizedAlbum;
      }

      return existingSong.album;
    }

    if (existingAlbumId != null && existingAlbumId != oldAlbumId) {
      await txn.delete(
        'album_songs',
        where: 'song_id = ?',
        whereArgs: [songId],
      );
      await txn.insert(
        'album_songs',
        {'album_id': existingAlbumId, 'song_id': songId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      if (oldAlbumCount == 1) {
        await txn.delete(
          'albums',
          where: 'id = ?',
          whereArgs: [oldAlbumId],
        );
      }

      return existingAlbumCanonicalName ?? sanitizedAlbum;
    }

    if (oldAlbumCount == 1) {
      await txn.update(
        'albums',
        {
          'name': sanitizedAlbum,
          'artist': newArtistName.isNotEmpty ? newArtistName : 'Various Artists',
          'updated_time': nowIso,
        },
        where: 'id = ?',
        whereArgs: [oldAlbumId],
      );
      return sanitizedAlbum;
    }

    await txn.delete(
      'album_songs',
      where: 'song_id = ?',
      whereArgs: [songId],
    );

    final newAlbumId = await _insertAlbum(
      txn,
      sanitizedAlbum,
      newArtistName,
      existingSong,
      nowIso,
    );

    await txn.insert(
      'album_songs',
      {'album_id': newAlbumId, 'song_id': songId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return sanitizedAlbum;
  }

  Future<_ArtistUpdateResult> _updateArtistRelations({
    required Transaction txn,
    required int songId,
    required int? oldArtistId,
    required SongsModel existingSong,
    required String newArtistName,
    required String nowIso,
  }) async {
    final sanitizedArtist = newArtistName.trim().isEmpty
        ? 'Unknown Artist'
        : newArtistName.trim();

    final affectedArtistIds = <int>{};

    if (oldArtistId == null) {
      if (sanitizedArtist.isEmpty) {
        return _ArtistUpdateResult(
          canonicalName: null,
          affectedArtistIds: affectedArtistIds,
        );
      }

      final newArtistId = await _resolveArtistId(
        txn,
        sanitizedArtist,
        existingSong,
        nowIso,
      );

      await txn.insert(
        'artist_songs',
        {'artist_id': newArtistId, 'song_id': songId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      affectedArtistIds.add(newArtistId);

      return _ArtistUpdateResult(
        canonicalName: sanitizedArtist,
        affectedArtistIds: affectedArtistIds,
      );
    }

    final oldArtistCount = Sqflite.firstIntValue(
          await txn.rawQuery(
            'SELECT COUNT(*) FROM artist_songs WHERE artist_id = ?',
            [oldArtistId],
          ),
        ) ??
        0;

    if (sanitizedArtist.isEmpty) {
      await txn.delete(
        'artist_songs',
        where: 'song_id = ?',
        whereArgs: [songId],
      );

      if (oldArtistCount == 1) {
        await txn.delete(
          'artists',
          where: 'id = ?',
          whereArgs: [oldArtistId],
        );
      } else {
        affectedArtistIds.add(oldArtistId);
      }

      return _ArtistUpdateResult(
        canonicalName: null,
        affectedArtistIds: affectedArtistIds,
      );
    }

    final existingArtistRow = await txn.query(
      'artists',
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
      whereArgs: [sanitizedArtist],
      limit: 1,
    );

    int? resolvedArtistId;
    String? resolvedArtistName;
    if (existingArtistRow.isNotEmpty) {
      resolvedArtistId = existingArtistRow.first['id'] as int;
      resolvedArtistName = existingArtistRow.first['name'] as String;
    }

    final normalizedExistingArtist =
        existingSong.artist.trim().toLowerCase();
    final normalizedSanitizedArtist = sanitizedArtist.toLowerCase();
    final artistChanged =
        normalizedExistingArtist != normalizedSanitizedArtist;

    if (!artistChanged) {
      if (resolvedArtistName != null &&
          resolvedArtistName != existingSong.artist) {
        return _ArtistUpdateResult(
          canonicalName: resolvedArtistName,
          affectedArtistIds: {oldArtistId},
        );
      }

      if (oldArtistCount == 1 && sanitizedArtist != existingSong.artist) {
        await txn.update(
          'artists',
          {
            'name': sanitizedArtist,
            'updated_time': nowIso,
          },
          where: 'id = ?',
          whereArgs: [oldArtistId],
        );
      }

      affectedArtistIds.add(oldArtistId);

      return _ArtistUpdateResult(
        canonicalName: sanitizedArtist,
        affectedArtistIds: affectedArtistIds,
      );
    }

    final targetArtistId = resolvedArtistId ??
        await _resolveArtistId(
          txn,
          sanitizedArtist,
          existingSong,
          nowIso,
        );

    await txn.delete(
      'artist_songs',
      where: 'song_id = ?',
      whereArgs: [songId],
    );

    await txn.insert(
      'artist_songs',
      {'artist_id': targetArtistId, 'song_id': songId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    if (oldArtistCount == 1) {
      await txn.delete(
        'artists',
        where: 'id = ?',
        whereArgs: [oldArtistId],
      );
    } else {
      affectedArtistIds.add(oldArtistId);
    }

    affectedArtistIds.add(targetArtistId);

    return _ArtistUpdateResult(
      canonicalName: resolvedArtistName ?? sanitizedArtist,
      affectedArtistIds: affectedArtistIds,
    );
  }

  Future<int> _insertAlbum(
    Transaction txn,
    String albumName,
    String albumArtist,
    SongsModel song,
    String nowIso,
  ) async {
    final insertData = {
      'name': albumName,
      'artist': albumArtist.isNotEmpty ? albumArtist : 'Various Artists',
      'song_count': 0,
      'year': song.year,
      'artwork_path': song.artwork_path,
      'created_time': nowIso,
      'updated_time': nowIso,
    };

    return await txn.insert('albums', insertData);
  }

  Future<int> _resolveArtistId(
    Transaction txn,
    String artistName,
    SongsModel song,
    String nowIso,
  ) async {
    final existingArtist = await txn.query(
      'artists',
      where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
      whereArgs: [artistName],
      limit: 1,
    );

    if (existingArtist.isNotEmpty) {
      return existingArtist.first['id'] as int;
    }

    final insertData = {
      'name': artistName,
      'song_count': 0,
      'album_count': 0,
      'artwork_path': song.artwork_path,
      'created_time': nowIso,
      'updated_time': nowIso,
    };

    return await txn.insert('artists', insertData);
  }
}

class _ArtistUpdateResult {
  final String? canonicalName;
  final Set<int> affectedArtistIds;

  _ArtistUpdateResult({
    required this.canonicalName,
    required this.affectedArtistIds,
  });
}
