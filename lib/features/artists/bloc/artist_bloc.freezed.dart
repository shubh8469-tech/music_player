// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArtistEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ArtistEvent()';
}


}

/// @nodoc
class $ArtistEventCopyWith<$Res>  {
$ArtistEventCopyWith(ArtistEvent _, $Res Function(ArtistEvent) __);
}


/// Adds pattern-matching-related methods to [ArtistEvent].
extension ArtistEventPatterns on ArtistEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _FetchAllArtists value)?  fetchAllArtists,TResult Function( _FetchSongsForArtist value)?  fetchSongsForArtist,TResult Function( _SortArtists value)?  sortArtists,TResult Function( _UpdateArtistCover value)?  updateArtistCover,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FetchAllArtists() when fetchAllArtists != null:
return fetchAllArtists(_that);case _FetchSongsForArtist() when fetchSongsForArtist != null:
return fetchSongsForArtist(_that);case _SortArtists() when sortArtists != null:
return sortArtists(_that);case _UpdateArtistCover() when updateArtistCover != null:
return updateArtistCover(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _FetchAllArtists value)  fetchAllArtists,required TResult Function( _FetchSongsForArtist value)  fetchSongsForArtist,required TResult Function( _SortArtists value)  sortArtists,required TResult Function( _UpdateArtistCover value)  updateArtistCover,}){
final _that = this;
switch (_that) {
case _FetchAllArtists():
return fetchAllArtists(_that);case _FetchSongsForArtist():
return fetchSongsForArtist(_that);case _SortArtists():
return sortArtists(_that);case _UpdateArtistCover():
return updateArtistCover(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _FetchAllArtists value)?  fetchAllArtists,TResult? Function( _FetchSongsForArtist value)?  fetchSongsForArtist,TResult? Function( _SortArtists value)?  sortArtists,TResult? Function( _UpdateArtistCover value)?  updateArtistCover,}){
final _that = this;
switch (_that) {
case _FetchAllArtists() when fetchAllArtists != null:
return fetchAllArtists(_that);case _FetchSongsForArtist() when fetchSongsForArtist != null:
return fetchSongsForArtist(_that);case _SortArtists() when sortArtists != null:
return sortArtists(_that);case _UpdateArtistCover() when updateArtistCover != null:
return updateArtistCover(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  fetchAllArtists,TResult Function( int artistId)?  fetchSongsForArtist,TResult Function( int sortIndex,  int order)?  sortArtists,TResult Function( int artistId,  String coverPath)?  updateArtistCover,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FetchAllArtists() when fetchAllArtists != null:
return fetchAllArtists();case _FetchSongsForArtist() when fetchSongsForArtist != null:
return fetchSongsForArtist(_that.artistId);case _SortArtists() when sortArtists != null:
return sortArtists(_that.sortIndex,_that.order);case _UpdateArtistCover() when updateArtistCover != null:
return updateArtistCover(_that.artistId,_that.coverPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  fetchAllArtists,required TResult Function( int artistId)  fetchSongsForArtist,required TResult Function( int sortIndex,  int order)  sortArtists,required TResult Function( int artistId,  String coverPath)  updateArtistCover,}) {final _that = this;
switch (_that) {
case _FetchAllArtists():
return fetchAllArtists();case _FetchSongsForArtist():
return fetchSongsForArtist(_that.artistId);case _SortArtists():
return sortArtists(_that.sortIndex,_that.order);case _UpdateArtistCover():
return updateArtistCover(_that.artistId,_that.coverPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  fetchAllArtists,TResult? Function( int artistId)?  fetchSongsForArtist,TResult? Function( int sortIndex,  int order)?  sortArtists,TResult? Function( int artistId,  String coverPath)?  updateArtistCover,}) {final _that = this;
switch (_that) {
case _FetchAllArtists() when fetchAllArtists != null:
return fetchAllArtists();case _FetchSongsForArtist() when fetchSongsForArtist != null:
return fetchSongsForArtist(_that.artistId);case _SortArtists() when sortArtists != null:
return sortArtists(_that.sortIndex,_that.order);case _UpdateArtistCover() when updateArtistCover != null:
return updateArtistCover(_that.artistId,_that.coverPath);case _:
  return null;

}
}

}

/// @nodoc


class _FetchAllArtists implements ArtistEvent {
  const _FetchAllArtists();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FetchAllArtists);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ArtistEvent.fetchAllArtists()';
}


}




/// @nodoc


class _FetchSongsForArtist implements ArtistEvent {
  const _FetchSongsForArtist(this.artistId);
  

 final  int artistId;

/// Create a copy of ArtistEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FetchSongsForArtistCopyWith<_FetchSongsForArtist> get copyWith => __$FetchSongsForArtistCopyWithImpl<_FetchSongsForArtist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FetchSongsForArtist&&(identical(other.artistId, artistId) || other.artistId == artistId));
}


@override
int get hashCode => Object.hash(runtimeType,artistId);

@override
String toString() {
  return 'ArtistEvent.fetchSongsForArtist(artistId: $artistId)';
}


}

/// @nodoc
abstract mixin class _$FetchSongsForArtistCopyWith<$Res> implements $ArtistEventCopyWith<$Res> {
  factory _$FetchSongsForArtistCopyWith(_FetchSongsForArtist value, $Res Function(_FetchSongsForArtist) _then) = __$FetchSongsForArtistCopyWithImpl;
@useResult
$Res call({
 int artistId
});




}
/// @nodoc
class __$FetchSongsForArtistCopyWithImpl<$Res>
    implements _$FetchSongsForArtistCopyWith<$Res> {
  __$FetchSongsForArtistCopyWithImpl(this._self, this._then);

  final _FetchSongsForArtist _self;
  final $Res Function(_FetchSongsForArtist) _then;

/// Create a copy of ArtistEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? artistId = null,}) {
  return _then(_FetchSongsForArtist(
null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _SortArtists implements ArtistEvent {
  const _SortArtists(this.sortIndex, this.order);
  

 final  int sortIndex;
 final  int order;

/// Create a copy of ArtistEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SortArtistsCopyWith<_SortArtists> get copyWith => __$SortArtistsCopyWithImpl<_SortArtists>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SortArtists&&(identical(other.sortIndex, sortIndex) || other.sortIndex == sortIndex)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,sortIndex,order);

@override
String toString() {
  return 'ArtistEvent.sortArtists(sortIndex: $sortIndex, order: $order)';
}


}

/// @nodoc
abstract mixin class _$SortArtistsCopyWith<$Res> implements $ArtistEventCopyWith<$Res> {
  factory _$SortArtistsCopyWith(_SortArtists value, $Res Function(_SortArtists) _then) = __$SortArtistsCopyWithImpl;
@useResult
$Res call({
 int sortIndex, int order
});




}
/// @nodoc
class __$SortArtistsCopyWithImpl<$Res>
    implements _$SortArtistsCopyWith<$Res> {
  __$SortArtistsCopyWithImpl(this._self, this._then);

  final _SortArtists _self;
  final $Res Function(_SortArtists) _then;

/// Create a copy of ArtistEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sortIndex = null,Object? order = null,}) {
  return _then(_SortArtists(
null == sortIndex ? _self.sortIndex : sortIndex // ignore: cast_nullable_to_non_nullable
as int,null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _UpdateArtistCover implements ArtistEvent {
  const _UpdateArtistCover(this.artistId, this.coverPath);
  

 final  int artistId;
 final  String coverPath;

/// Create a copy of ArtistEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateArtistCoverCopyWith<_UpdateArtistCover> get copyWith => __$UpdateArtistCoverCopyWithImpl<_UpdateArtistCover>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateArtistCover&&(identical(other.artistId, artistId) || other.artistId == artistId)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath));
}


@override
int get hashCode => Object.hash(runtimeType,artistId,coverPath);

@override
String toString() {
  return 'ArtistEvent.updateArtistCover(artistId: $artistId, coverPath: $coverPath)';
}


}

/// @nodoc
abstract mixin class _$UpdateArtistCoverCopyWith<$Res> implements $ArtistEventCopyWith<$Res> {
  factory _$UpdateArtistCoverCopyWith(_UpdateArtistCover value, $Res Function(_UpdateArtistCover) _then) = __$UpdateArtistCoverCopyWithImpl;
@useResult
$Res call({
 int artistId, String coverPath
});




}
/// @nodoc
class __$UpdateArtistCoverCopyWithImpl<$Res>
    implements _$UpdateArtistCoverCopyWith<$Res> {
  __$UpdateArtistCoverCopyWithImpl(this._self, this._then);

  final _UpdateArtistCover _self;
  final $Res Function(_UpdateArtistCover) _then;

/// Create a copy of ArtistEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? artistId = null,Object? coverPath = null,}) {
  return _then(_UpdateArtistCover(
null == artistId ? _self.artistId : artistId // ignore: cast_nullable_to_non_nullable
as int,null == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ArtistState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ArtistState()';
}


}

/// @nodoc
class $ArtistStateCopyWith<$Res>  {
$ArtistStateCopyWith(ArtistState _, $Res Function(ArtistState) __);
}


/// Adds pattern-matching-related methods to [ArtistState].
extension ArtistStatePatterns on ArtistState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Artist> artists,  Map<int, List<Song>>? artistSongs)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.artists,_that.artistSongs);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Artist> artists,  Map<int, List<Song>>? artistSongs)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.artists,_that.artistSongs);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Artist> artists,  Map<int, List<Song>>? artistSongs)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.artists,_that.artistSongs);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements ArtistState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ArtistState.initial()';
}


}




/// @nodoc


class _Loading implements ArtistState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ArtistState.loading()';
}


}




/// @nodoc


class _Loaded implements ArtistState {
  const _Loaded(final  List<Artist> artists, {final  Map<int, List<Song>>? artistSongs}): _artists = artists,_artistSongs = artistSongs;
  

 final  List<Artist> _artists;
 List<Artist> get artists {
  if (_artists is EqualUnmodifiableListView) return _artists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_artists);
}

 final  Map<int, List<Song>>? _artistSongs;
 Map<int, List<Song>>? get artistSongs {
  final value = _artistSongs;
  if (value == null) return null;
  if (_artistSongs is EqualUnmodifiableMapView) return _artistSongs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ArtistState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._artists, _artists)&&const DeepCollectionEquality().equals(other._artistSongs, _artistSongs));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_artists),const DeepCollectionEquality().hash(_artistSongs));

@override
String toString() {
  return 'ArtistState.loaded(artists: $artists, artistSongs: $artistSongs)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $ArtistStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<Artist> artists, Map<int, List<Song>>? artistSongs
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of ArtistState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? artists = null,Object? artistSongs = freezed,}) {
  return _then(_Loaded(
null == artists ? _self._artists : artists // ignore: cast_nullable_to_non_nullable
as List<Artist>,artistSongs: freezed == artistSongs ? _self._artistSongs : artistSongs // ignore: cast_nullable_to_non_nullable
as Map<int, List<Song>>?,
  ));
}


}

/// @nodoc


class _Error implements ArtistState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of ArtistState
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
  return 'ArtistState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $ArtistStateCopyWith<$Res> {
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

/// Create a copy of ArtistState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
