part of 'language_bloc.dart';


class LanguageState {
  final Locale locale;
  const LanguageState({required this.locale});

  /// default initial state: English
  factory LanguageState.initial() => const LanguageState(locale: Locale('en'));
}