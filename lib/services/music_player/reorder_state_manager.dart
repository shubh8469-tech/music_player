import 'dart:async';

import '../../features/songs/data/models/song_model.dart';

/// Manages the reorder cache state to ensure correct currentSongId during
/// queue reordering (when list updates before player index catches up).
class ReorderStateManager {
  int? _reorderCurrentSongId;
  int? _reorderTargetIndex;
  bool _reorderListUpdated = false;
  DateTime? _reorderListUpdatedAt;
  Timer? _reorderClearTimer;

  static const _clearDelayMs = 100;

  void clear() {
    _reorderClearTimer?.cancel();
    _reorderClearTimer = null;
    _reorderCurrentSongId = null;
    _reorderTargetIndex = null;
    _reorderListUpdated = false;
    _reorderListUpdatedAt = null;
  }

  /// New index of the item that was at [currentIndex] after reorder:
  /// remove at [oldIndex], insert at [newIndex].
  static int newCurrentIndexAfterReorder(
    int oldIndex,
    int newIndex,
    int currentIndex,
  ) {
    final c = oldIndex < currentIndex ? currentIndex - 1 : currentIndex;
    return c + (newIndex <= c ? 1 : 0);
  }

  /// Call before updating UI list on reorder so currentSongId is correct on first rebuild.
  void prepareReorderForCurrentSong(
    int oldIndex,
    int newIndex,
    int currentIndex,
    List<SongsModel> songs,
  ) {
    _reorderListUpdated = false;
    _reorderListUpdatedAt = null;
    _reorderClearTimer?.cancel();

    if (currentIndex >= 0 && currentIndex < songs.length) {
      if (currentIndex == oldIndex) {
        _reorderCurrentSongId = songs[oldIndex].id;
        _reorderTargetIndex = newIndex;
      } else {
        _reorderCurrentSongId = songs[currentIndex].id;
        _reorderTargetIndex = newCurrentIndexAfterReorder(
          oldIndex,
          newIndex,
          currentIndex,
        );
      }
    } else {
      _reorderCurrentSongId = null;
      _reorderTargetIndex = null;
    }
  }

  /// Compute reorder cache for swapReorderSongInQueue.
  void setReorderCache(
    int oldIndex,
    int newIndex,
    int currentIndex,
    List<SongsModel> songs,
  ) {
    _reorderListUpdated = false;
    _reorderListUpdatedAt = null;
    _reorderClearTimer?.cancel();

    if (currentIndex >= 0 && currentIndex < songs.length) {
      if (currentIndex == oldIndex) {
        _reorderCurrentSongId = songs[oldIndex].id;
        _reorderTargetIndex = newIndex;
      } else {
        _reorderCurrentSongId = songs[currentIndex].id;
        _reorderTargetIndex = newCurrentIndexAfterReorder(
          oldIndex,
          newIndex,
          currentIndex,
        );
      }
    } else {
      _reorderCurrentSongId = null;
      _reorderTargetIndex = null;
    }
  }

  void markListUpdated() {
    _reorderListUpdated = true;
    _reorderListUpdatedAt = DateTime.now();
    _scheduleClear();
  }

  void _scheduleClear() {
    _reorderClearTimer?.cancel();
    _reorderClearTimer = Timer(const Duration(milliseconds: 350), () {
      clear();
    });
  }

  /// Returns the current song ID, considering reorder cache.
  /// Returns null if cache should be cleared (after delay).
  int? getCurrentSongId({
    required int currentIndex,
    required List<SongsModel> songs,
  }) {
    if (_reorderCurrentSongId != null && _reorderTargetIndex != null) {
      if (currentIndex == _reorderTargetIndex &&
          _reorderListUpdated &&
          _reorderListUpdatedAt != null) {
        final elapsed = DateTime.now().difference(_reorderListUpdatedAt!);
        if (elapsed.inMilliseconds >= _clearDelayMs) {
          clear();
        } else {
          return _reorderCurrentSongId;
        }
      } else {
        return _reorderCurrentSongId;
      }
    }

    if (currentIndex >= 0 && currentIndex < songs.length) {
      return songs[currentIndex].id;
    }
    return null;
  }
}
