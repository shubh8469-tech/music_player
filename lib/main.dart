import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/screens/splashScreen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'GlobalBloc/languageBloc/language_bloc.dart';
import 'l10n/l10n.dart';

void main() {
  runApp(
    MultiBlocProvider(
        providers:[
          BlocProvider(create: (context) => LanguageBloc()),
        ],
        child: const MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: SplashScreen(),
    );
  }
}
