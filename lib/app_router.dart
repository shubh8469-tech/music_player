import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/screens/equilizer/equilizer_screen.dart';
import 'package:music_app/screens/settings/backup_restore_page.dart';
import 'package:music_app/screens/settings/settings.dart';
import 'package:music_app/screens/tabs/library/songs/select_song_screen.dart';
import 'package:music_app/screens/tabs/library/songs/add_songs_screen.dart';
import 'package:music_app/screens/tabs/library/playlists/create_playlist_screen.dart';
import 'package:music_app/screens/tabs/library/playlists/playlist_detail_screen.dart';
import 'package:music_app/screens/tabs/library/playlists/select_playlist_screen.dart';
import 'package:music_app/screens/tabs/library/hidden_music/hidden_music_screen.dart';
import 'package:music_app/screens/tabs/library/folders/folder_detail_screen.dart';
import 'package:music_app/screens/tabs/library/folders/select_folder_screen.dart';
import 'package:music_app/screens/tabs/library/artist/artist_detail_screen.dart';
import 'package:music_app/screens/tabs/library/artist/select_artist_screen.dart';
import 'package:music_app/screens/tabs/library/albums/album_detail_screen.dart';
import 'package:music_app/screens/tabs/library/albums/select_album_screen.dart';
import 'package:music_app/screens/tabs/library/genres/genre_detail_screen.dart';
import 'package:music_app/screens/tabs/library/genres/select_genre_screen.dart';

import 'package:music_app/features/songs/data/models/song_model.dart';
import 'screens/Splash&Setup/permission.dart';
import 'screens/Splash&Setup/splashScreen.dart';
import 'screens/Splash&Setup/sync_progress.dart';
import 'screens/dashboard/dashboardScreen.dart';
import 'screens/play_song/playing_song_screen.dart';
import 'screens/tabs/home/homeScreen.dart';
import 'screens/tabs/home/import_songs_screen.dart';
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
