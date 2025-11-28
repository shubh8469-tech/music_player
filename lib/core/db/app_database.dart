import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'music_app.db'),
      version: 11,
      onOpen: (db) async {
        // Enable foreign keys to make CASCADE deletes work
        await db.execute('PRAGMA foreign_keys = ON');
        log('Foreign keys enabled');
      },
      onCreate: (db, version) async {
        // Enable foreign keys first
        await db.execute('PRAGMA foreign_keys = ON');
        log('Foreign keys enabled');

        final schema = await rootBundle.loadString('assets/db/setup.sql');
        final statements = _splitSqlStatements(schema);
        for (var i = 0; i < statements.length; i++) {
          log('Statement #$i:\n${statements[i]}');
        }
        log(
          'Executing ${statements.length} --Statement $statements --Statements SQL statements for DB setup.',
        );
        for (final stmt in statements) {
          if (stmt.trim().isNotEmpty) {
            await db.execute(stmt);
          }
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('PRAGMA foreign_keys = ON');

        Future<void> upsertBackupOption(
          String key,
          String label,
          int isSelected,
          String metaLabel,
        ) async {
          await db.execute(
            '''
            INSERT INTO backup_options (key, label, metaLabel, is_selected)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(key) DO UPDATE SET
              label = excluded.label,
              metaLabel = excluded.metaLabel,
              is_selected = excluded.is_selected
            ''',
            [key, label, metaLabel, isSelected],
          );
        }

        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE songs ADD COLUMN is_hidden INTEGER NOT NULL DEFAULT 0;',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE folders ADD COLUMN is_hidden INTEGER NOT NULL DEFAULT 0;',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE playlists ADD COLUMN cover_path TEXT;',
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE albums ADD COLUMN cached_artist_names TEXT;',
          );
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS backup_options (
              key TEXT PRIMARY KEY,
              label TEXT NOT NULL,
              metaLabel TEXT NOT NULL,
              is_selected INTEGER NOT NULL DEFAULT 1,
              updated_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
            );
          ''');

          await upsertBackupOption('tags', 'Tags', 1, "Songs, albums, artists, genres, track number");
          await upsertBackupOption('covers', 'Covers', 1, "Songs, albums");
          await upsertBackupOption('playlists', 'Playlists', 1, "");
          await upsertBackupOption('sort_settings', 'Sort Settings', 1, "Songs, folders, albums, artists, genres");
          await upsertBackupOption(
            'scan_hide_settings',
            'Scan and hide Settings',
            1,
              "Music scanning filters, hidden songs and folders"
          );
        }
        if (oldVersion < 7) {
          // Reserved for previous migrations
        }
        if (oldVersion < 8) {
          await db.delete(
            'backup_options',
            where: 'key = ?',
            whereArgs: ['lyrics'],
          );
        }
        if (oldVersion < 9) {
          // Create genres table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS genres (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL UNIQUE,
              song_count INTEGER NOT NULL DEFAULT 0,
              artwork_path TEXT,
              created_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
              updated_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
            );
          ''');

          // Create genres updated_time trigger
          await db.execute('''
            CREATE TRIGGER IF NOT EXISTS genres_updated_time_trigger
            AFTER UPDATE ON genres
            FOR EACH ROW
            WHEN NEW.updated_time = OLD.updated_time
              AND (SELECT execute_updated_time_triggers FROM trigger_control) = 1
            BEGIN
              UPDATE genres
              SET updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
              WHERE id = OLD.id;
            END;
          ''');

          // Create genre_songs junction table
          await db.execute('''
            CREATE TABLE IF NOT EXISTS genre_songs (
              genre_id INTEGER NOT NULL,
              song_id INTEGER NOT NULL,
              PRIMARY KEY (genre_id, song_id),
              FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE,
              FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
            );
          ''');

          // Create genre_song_insert trigger
          await db.execute('''
            CREATE TRIGGER IF NOT EXISTS genre_song_insert_trigger
            AFTER INSERT ON genre_songs
            FOR EACH ROW
            BEGIN
              UPDATE genres
              SET song_count = song_count + 1,
                  updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
              WHERE id = NEW.genre_id;
            END;
          ''');

          // Create genre_song_delete trigger
          await db.execute('''
            CREATE TRIGGER IF NOT EXISTS genre_song_delete_trigger
            AFTER DELETE ON genre_songs
            FOR EACH ROW
            BEGIN
              UPDATE genres
              SET song_count = song_count - 1,
                  updated_time = STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')
              WHERE id = OLD.genre_id;
            END;
          ''');
        }
        if (oldVersion < 10) {
          // Backfill genres from existing songs
          log('Backfilling genres from existing songs...');
          final songs = await db.query('songs', columns: ['id', 'genre']);
          final genreMap = <String, int>{};
          
          for (final song in songs) {
            final genreName = (song['genre'] as String?)?.trim();
            if (genreName == null || genreName.isEmpty) {
              continue;
            }

            // Get or create genre
            int genreId;
            if (genreMap.containsKey(genreName)) {
              genreId = genreMap[genreName]!;
            } else {
              // Check if genre already exists
              final existingGenre = await db.query(
                'genres',
                where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
                whereArgs: [genreName],
                limit: 1,
              );

              if (existingGenre.isNotEmpty) {
                genreId = existingGenre.first['id'] as int;
              } else {
                // Create new genre
                genreId = await db.insert(
                  'genres',
                  {
                    'name': genreName,
                    'song_count': 0,
                    'artwork_path': null,
                    'created_time': DateTime.now().toIso8601String(),
                    'updated_time': DateTime.now().toIso8601String(),
                  },
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
              }
              genreMap[genreName] = genreId;
            }

            // Link song to genre (only if not already linked)
            try {
              await db.insert(
                'genre_songs',
                {
                  'genre_id': genreId,
                  'song_id': song['id'] as int,
                },
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );
            } catch (e) {
              log('Error linking song ${song['id']} to genre $genreName: $e');
            }
          }

          log('Backfilled ${genreMap.length} genres from ${songs.length} songs');
        }
        if (oldVersion < 11) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS scan_preferences (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              min_duration_ms INTEGER NOT NULL DEFAULT 30000,
              min_size_bytes INTEGER NOT NULL DEFAULT 50000,
              updated_time DATETIME NOT NULL DEFAULT (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
            );
          ''');

          await db.insert(
            'scan_preferences',
            {
              'id': 1,
              'min_duration_ms': 30000,
              'min_size_bytes': 50000,
              'updated_time': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      },
    );
    return _db!;
  }
}

/// Splits an SQL script into executable statements, preserving multi-line
/// constructs like CREATE TRIGGER ... BEGIN ... END; without splitting on
/// inner semicolons.
List<String> _splitSqlStatements(String script) {
  final List<String> statements = [];
  final StringBuffer current = StringBuffer();
  bool insideTriggerBlock = false;

  for (final rawLine in script.split('\n')) {
    final line = rawLine.trimRight();

    // Ignore full-line comments
    if (line.trim().startsWith('--')) {
      continue;
    }

    if (line.trim().isEmpty) {
      continue;
    }

    final upper = line.toUpperCase();

    // Detect start of trigger
    if (!insideTriggerBlock && upper.contains('CREATE TRIGGER')) {
      insideTriggerBlock = true;
    }

    current.writeln(line);

    if (insideTriggerBlock) {
      // End of trigger block
      if (line.trim().toUpperCase() == 'END;' ||
          line.trim().toUpperCase().endsWith('END;')) {
        statements.add(current.toString().trim());
        current.clear();
        insideTriggerBlock = false;
      }
    } else {
      // Normal statement ends with ;
      if (line.trim().endsWith(';')) {
        statements.add(current.toString().trim());
        current.clear();
      }
    }
  }

  // Add last leftover
  if (current.isNotEmpty) {
    statements.add(current.toString().trim());
  }

  return statements;
}
