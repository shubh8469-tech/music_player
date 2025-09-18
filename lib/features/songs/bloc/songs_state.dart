part of 'songs_bloc.dart';

@freezed
class SongsState with _$SongsState {
  const factory SongsState.initial() = _Initial;
  const factory SongsState.loading() = _Loading;
  const factory SongsState.loaded(List<SongsModel> songs) = _Loaded;
  const factory SongsState.error(String message) = _Error;
}
