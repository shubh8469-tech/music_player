import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'music_app.db'),
      version: 1,
      onCreate: (db, version) async {
        final schema = await rootBundle.loadString('assets/db/setup.sql');
        final statements = _splitSqlStatements(schema);
        for (final stmt in statements) {
          if (stmt.trim().isNotEmpty) {
            await db.execute(stmt);
          }
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

  for (final String rawLine in script.split('\n')) {
    final String line = rawLine.trimRight();
    if (line.trim().isEmpty) {
      // Preserve blank lines within statements for readability
      if (current.isNotEmpty) current.writeln();
      continue;
    }

    final String upper = line.toUpperCase();

    // Detect start of a trigger
    if (!insideTriggerBlock && upper.contains('CREATE TRIGGER')) {
      insideTriggerBlock = true;
    }

    current.writeln(line);

    if (insideTriggerBlock) {
      // End of trigger is marked by END;
      if (RegExp(r"\\bEND\\s*;\\s*$", caseSensitive: false).hasMatch(line)) {
        statements.add(current.toString().trim());
        current.clear();
        insideTriggerBlock = false;
      }
    } else {
      // For regular statements, terminate at a trailing semicolon
      if (line.trim().endsWith(';')) {
        statements.add(current.toString().trim());
        current.clear();
      }
    }
  }

  final String leftover = current.toString().trim();
  if (leftover.isNotEmpty) {
    statements.add(leftover);
  }

  return statements;
}
