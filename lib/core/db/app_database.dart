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
      version: 5,
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
