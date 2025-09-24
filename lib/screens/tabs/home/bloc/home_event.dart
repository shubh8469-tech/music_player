part of 'home_bloc.dart';

@freezed
class HomeEvent with _$HomeEvent {
  const factory HomeEvent.loadData() = _LoadData;
  const factory HomeEvent.refreshData() = _RefreshData;
  const factory HomeEvent.songPlayed() = _SongPlayed;
}
