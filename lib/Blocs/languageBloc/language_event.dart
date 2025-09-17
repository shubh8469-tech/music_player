part of 'language_bloc.dart';

@immutable
sealed class LanguageEvent {}

class ChangeLocale extends LanguageEvent {
  final Locale locale;
  ChangeLocale(this.locale);
}
