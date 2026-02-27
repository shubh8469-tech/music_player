import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:music_app/features/playlists/presentation/bloc/playlist_bloc.dart';
import 'package:music_app/features/playlists/domain/repositories/playlist_repository.dart';
import 'package:music_app/features/folders/presentation/bloc/folder_bloc.dart';
import 'package:music_app/features/folders/domain/usecases/get_all_folders.dart';
import 'package:music_app/features/folders/domain/usecases/get_folder_songs.dart';
import 'package:music_app/features/folders/domain/usecases/delete_folder.dart';
import 'package:music_app/features/artists/presentation/bloc/artist_bloc.dart';
import 'package:music_app/features/artists/domain/usecases/get_all_artists.dart';
import 'package:music_app/features/artists/domain/usecases/get_artist_songs.dart';
import 'package:music_app/features/artists/domain/usecases/update_artist_cover.dart';
import 'package:music_app/features/artists/domain/usecases/update_artist_name.dart';
import 'package:music_app/features/albums/presentation/bloc/album_bloc.dart';
import 'package:music_app/features/albums/domain/usecases/get_all_albums.dart';
import 'package:music_app/features/albums/domain/usecases/get_album_songs.dart';
import 'package:music_app/features/albums/domain/usecases/get_albums_by_artist.dart';
import 'package:music_app/features/albums/domain/usecases/update_album_cover.dart';
import 'package:music_app/features/albums/domain/usecases/update_album_name.dart';
import 'package:music_app/features/genres/presentation/bloc/genre_bloc.dart';
import 'package:music_app/features/genres/domain/usecases/get_all_genres.dart';
import 'package:music_app/features/genres/domain/usecases/get_genre_songs.dart';
import 'package:music_app/features/genres/domain/usecases/update_genre_cover.dart';
import 'package:music_app/features/genres/domain/usecases/update_genre_name.dart';
import 'package:music_app/core/screens/common/commonTapProvider.dart';
import 'package:provider/provider.dart';
import 'package:music_app/app_router.dart';
import 'package:music_app/features/music_player/presentation/bloc/music_player_bloc.dart';
import 'package:music_app/features/music_player/domain/repositories/playback_repository.dart';
import 'package:music_app/features/music_player/domain/usecases/get_playback_state_stream.dart';
import 'package:music_app/features/music_player/data/services/music_player_service.dart';
import 'core/di/injection.dart';
import 'features/songs/presentation/bloc/songs_bloc.dart';
import 'features/songs/data/datasources/song_local_data_source.dart';
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
                updateArtistNameUseCase: locator<UpdateArtistName>(),
              ),
            ),
            BlocProvider<AlbumBloc>(
              create: (_) => AlbumBloc(
                getAllAlbums: locator<GetAllAlbums>(),
                getAlbumSongs: locator<GetAlbumSongs>(),
                getAlbumsByArtist: locator<GetAlbumsByArtist>(),
                updateAlbumCoverUseCase: locator<UpdateAlbumCover>(),
                updateAlbumNameUseCase: locator<UpdateAlbumName>(),
              ),
            ),
            BlocProvider<GenreBloc>(
              create: (_) => GenreBloc(
                getAllGenres: locator<GetAllGenres>(),
                getGenreSongs: locator<GetGenreSongs>(),
                updateGenreCoverUseCase: locator<UpdateGenreCover>(),
                updateGenreNameUseCase: locator<UpdateGenreName>(),
              ),
            ),
            BlocProvider<MusicPlayerBloc>(
              create: (_) => MusicPlayerBloc(
                musicService: locator<MusicPlayerService>(),
                getPlaybackStateStream: locator<GetPlaybackStateStream>(),
                playbackRepository: locator<PlaybackRepository>(),
              ),
            ),
            BlocProvider<SongsBloc>(
              create: (context) => SongsBloc(
                locator<SongLocalDataSource>(),
                locator<PlaylistRepository>(),
                onLibraryRefresh: () {
                  log('Library refresh triggered from SongsBloc');
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
                  context.read<GenreBloc>().add(
                    const GenreEvent.fetchAllGenres(),
                  );
                },
              )..add(const SongsEvent.getAllSongs()),
            ),
            ChangeNotifierProvider(create: (_) => HoldTheTapFor()),
          ],
          child: BlocListener<SongsBloc, SongsState>(
            listener: (context, state) {
              state.maybeWhen(
                loaded: (songs) {
                  context.read<MusicPlayerBloc>().syncPlaylistWithUpdatedSongsFromModels(songs);
                },
                orElse: () {},
              );
            },
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              child: const MyApp(),
            ),
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
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
