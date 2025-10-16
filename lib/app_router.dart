import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/screens/tabs/library/songs/select_song_screen.dart';
import 'package:music_app/screens/tabs/library/songs/add_songs_screen.dart';
import 'package:music_app/screens/tabs/library/playlists/create_playlist_screen.dart';
import 'package:music_app/screens/tabs/library/playlists/playlist_detail_screen.dart';
import 'package:music_app/screens/tabs/library/playlists/select_playlist_screen.dart';
import 'package:music_app/screens/tabs/library/folders/folder_detail_screen.dart';
import 'package:music_app/screens/tabs/library/folders/select_folder_screen.dart';
import 'package:music_app/screens/tabs/library/artist/artist_detail_screen.dart';
import 'package:music_app/screens/tabs/library/albums/album_detail_screen.dart';

import 'screens/Splash&Setup/permission.dart';
import 'screens/Splash&Setup/splashScreen.dart';
import 'screens/Splash&Setup/sync_progress.dart';
import 'screens/dashboard/dashboardScreen.dart';
import 'screens/play_song/playing_song_screen.dart';
import 'screens/tabs/home/homeScreen.dart';
import 'screens/tabs/library/libraryScreen.dart';
import 'screens/tabs/songs_setting/edit_song_details_screen.dart';

enum AppRouteName {
  splash,
  permission,
  sync,
  dashboard,
  playing,
  home,
  library,
  editSongDetails,
  selectSong,
  addSongs,
  createPlaylist,
  selectPlaylist,
  playlistDetail,
  folderDetail,
  selectFolder,
  artistDetail,
  albumDetail,
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      name: AppRouteName.splash.name,
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      name: AppRouteName.permission.name,
      path: '/permission',
      builder: (context, state) => const PermissionPage(),
    ),
    GoRoute(
      name: AppRouteName.sync.name,
      path: '/sync',
      builder: (context, state) => const SyncProgress(),
    ),
    GoRoute(
      name: AppRouteName.dashboard.name,
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
      routes: [
        GoRoute(
          name: AppRouteName.home.name,
          path: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          name: AppRouteName.library.name,
          path: 'library',
          builder: (context, state) => const LibraryScreen(),
        ),

        GoRoute(
          path: 'playing',
          pageBuilder: (context, state) {
            final args = state.extra as PlayingSongArgs;

            return CustomTransitionPage(
              key: state.pageKey,
              child: PlayingSongScreen(songs: args.songs),
              transitionDuration: const Duration(milliseconds: 500),
              reverseTransitionDuration: const Duration(milliseconds: 500),

              // your existing screen
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0); // from bottom
                    const end = Offset.zero; // to normal position
                    const curve = Curves.easeInOut;

                    final tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: curve));
                    final offsetAnimation = animation.drive(tween);

                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
            );
          },
        ),
        GoRoute(
          name: AppRouteName.editSongDetails.name,
          path: 'edit-song',
          builder: (context, state) => const EditSongDetailsScreen(),
        ),
        GoRoute(
          name: AppRouteName.selectSong.name,
          path: 'select-song',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            if (args != null) {
              return SelectSongScreen(
                playlist: args['playlist'],
                playlistSongs: args['songs'],
                isSystemPlaylist: args['isSystemPlaylist'],
              );
            }
            return const SelectSongScreen();
          },
        ),
        GoRoute(
          name: AppRouteName.addSongs.name,
          path: 'add-songs',
          builder: (context, state) {
            final playlist = state.extra as dynamic;
            return AddSongsScreen(playlist: playlist);
          },
        ),
        GoRoute(
          name: AppRouteName.createPlaylist.name,
          path: 'create-playlist',
          builder: (context, state) => const CreatePlaylistScreen(),
        ),
        GoRoute(
          name: AppRouteName.selectPlaylist.name,
          path: 'select-playlist',
          builder: (context, state) => const SelectPlaylistScreen(),
        ),
        GoRoute(
          name: AppRouteName.playlistDetail.name,
          path: 'playlist-detail',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            final playlist = args['playlist'] as dynamic;
            final assetIcon = args['assetIcon'] as String;
            final colors = args['colors'] as List<Color>;
            return PlaylistDetailScreen(
              playlist: playlist,
              assetIcon: assetIcon,
              colors: colors,
            );
          },
        ),
        GoRoute(
          name: AppRouteName.folderDetail.name,
          path: 'folder-detail',
          builder: (context, state) {
            final folder = state.extra as dynamic;
            return FolderDetailScreen(folder: folder);
          },
        ),
        GoRoute(
          name: AppRouteName.selectFolder.name,
          path: 'select-folder',
          builder: (context, state) => const SelectFolderScreen(),
        ),
        GoRoute(
          name: AppRouteName.artistDetail.name,
          path: 'artist-detail',
          builder: (context, state) {
            final artist = state.extra as dynamic;
            return ArtistDetailScreen(artist: artist);
          },
        ),
        GoRoute(
          name: AppRouteName.albumDetail.name,
          path: 'album-detail',
          builder: (context, state) {
            final album = state.extra as dynamic;
            return AlbumDetailScreen(album: album);
          },
        ),
      ],
    ),
  ],
);
