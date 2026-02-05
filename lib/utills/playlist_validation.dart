/// Validation utilities for playlist names.
class PlaylistValidation {
  PlaylistValidation._();

  /// Maximum allowed length for a playlist name.
  static const int maxNameLength = 100;

  /// Form field validator for playlist name.
  /// Use with TextFormField's validator parameter.
  static String? validatePlaylistName(String? value) {
    if (value == null) {
      return 'Please enter a playlist name';
    }

    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'Please enter a playlist name';
    }

    if (trimmed.length > maxNameLength) {
      return 'Playlist name must be at most $maxNameLength characters';
    }

    return null;
  }
}
