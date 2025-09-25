import 'package:flutter/material.dart';
import 'package:music_app/screens/play_song/queue_screen.dart';
import 'package:music_app/screens/play_song/select_queue_screen.dart';

/// Helper class to navigate to queue-related screens
class QueueNavigationHelper {
  /// Navigate to the playing queue screen
  static void navigateToQueueScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const QueueScreen()));
  }

  /// Navigate to the select queue screen
  static void navigateToSelectQueueScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SelectQueueScreen()));
  }

  /// Show queue options bottom sheet
  static void showQueueOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: const Text('Playing Queue'),
              onTap: () {
                Navigator.of(context).pop();
                navigateToQueueScreen(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_to_queue),
              title: const Text('Select Queue'),
              onTap: () {
                Navigator.of(context).pop();
                navigateToSelectQueueScreen(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
