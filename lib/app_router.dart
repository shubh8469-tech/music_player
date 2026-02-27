import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/music_player/presentation/screens/equilizer/equilizer_screen.dart';
import 'package:music_app/features/music_player/presentation/screens/play_song/queue_screen.dart';
import 'package:music_app/features/settings/presentation/screens/backup_restore_page.dart';
import 'package:music_app/features/settings/presentation/screens/settings.dart';
import 'package:music_app/features/settings/presentation/screens/scan_music_screen.dart';
import 'package:music_app/features/settings/presentation/screens/scan_select_folders_screen.dart';
import 'package:music_app/features/settings/presentation/screens/scanning_progress_screen.dart';
import 'package:music_app/features/settings/presentation/screens/scan_complete_screen.dart';
import 'package:music_app/features/songs/presentation/screens/select_song_screen.dart';
import 'package:music_app/features/songs/presentation/screens/add_songs_screen.dart';
import 'package:music_app/features/playlists/presentation/screens/playlist_detail_screen.dart';
import 'package:music_app/features/playlists/presentation/screens/select_playlist_screen.dart';
import 'package:music_app/features/folders/presentation/screens/hidden_music_screen.dart';
import 'package:music_app/features/folders/presentation/screens/folder_detail_screen.dart';
import 'package:music_app/features/folders/presentation/screens/select_folder_screen.dart';
import 'package:music_app/features/artists/presentation/screens/artist_detail_screen.dart';
import 'package:music_app/features/artists/presentation/screens/select_artist_screen.dart';
import 'package:music_app/features/albums/presentation/screens/album_detail_screen.dart';
import 'package:music_app/features/albums/presentation/screens/select_album_screen.dart';
import 'package:music_app/features/genres/presentation/screens/genre_detail_screen.dart';
import 'package:music_app/features/genres/presentation/screens/select_genre_screen.dart';

import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/features/music_player/presentation/screens/play_song/playing_song_screen.dart';
import 'package:music_app/features/songs/presentation/screens/edit_song/edit_song_details_screen.dart';

import 'features/app_shell/presentation/screens/dashboard/dashboardScreen.dart';
import 'features/app_shell/presentation/screens/splash_setup/permission.dart';
import 'features/app_shell/presentation/screens/splash_setup/splashScreen.dart';
import 'features/app_shell/presentation/screens/splash_setup/sync_progress.dart';
import 'features/app_shell/presentation/screens/tabs/home/homeScreen.dart';
import 'features/app_shell/presentation/screens/tabs/home/import_songs_screen.dart';
import 'features/app_shell/presentation/screens/tabs/library/libraryScreen.dart';

enum AppRouteName {
  splash,
  permission,
  sync,
  dashboard,
  playing,
  queue,
  home,
  library,
  importSongs,
  editSongDetails,
  selectSong,
  addSongs,
  createPlaylist,
  selectPlaylist,
  playlistDetail,
  folderDetail,
  selectFolder,
  hiddenMusic,
  artistDetail,
  selectArtist,
  albumDetail,
  selectAlbum,
  genreDetail,
  selectGenre,
  equalizer,
  settings,
  backupRestore,
  scanMusic,
  scanSelectFolders,
  scanningProgress,
  scanComplete,
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
          name: AppRouteName.settings.name,
          path: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          name: AppRouteName.backupRestore.name,
          path: 'backup-restore',
          builder: (context, state) => const BackupRestorePage(),
        ),
        GoRoute(
          name: AppRouteName.scanMusic.name,
          path: 'scan-music',
          builder: (context, state) => const ScanMusicScreen(),
        ),
        GoRoute(
          name: AppRouteName.scanSelectFolders.name,
          path: 'scan-select-folders',
          builder: (context, state) => const ScanSelectFoldersScreen(),
        ),
        GoRoute(
          name: AppRouteName.scanningProgress.name,
          path: 'scanning-progress',
          builder: (context, state) => const ScanningProgressScreen(),
        ),
        GoRoute(
          name: AppRouteName.scanComplete.name,
          path: 'scan-complete',
          builder: (context, state) => const ScanCompleteScreen(),
        ),
        GoRoute(
          name: AppRouteName.library.name,
          path: 'library',
          builder: (context, state) => const LibraryScreen(),
        ),
        GoRoute(
          name: AppRouteName.hiddenMusic.name,
          path: 'hidden-music',
          builder: (context, state) => const HiddenMusicScreen(),
        ),
        GoRoute(
          name: AppRouteName.importSongs.name,
          path: 'import-songs',
          builder: (context, state) => const ImportSongsScreen(),
        ),
        GoRoute(
          name: 'queue',
          path: 'queue',
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const QueueScreen(),
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
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
          path: 'playing',
          pageBuilder: (context, state) {
            final args = state.extra as PlayingSongArgs;

            return CustomTransitionPage(
              key: state.pageKey,
              child: PlayingSongScreen(songs: args.songs),
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),

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
          builder: (context, state) {
            final song = state.extra as SongsModel?;
            if (song == null) {
              return const Scaffold(
                body: Center(child: Text('No song selected for editing')),
              );
            }
            return EditSongDetailsScreen(song: song);
          },
        ),
        GoRoute(
          name: AppRouteName.selectSong.name,
          path: 'select-song',
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>?;
            if (args != null) {
              return SelectSongScreen(
                playlist: args['playlist'],
                album: args['album'],
                artist: args['artist'],
                genre: args['genre'],
                folder: args['folder'],
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
        // GoRoute(
        //   name: AppRouteName.createPlaylist.name,
        //   path: 'create-playlist',
        //   builder: (context, state) => const CreatePlaylistScreen(),
        // ),
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
          name: AppRouteName.selectArtist.name,
          path: 'select-artist',
          builder: (context, state) => const SelectArtistScreen(),
        ),
        GoRoute(
          name: AppRouteName.albumDetail.name,
          path: 'album-detail',
          builder: (context, state) {
            final album = state.extra as dynamic;
            return AlbumDetailScreen(album: album);
          },
        ),
        GoRoute(
          name: AppRouteName.selectAlbum.name,
          path: 'select-albums',
          builder: (context, state) => const SelectAlbumScreen(),
        ),
        GoRoute(
          name: AppRouteName.genreDetail.name,
          path: 'genre-detail',
          builder: (context, state) {
            final genre = state.extra as dynamic;
            return GenreDetailScreen(genre: genre);
          },
        ),
        GoRoute(
          name: AppRouteName.selectGenre.name,
          path: 'select-genre',
          builder: (context, state) => const SelectGenreScreen(),
        ),
        GoRoute(
          name: AppRouteName.equalizer.name,
          path: 'equalizer',
          builder: (context, state) => const EqualizerScreen(),
        ),
      ],
    ),
  ],
);
