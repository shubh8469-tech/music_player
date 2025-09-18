import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/screens/tabs/library/songs/select_song_screen.dart';

import 'screens/Splash&Setup/permission.dart';
import 'screens/Splash&Setup/splashScreen.dart';
import 'screens/Splash&Setup/sync_progress.dart';
import 'screens/dashboard/dashboardScreen.dart';
import 'screens/play_song/playing_song_screen.dart';
import 'screens/tabs/home/homeScreen.dart';
import 'screens/tabs/library/libraryScreen.dart';
import 'screens/tabs/songs_setting/edit_song_details_screen.dart';

enum AppRouteName { splash, permission, sync, dashboard, playing, home, library, editSongDetails, selectSong }

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    GoRoute(name: AppRouteName.splash.name, path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(name: AppRouteName.permission.name, path: '/permission', builder: (context, state) => const PermissionPage()),
    GoRoute(name: AppRouteName.sync.name, path: '/sync', builder: (context, state) => const SyncProgress()),
    GoRoute(
      name: AppRouteName.dashboard.name,
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
      routes: [
        GoRoute(name: AppRouteName.home.name, path: 'home', builder: (context, state) => const HomeScreen()),
        GoRoute(name: AppRouteName.library.name, path: 'library', builder: (context, state) => const LibraryScreen()),

        GoRoute(
          path: 'playing',
          pageBuilder: (context, state) {
            final args = state.extra as PlayingSongArgs;

            return CustomTransitionPage(
              key: state.pageKey,
              child: PlayingSongScreen(
                songs: args.songs,
              ),
              transitionDuration: const Duration(milliseconds: 500),
              reverseTransitionDuration: const Duration(milliseconds: 500),

              // your existing screen
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0); // from bottom
                const end = Offset.zero; // to normal position
                const curve = Curves.easeInOut;

                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                final offsetAnimation = animation.drive(tween);

                return SlideTransition(position: offsetAnimation, child: child);
              },
            );
          },
        ),
        // GoRoute(
        //   name: AppRouteName.playing.name,
        //   path: 'playing',
        //   builder: (context, state) => const PlayingSongScreen(),
        // ),
        GoRoute(name: AppRouteName.editSongDetails.name, path: 'edit-song', builder: (context, state) => const EditSongDetailsScreen()),
        GoRoute(name: AppRouteName.selectSong.name, path: 'select-song', builder: (context, state) => const SelectSongScreen()),
      ],
    ),
  ],
);
