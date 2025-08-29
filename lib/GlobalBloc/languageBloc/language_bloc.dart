import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'language_event.dart';
part 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  LanguageBloc() : super(LanguageState.initial()) {
    on<LanguageEvent>((event, emit) {

      on<ChangeLocale>((event, emit) {
        emit(LanguageState(locale: event.locale));
      });

    });
  }
}
