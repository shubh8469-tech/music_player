import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:music_app/features/playlists/bloc/playlist_bloc.dart';
import 'Blocs/languageBloc/language_bloc.dart';
import 'app_router.dart';
import 'core/di/injection.dart';
import 'features/songs/bloc/songs_bloc.dart';
import 'l10n/l10n.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(
    ScreenUtilInit(
      designSize: const Size(378, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => LanguageBloc()),
            BlocProvider<SongsBloc>(
              create: (_) =>
                  SongsBloc(locator())..add(const SongsEvent.getAllSongs()),
            ),
            BlocProvider<PlaylistBloc>(
              create: (_) =>
                  PlaylistBloc(locator())
                    ..add(const PlaylistEvent.fetchAllPlaylists()),
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
