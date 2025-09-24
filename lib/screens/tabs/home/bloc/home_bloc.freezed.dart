// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeEvent()';
}


}

/// @nodoc
class $HomeEventCopyWith<$Res>  {
$HomeEventCopyWith(HomeEvent _, $Res Function(HomeEvent) __);
}


/// Adds pattern-matching-related methods to [HomeEvent].
extension HomeEventPatterns on HomeEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadData value)?  loadData,TResult Function( _RefreshData value)?  refreshData,TResult Function( _SongPlayed value)?  songPlayed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadData() when loadData != null:
return loadData(_that);case _RefreshData() when refreshData != null:
return refreshData(_that);case _SongPlayed() when songPlayed != null:
return songPlayed(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadData value)  loadData,required TResult Function( _RefreshData value)  refreshData,required TResult Function( _SongPlayed value)  songPlayed,}){
final _that = this;
switch (_that) {
case _LoadData():
return loadData(_that);case _RefreshData():
return refreshData(_that);case _SongPlayed():
return songPlayed(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadData value)?  loadData,TResult? Function( _RefreshData value)?  refreshData,TResult? Function( _SongPlayed value)?  songPlayed,}){
final _that = this;
switch (_that) {
case _LoadData() when loadData != null:
return loadData(_that);case _RefreshData() when refreshData != null:
return refreshData(_that);case _SongPlayed() when songPlayed != null:
return songPlayed(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadData,TResult Function()?  refreshData,TResult Function()?  songPlayed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadData() when loadData != null:
return loadData();case _RefreshData() when refreshData != null:
return refreshData();case _SongPlayed() when songPlayed != null:
return songPlayed();case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadData,required TResult Function()  refreshData,required TResult Function()  songPlayed,}) {final _that = this;
switch (_that) {
case _LoadData():
return loadData();case _RefreshData():
return refreshData();case _SongPlayed():
return songPlayed();case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadData,TResult? Function()?  refreshData,TResult? Function()?  songPlayed,}) {final _that = this;
switch (_that) {
case _LoadData() when loadData != null:
return loadData();case _RefreshData() when refreshData != null:
return refreshData();case _SongPlayed() when songPlayed != null:
return songPlayed();case _:
  return null;

}
}

}

/// @nodoc


class _LoadData implements HomeEvent {
  const _LoadData();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadData);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeEvent.loadData()';
}


}




/// @nodoc


class _RefreshData implements HomeEvent {
  const _RefreshData();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RefreshData);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeEvent.refreshData()';
}


}




/// @nodoc


class _SongPlayed implements HomeEvent {
  const _SongPlayed();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SongPlayed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeEvent.songPlayed()';
}


}




/// @nodoc
mixin _$HomeState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState()';
}


}

/// @nodoc
class $HomeStateCopyWith<$Res>  {
$HomeStateCopyWith(HomeState _, $Res Function(HomeState) __);
}


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _Error():
return error(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Error() when error != null:
return error(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<SongsModel> recentlyPlayedSongs,  List<Playlist> userPlaylists,  List<Playlist> systemPlaylists)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.recentlyPlayedSongs,_that.userPlaylists,_that.systemPlaylists);case _Error() when error != null:
return error(_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<SongsModel> recentlyPlayedSongs,  List<Playlist> userPlaylists,  List<Playlist> systemPlaylists)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.recentlyPlayedSongs,_that.userPlaylists,_that.systemPlaylists);case _Error():
return error(_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<SongsModel> recentlyPlayedSongs,  List<Playlist> userPlaylists,  List<Playlist> systemPlaylists)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.recentlyPlayedSongs,_that.userPlaylists,_that.systemPlaylists);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements HomeState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.initial()';
}


}




/// @nodoc


class _Loading implements HomeState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'HomeState.loading()';
}


}




/// @nodoc


class _Loaded implements HomeState {
  const _Loaded({required final  List<SongsModel> recentlyPlayedSongs, required final  List<Playlist> userPlaylists, required final  List<Playlist> systemPlaylists}): _recentlyPlayedSongs = recentlyPlayedSongs,_userPlaylists = userPlaylists,_systemPlaylists = systemPlaylists;
  

 final  List<SongsModel> _recentlyPlayedSongs;
 List<SongsModel> get recentlyPlayedSongs {
  if (_recentlyPlayedSongs is EqualUnmodifiableListView) return _recentlyPlayedSongs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentlyPlayedSongs);
}

 final  List<Playlist> _userPlaylists;
 List<Playlist> get userPlaylists {
  if (_userPlaylists is EqualUnmodifiableListView) return _userPlaylists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_userPlaylists);
}

 final  List<Playlist> _systemPlaylists;
 List<Playlist> get systemPlaylists {
  if (_systemPlaylists is EqualUnmodifiableListView) return _systemPlaylists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_systemPlaylists);
}


/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._recentlyPlayedSongs, _recentlyPlayedSongs)&&const DeepCollectionEquality().equals(other._userPlaylists, _userPlaylists)&&const DeepCollectionEquality().equals(other._systemPlaylists, _systemPlaylists));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_recentlyPlayedSongs),const DeepCollectionEquality().hash(_userPlaylists),const DeepCollectionEquality().hash(_systemPlaylists));

@override
String toString() {
  return 'HomeState.loaded(recentlyPlayedSongs: $recentlyPlayedSongs, userPlaylists: $userPlaylists, systemPlaylists: $systemPlaylists)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<SongsModel> recentlyPlayedSongs, List<Playlist> userPlaylists, List<Playlist> systemPlaylists
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? recentlyPlayedSongs = null,Object? userPlaylists = null,Object? systemPlaylists = null,}) {
  return _then(_Loaded(
recentlyPlayedSongs: null == recentlyPlayedSongs ? _self._recentlyPlayedSongs : recentlyPlayedSongs // ignore: cast_nullable_to_non_nullable
as List<SongsModel>,userPlaylists: null == userPlaylists ? _self._userPlaylists : userPlaylists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,systemPlaylists: null == systemPlaylists ? _self._systemPlaylists : systemPlaylists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,
  ));
}


}

/// @nodoc


class _Error implements HomeState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'HomeState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
