// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'genre_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GenreEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenreEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GenreEvent()';
}


}

/// @nodoc
class $GenreEventCopyWith<$Res>  {
$GenreEventCopyWith(GenreEvent _, $Res Function(GenreEvent) __);
}


/// Adds pattern-matching-related methods to [GenreEvent].
extension GenreEventPatterns on GenreEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _FetchAllGenres value)?  fetchAllGenres,TResult Function( _FetchSongsForGenre value)?  fetchSongsForGenre,TResult Function( _SortGenres value)?  sortGenres,TResult Function( _UpdateGenreCover value)?  updateGenreCover,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FetchAllGenres() when fetchAllGenres != null:
return fetchAllGenres(_that);case _FetchSongsForGenre() when fetchSongsForGenre != null:
return fetchSongsForGenre(_that);case _SortGenres() when sortGenres != null:
return sortGenres(_that);case _UpdateGenreCover() when updateGenreCover != null:
return updateGenreCover(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _FetchAllGenres value)  fetchAllGenres,required TResult Function( _FetchSongsForGenre value)  fetchSongsForGenre,required TResult Function( _SortGenres value)  sortGenres,required TResult Function( _UpdateGenreCover value)  updateGenreCover,}){
final _that = this;
switch (_that) {
case _FetchAllGenres():
return fetchAllGenres(_that);case _FetchSongsForGenre():
return fetchSongsForGenre(_that);case _SortGenres():
return sortGenres(_that);case _UpdateGenreCover():
return updateGenreCover(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _FetchAllGenres value)?  fetchAllGenres,TResult? Function( _FetchSongsForGenre value)?  fetchSongsForGenre,TResult? Function( _SortGenres value)?  sortGenres,TResult? Function( _UpdateGenreCover value)?  updateGenreCover,}){
final _that = this;
switch (_that) {
case _FetchAllGenres() when fetchAllGenres != null:
return fetchAllGenres(_that);case _FetchSongsForGenre() when fetchSongsForGenre != null:
return fetchSongsForGenre(_that);case _SortGenres() when sortGenres != null:
return sortGenres(_that);case _UpdateGenreCover() when updateGenreCover != null:
return updateGenreCover(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  fetchAllGenres,TResult Function( int genreId)?  fetchSongsForGenre,TResult Function( int sortIndex,  int order)?  sortGenres,TResult Function( int genreId,  String coverPath)?  updateGenreCover,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FetchAllGenres() when fetchAllGenres != null:
return fetchAllGenres();case _FetchSongsForGenre() when fetchSongsForGenre != null:
return fetchSongsForGenre(_that.genreId);case _SortGenres() when sortGenres != null:
return sortGenres(_that.sortIndex,_that.order);case _UpdateGenreCover() when updateGenreCover != null:
return updateGenreCover(_that.genreId,_that.coverPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  fetchAllGenres,required TResult Function( int genreId)  fetchSongsForGenre,required TResult Function( int sortIndex,  int order)  sortGenres,required TResult Function( int genreId,  String coverPath)  updateGenreCover,}) {final _that = this;
switch (_that) {
case _FetchAllGenres():
return fetchAllGenres();case _FetchSongsForGenre():
return fetchSongsForGenre(_that.genreId);case _SortGenres():
return sortGenres(_that.sortIndex,_that.order);case _UpdateGenreCover():
return updateGenreCover(_that.genreId,_that.coverPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  fetchAllGenres,TResult? Function( int genreId)?  fetchSongsForGenre,TResult? Function( int sortIndex,  int order)?  sortGenres,TResult? Function( int genreId,  String coverPath)?  updateGenreCover,}) {final _that = this;
switch (_that) {
case _FetchAllGenres() when fetchAllGenres != null:
return fetchAllGenres();case _FetchSongsForGenre() when fetchSongsForGenre != null:
return fetchSongsForGenre(_that.genreId);case _SortGenres() when sortGenres != null:
return sortGenres(_that.sortIndex,_that.order);case _UpdateGenreCover() when updateGenreCover != null:
return updateGenreCover(_that.genreId,_that.coverPath);case _:
  return null;

}
}

}

/// @nodoc


class _FetchAllGenres implements GenreEvent {
  const _FetchAllGenres();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FetchAllGenres);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GenreEvent.fetchAllGenres()';
}


}




/// @nodoc


class _FetchSongsForGenre implements GenreEvent {
  const _FetchSongsForGenre(this.genreId);
  

 final  int genreId;

/// Create a copy of GenreEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FetchSongsForGenreCopyWith<_FetchSongsForGenre> get copyWith => __$FetchSongsForGenreCopyWithImpl<_FetchSongsForGenre>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FetchSongsForGenre&&(identical(other.genreId, genreId) || other.genreId == genreId));
}


@override
int get hashCode => Object.hash(runtimeType,genreId);

@override
String toString() {
  return 'GenreEvent.fetchSongsForGenre(genreId: $genreId)';
}


}

/// @nodoc
abstract mixin class _$FetchSongsForGenreCopyWith<$Res> implements $GenreEventCopyWith<$Res> {
  factory _$FetchSongsForGenreCopyWith(_FetchSongsForGenre value, $Res Function(_FetchSongsForGenre) _then) = __$FetchSongsForGenreCopyWithImpl;
@useResult
$Res call({
 int genreId
});




}
/// @nodoc
class __$FetchSongsForGenreCopyWithImpl<$Res>
    implements _$FetchSongsForGenreCopyWith<$Res> {
  __$FetchSongsForGenreCopyWithImpl(this._self, this._then);

  final _FetchSongsForGenre _self;
  final $Res Function(_FetchSongsForGenre) _then;

/// Create a copy of GenreEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? genreId = null,}) {
  return _then(_FetchSongsForGenre(
null == genreId ? _self.genreId : genreId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _SortGenres implements GenreEvent {
  const _SortGenres(this.sortIndex, this.order);
  

 final  int sortIndex;
 final  int order;

/// Create a copy of GenreEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SortGenresCopyWith<_SortGenres> get copyWith => __$SortGenresCopyWithImpl<_SortGenres>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SortGenres&&(identical(other.sortIndex, sortIndex) || other.sortIndex == sortIndex)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,sortIndex,order);

@override
String toString() {
  return 'GenreEvent.sortGenres(sortIndex: $sortIndex, order: $order)';
}


}

/// @nodoc
abstract mixin class _$SortGenresCopyWith<$Res> implements $GenreEventCopyWith<$Res> {
  factory _$SortGenresCopyWith(_SortGenres value, $Res Function(_SortGenres) _then) = __$SortGenresCopyWithImpl;
@useResult
$Res call({
 int sortIndex, int order
});




}
/// @nodoc
class __$SortGenresCopyWithImpl<$Res>
    implements _$SortGenresCopyWith<$Res> {
  __$SortGenresCopyWithImpl(this._self, this._then);

  final _SortGenres _self;
  final $Res Function(_SortGenres) _then;

/// Create a copy of GenreEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sortIndex = null,Object? order = null,}) {
  return _then(_SortGenres(
null == sortIndex ? _self.sortIndex : sortIndex // ignore: cast_nullable_to_non_nullable
as int,null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _UpdateGenreCover implements GenreEvent {
  const _UpdateGenreCover(this.genreId, this.coverPath);
  

 final  int genreId;
 final  String coverPath;

/// Create a copy of GenreEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateGenreCoverCopyWith<_UpdateGenreCover> get copyWith => __$UpdateGenreCoverCopyWithImpl<_UpdateGenreCover>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateGenreCover&&(identical(other.genreId, genreId) || other.genreId == genreId)&&(identical(other.coverPath, coverPath) || other.coverPath == coverPath));
}


@override
int get hashCode => Object.hash(runtimeType,genreId,coverPath);

@override
String toString() {
  return 'GenreEvent.updateGenreCover(genreId: $genreId, coverPath: $coverPath)';
}


}

/// @nodoc
abstract mixin class _$UpdateGenreCoverCopyWith<$Res> implements $GenreEventCopyWith<$Res> {
  factory _$UpdateGenreCoverCopyWith(_UpdateGenreCover value, $Res Function(_UpdateGenreCover) _then) = __$UpdateGenreCoverCopyWithImpl;
@useResult
$Res call({
 int genreId, String coverPath
});




}
/// @nodoc
class __$UpdateGenreCoverCopyWithImpl<$Res>
    implements _$UpdateGenreCoverCopyWith<$Res> {
  __$UpdateGenreCoverCopyWithImpl(this._self, this._then);

  final _UpdateGenreCover _self;
  final $Res Function(_UpdateGenreCover) _then;

/// Create a copy of GenreEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? genreId = null,Object? coverPath = null,}) {
  return _then(_UpdateGenreCover(
null == genreId ? _self.genreId : genreId // ignore: cast_nullable_to_non_nullable
as int,null == coverPath ? _self.coverPath : coverPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$GenreState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenreState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GenreState()';
}


}

/// @nodoc
class $GenreStateCopyWith<$Res>  {
$GenreStateCopyWith(GenreState _, $Res Function(GenreState) __);
}


/// Adds pattern-matching-related methods to [GenreState].
extension GenreStatePatterns on GenreState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Genre> genres,  Map<int, List<Song>>? genreSongs)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.genres,_that.genreSongs);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Genre> genres,  Map<int, List<Song>>? genreSongs)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.genres,_that.genreSongs);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Genre> genres,  Map<int, List<Song>>? genreSongs)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.genres,_that.genreSongs);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements GenreState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GenreState.initial()';
}


}




/// @nodoc


class _Loading implements GenreState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GenreState.loading()';
}


}




/// @nodoc


class _Loaded implements GenreState {
  const _Loaded(final  List<Genre> genres, {final  Map<int, List<Song>>? genreSongs}): _genres = genres,_genreSongs = genreSongs;
  

 final  List<Genre> _genres;
 List<Genre> get genres {
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_genres);
}

 final  Map<int, List<Song>>? _genreSongs;
 Map<int, List<Song>>? get genreSongs {
  final value = _genreSongs;
  if (value == null) return null;
  if (_genreSongs is EqualUnmodifiableMapView) return _genreSongs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of GenreState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._genres, _genres)&&const DeepCollectionEquality().equals(other._genreSongs, _genreSongs));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_genres),const DeepCollectionEquality().hash(_genreSongs));

@override
String toString() {
  return 'GenreState.loaded(genres: $genres, genreSongs: $genreSongs)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $GenreStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<Genre> genres, Map<int, List<Song>>? genreSongs
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of GenreState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? genres = null,Object? genreSongs = freezed,}) {
  return _then(_Loaded(
null == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<Genre>,genreSongs: freezed == genreSongs ? _self._genreSongs : genreSongs // ignore: cast_nullable_to_non_nullable
as Map<int, List<Song>>?,
  ));
}


}

/// @nodoc


class _Error implements GenreState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of GenreState
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
  return 'GenreState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $GenreStateCopyWith<$Res> {
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

/// Create a copy of GenreState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
