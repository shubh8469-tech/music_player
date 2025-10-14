import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app state flags for navigation flow
class AppStateService {
  static const String _keyPermissionGranted = 'permission_granted';
  static const String _keySyncCompleted = 'sync_completed';

  final SharedPreferences _prefs;

  AppStateService(this._prefs);

  /// Check if storage permission has been granted
  Future<bool> isPermissionGranted() async {
    return _prefs.getBool(_keyPermissionGranted) ?? false;
  }

  /// Mark that storage permission has been granted
  Future<void> setPermissionGranted(bool value) async {
    await _prefs.setBool(_keyPermissionGranted, value);
  }

  /// Check if initial sync has been completed
  Future<bool> isSyncCompleted() async {
    return _prefs.getBool(_keySyncCompleted) ?? false;
  }

  /// Mark that initial sync has been completed
  Future<void> setSyncCompleted(bool value) async {
    await _prefs.setBool(_keySyncCompleted, value);
  }

  /// Reset all app state flags (useful for testing or resetting the app)
  Future<void> resetAppState() async {
    await _prefs.remove(_keyPermissionGranted);
    await _prefs.remove(_keySyncCompleted);
  }
}

