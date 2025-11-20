import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:music_app/features/playlists/bloc/playlist_bloc.dart';
import 'package:music_app/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:music_app/features/folders/bloc/folder_bloc.dart';
import 'package:music_app/features/folders/domain/usecases/get_all_folders.dart';
import 'package:music_app/features/folders/domain/usecases/get_folder_songs.dart';
import 'package:music_app/features/folders/domain/usecases/delete_folder.dart';
import 'package:music_app/features/artists/bloc/artist_bloc.dart';
import 'package:music_app/features/artists/domain/usecases/get_all_artists.dart';
import 'package:music_app/features/artists/domain/usecases/get_artist_songs.dart';
import 'package:music_app/features/artists/domain/usecases/update_artist_cover.dart';
import 'package:music_app/features/albums/bloc/album_bloc.dart';
import 'package:music_app/features/albums/domain/usecases/get_all_albums.dart';
import 'package:music_app/features/albums/domain/usecases/get_album_songs.dart';
import 'package:music_app/features/albums/domain/usecases/get_albums_by_artist.dart';
import 'package:music_app/features/albums/domain/usecases/update_album_cover.dart';
import 'Blocs/languageBloc/language_bloc.dart';
import 'app_router.dart';
import 'core/di/injection.dart';
import 'features/songs/bloc/songs_bloc.dart';
import 'features/songs/data/dataSource/song_local_data_source.dart';
import 'l10n/l10n.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:metadata_god/metadata_god.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MetadataGod for iOS metadata extraction
  await MetadataGod.initialize();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.music_app.playback',
    androidNotificationChannelName: 'Music Playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );

  if (Platform.isAndroid) {
    final notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      await Permission.notification.request();
    }
  }

  // Configure audio session for proper media routing & background behavior
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  await initInjections();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => LanguageBloc()),
            BlocProvider<PlaylistBloc>(
              create: (_) =>
                  PlaylistBloc(locator())
                    ..add(const PlaylistEvent.fetchAllPlaylists()),
            ),
            BlocProvider<FolderBloc>(
              create: (_) => FolderBloc(
                getAllFolders: locator<GetAllFolders>(),
                getFolderSongs: locator<GetFolderSongs>(),
                deleteFolder: locator<DeleteFolder>(),
              ),
            ),
            BlocProvider<ArtistBloc>(
              create: (_) => ArtistBloc(
                getAllArtists: locator<GetAllArtists>(),
                getArtistSongs: locator<GetArtistSongs>(),
                updateArtistCoverUseCase: locator<UpdateArtistCover>(),
              ),
            ),
            BlocProvider<AlbumBloc>(
              create: (_) => AlbumBloc(
                getAllAlbums: locator<GetAllAlbums>(),
                getAlbumSongs: locator<GetAlbumSongs>(),
                getAlbumsByArtist: locator<GetAlbumsByArtist>(),
                updateAlbumCoverUseCase: locator<UpdateAlbumCover>(),
              ),
            ),
            BlocProvider<SongsBloc>(
              create: (context) => SongsBloc(
                locator<SongLocalDataSource>(),
                locator<PlaylistRepository>(),
                onLibraryRefresh: () {
                  context.read<PlaylistBloc>().add(
                        const PlaylistEvent.fetchAllPlaylists(),
                      );
                  context.read<FolderBloc>().add(
                        const FolderEvent.fetchAllFolders(),
                      );
                  context.read<ArtistBloc>().add(
                        const ArtistEvent.fetchAllArtists(),
                      );
                  context.read<AlbumBloc>().add(
                        const AlbumEvent.fetchAllAlbums(),
                      );
                },
              )..add(const SongsEvent.getAllSongs()),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            child: const MyApp(),
          ),
        );
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, state) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          supportedLocales: S.supportedLocales,
          locale: state.locale,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: appRouter,
        );
      },
    );
  }
}
