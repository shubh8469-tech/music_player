import 'package:sqflite/sqflite.dart';

class ScanPreferences {
  final int minDurationMs;
  final int minSizeBytes;

  const ScanPreferences({
    required this.minDurationMs,
    required this.minSizeBytes,
  });

  factory ScanPreferences.fromMap(Map<String, dynamic> map) {
    return ScanPreferences(
      minDurationMs: map['min_duration_ms'] as int? ?? 30000,
      minSizeBytes: map['min_size_bytes'] as int? ?? 50000,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'min_duration_ms': minDurationMs,
      'min_size_bytes': minSizeBytes,
      'updated_time': DateTime.now().toIso8601String(),
    };
  }
}

abstract class ScanPreferencesLocalDataSource {
  Future<ScanPreferences> getPreferences();
  Future<void> savePreferences({
    required int minDurationMs,
    required int minSizeBytes,
  });
}

class ScanPreferencesLocalDataSourceImpl
    implements ScanPreferencesLocalDataSource {
  ScanPreferencesLocalDataSourceImpl(this._db);

  final Database _db;

  @override
  Future<ScanPreferences> getPreferences() async {
    final rows = await _db.query(
      'scan_preferences',
      limit: 1,
    );

    if (rows.isEmpty) {
      final defaults = const ScanPreferences(
        minDurationMs: 30000,
        minSizeBytes: 50000,
      );
      await _db.insert(
        'scan_preferences',
        defaults.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return defaults;
    }

    return ScanPreferences.fromMap(rows.first);
  }

  @override
  Future<void> savePreferences({
    required int minDurationMs,
    required int minSizeBytes,
  }) async {
    await _db.insert(
      'scan_preferences',
      ScanPreferences(
        minDurationMs: minDurationMs,
        minSizeBytes: minSizeBytes,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

