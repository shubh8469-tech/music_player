import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/screens/Splash&Setup/permission.dart';
import 'package:music_app/screens/Splash&Setup/splashScreen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:music_app/screens/dashboard/dashboardScreen.dart';
import 'GlobalBloc/languageBloc/language_bloc.dart';
import 'l10n/l10n.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(
    ScreenUtilInit(
      // designSize should match your designer's artboard (example below).
      designSize: const Size(378, 812),
      minTextAdapt: true, // adapt text for small screens / accessibility
      splitScreenMode: true, // support split screen
      builder: (context, child) {
        // Provide your Bloc(s) after ScreenUtilInit so widgets can use .sp/.w in theme if needed
        return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => LanguageBloc()),
            ],
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              child: const MyApp(),
            )
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
        return MaterialApp(
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
          home: DashboardScreen(),
        );
      },
    );
  }
}
