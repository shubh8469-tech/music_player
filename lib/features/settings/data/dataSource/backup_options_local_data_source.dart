import 'package:sqflite/sqflite.dart';

class BackupOption {
  final String key;
  final String label;
  final bool isSelected;

  const BackupOption({
    required this.key,
    required this.label,
    required this.isSelected,
  });

  BackupOption copyWith({bool? isSelected}) => BackupOption(
        key: key,
        label: label,
        isSelected: isSelected ?? this.isSelected,
      );

  factory BackupOption.fromMap(Map<String, dynamic> map) {
    return BackupOption(
      key: map['key'] as String,
      label: map['label'] as String,
      isSelected: (map['is_selected'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'label': label,
      'is_selected': isSelected ? 1 : 0,
      'updated_time': DateTime.now().toIso8601String(),
    };
  }
}

abstract class BackupOptionsLocalDataSource {
  Future<List<BackupOption>> getAllOptions();
  Future<void> updateSelection(String key, bool isSelected);
}

class BackupOptionsLocalDataSourceImpl implements BackupOptionsLocalDataSource {
  BackupOptionsLocalDataSourceImpl(this._db);

  final Database _db;

  static const List<BackupOption> _defaultOptions = [
    BackupOption(key: 'tags', label: 'Tags', isSelected: true),
    BackupOption(key: 'covers', label: 'Covers', isSelected: true),
    BackupOption(key: 'playlists', label: 'Playlists', isSelected: true),
    BackupOption(key: 'sort_settings', label: 'Sort Settings', isSelected: true),
    BackupOption(
      key: 'scan_hide_settings',
      label: 'Scan and hide Settings',
      isSelected: true,
    ),
  ];

  @override
  Future<List<BackupOption>> getAllOptions() async {
    final rows = await _db.query(
      'backup_options',
      orderBy: 'rowid ASC',
    );

    if (rows.isEmpty) {
      await _seedDefaults();
      return _defaultOptions;
    }

    return rows.map(BackupOption.fromMap).toList();
  }

  @override
  Future<void> updateSelection(String key, bool isSelected) async {
    await _db.update(
      'backup_options',
      {
        'is_selected': isSelected ? 1 : 0,
        'updated_time': DateTime.now().toIso8601String(),
      },
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<void> _seedDefaults() async {
    final batch = _db.batch();
    for (final option in _defaultOptions) {
      batch.insert(
        'backup_options',
        option.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }
}

