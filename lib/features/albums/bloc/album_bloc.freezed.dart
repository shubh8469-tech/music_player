// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'album_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlbumEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlbumEvent()';
}


}

/// @nodoc
class $AlbumEventCopyWith<$Res>  {
$AlbumEventCopyWith(AlbumEvent _, $Res Function(AlbumEvent) __);
}


/// Adds pattern-matching-related methods to [AlbumEvent].
extension AlbumEventPatterns on AlbumEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _FetchAllAlbums value)?  fetchAllAlbums,TResult Function( _FetchSongsForAlbum value)?  fetchSongsForAlbum,TResult Function( _FetchAlbumsByArtist value)?  fetchAlbumsByArtist,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FetchAllAlbums() when fetchAllAlbums != null:
return fetchAllAlbums(_that);case _FetchSongsForAlbum() when fetchSongsForAlbum != null:
return fetchSongsForAlbum(_that);case _FetchAlbumsByArtist() when fetchAlbumsByArtist != null:
return fetchAlbumsByArtist(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _FetchAllAlbums value)  fetchAllAlbums,required TResult Function( _FetchSongsForAlbum value)  fetchSongsForAlbum,required TResult Function( _FetchAlbumsByArtist value)  fetchAlbumsByArtist,}){
final _that = this;
switch (_that) {
case _FetchAllAlbums():
return fetchAllAlbums(_that);case _FetchSongsForAlbum():
return fetchSongsForAlbum(_that);case _FetchAlbumsByArtist():
return fetchAlbumsByArtist(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _FetchAllAlbums value)?  fetchAllAlbums,TResult? Function( _FetchSongsForAlbum value)?  fetchSongsForAlbum,TResult? Function( _FetchAlbumsByArtist value)?  fetchAlbumsByArtist,}){
final _that = this;
switch (_that) {
case _FetchAllAlbums() when fetchAllAlbums != null:
return fetchAllAlbums(_that);case _FetchSongsForAlbum() when fetchSongsForAlbum != null:
return fetchSongsForAlbum(_that);case _FetchAlbumsByArtist() when fetchAlbumsByArtist != null:
return fetchAlbumsByArtist(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  fetchAllAlbums,TResult Function( int albumId)?  fetchSongsForAlbum,TResult Function( String artistName)?  fetchAlbumsByArtist,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FetchAllAlbums() when fetchAllAlbums != null:
return fetchAllAlbums();case _FetchSongsForAlbum() when fetchSongsForAlbum != null:
return fetchSongsForAlbum(_that.albumId);case _FetchAlbumsByArtist() when fetchAlbumsByArtist != null:
return fetchAlbumsByArtist(_that.artistName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  fetchAllAlbums,required TResult Function( int albumId)  fetchSongsForAlbum,required TResult Function( String artistName)  fetchAlbumsByArtist,}) {final _that = this;
switch (_that) {
case _FetchAllAlbums():
return fetchAllAlbums();case _FetchSongsForAlbum():
return fetchSongsForAlbum(_that.albumId);case _FetchAlbumsByArtist():
return fetchAlbumsByArtist(_that.artistName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  fetchAllAlbums,TResult? Function( int albumId)?  fetchSongsForAlbum,TResult? Function( String artistName)?  fetchAlbumsByArtist,}) {final _that = this;
switch (_that) {
case _FetchAllAlbums() when fetchAllAlbums != null:
return fetchAllAlbums();case _FetchSongsForAlbum() when fetchSongsForAlbum != null:
return fetchSongsForAlbum(_that.albumId);case _FetchAlbumsByArtist() when fetchAlbumsByArtist != null:
return fetchAlbumsByArtist(_that.artistName);case _:
  return null;

}
}

}

/// @nodoc


class _FetchAllAlbums implements AlbumEvent {
  const _FetchAllAlbums();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FetchAllAlbums);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlbumEvent.fetchAllAlbums()';
}


}




/// @nodoc


class _FetchSongsForAlbum implements AlbumEvent {
  const _FetchSongsForAlbum(this.albumId);
  

 final  int albumId;

/// Create a copy of AlbumEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FetchSongsForAlbumCopyWith<_FetchSongsForAlbum> get copyWith => __$FetchSongsForAlbumCopyWithImpl<_FetchSongsForAlbum>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FetchSongsForAlbum&&(identical(other.albumId, albumId) || other.albumId == albumId));
}


@override
int get hashCode => Object.hash(runtimeType,albumId);

@override
String toString() {
  return 'AlbumEvent.fetchSongsForAlbum(albumId: $albumId)';
}


}

/// @nodoc
abstract mixin class _$FetchSongsForAlbumCopyWith<$Res> implements $AlbumEventCopyWith<$Res> {
  factory _$FetchSongsForAlbumCopyWith(_FetchSongsForAlbum value, $Res Function(_FetchSongsForAlbum) _then) = __$FetchSongsForAlbumCopyWithImpl;
@useResult
$Res call({
 int albumId
});




}
/// @nodoc
class __$FetchSongsForAlbumCopyWithImpl<$Res>
    implements _$FetchSongsForAlbumCopyWith<$Res> {
  __$FetchSongsForAlbumCopyWithImpl(this._self, this._then);

  final _FetchSongsForAlbum _self;
  final $Res Function(_FetchSongsForAlbum) _then;

/// Create a copy of AlbumEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? albumId = null,}) {
  return _then(_FetchSongsForAlbum(
null == albumId ? _self.albumId : albumId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _FetchAlbumsByArtist implements AlbumEvent {
  const _FetchAlbumsByArtist(this.artistName);
  

 final  String artistName;

/// Create a copy of AlbumEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FetchAlbumsByArtistCopyWith<_FetchAlbumsByArtist> get copyWith => __$FetchAlbumsByArtistCopyWithImpl<_FetchAlbumsByArtist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FetchAlbumsByArtist&&(identical(other.artistName, artistName) || other.artistName == artistName));
}


@override
int get hashCode => Object.hash(runtimeType,artistName);

@override
String toString() {
  return 'AlbumEvent.fetchAlbumsByArtist(artistName: $artistName)';
}


}

/// @nodoc
abstract mixin class _$FetchAlbumsByArtistCopyWith<$Res> implements $AlbumEventCopyWith<$Res> {
  factory _$FetchAlbumsByArtistCopyWith(_FetchAlbumsByArtist value, $Res Function(_FetchAlbumsByArtist) _then) = __$FetchAlbumsByArtistCopyWithImpl;
@useResult
$Res call({
 String artistName
});




}
/// @nodoc
class __$FetchAlbumsByArtistCopyWithImpl<$Res>
    implements _$FetchAlbumsByArtistCopyWith<$Res> {
  __$FetchAlbumsByArtistCopyWithImpl(this._self, this._then);

  final _FetchAlbumsByArtist _self;
  final $Res Function(_FetchAlbumsByArtist) _then;

/// Create a copy of AlbumEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? artistName = null,}) {
  return _then(_FetchAlbumsByArtist(
null == artistName ? _self.artistName : artistName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$AlbumState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlbumState()';
}


}

/// @nodoc
class $AlbumStateCopyWith<$Res>  {
$AlbumStateCopyWith(AlbumState _, $Res Function(AlbumState) __);
}


/// Adds pattern-matching-related methods to [AlbumState].
extension AlbumStatePatterns on AlbumState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Album> albums,  Map<int, List<Song>>? albumSongs)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.albums,_that.albumSongs);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Album> albums,  Map<int, List<Song>>? albumSongs)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.albums,_that.albumSongs);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Album> albums,  Map<int, List<Song>>? albumSongs)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.albums,_that.albumSongs);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements AlbumState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlbumState.initial()';
}


}




/// @nodoc


class _Loading implements AlbumState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AlbumState.loading()';
}


}




/// @nodoc


class _Loaded implements AlbumState {
  const _Loaded(final  List<Album> albums, {final  Map<int, List<Song>>? albumSongs}): _albums = albums,_albumSongs = albumSongs;
  

 final  List<Album> _albums;
 List<Album> get albums {
  if (_albums is EqualUnmodifiableListView) return _albums;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_albums);
}

 final  Map<int, List<Song>>? _albumSongs;
 Map<int, List<Song>>? get albumSongs {
  final value = _albumSongs;
  if (value == null) return null;
  if (_albumSongs is EqualUnmodifiableMapView) return _albumSongs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AlbumState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._albums, _albums)&&const DeepCollectionEquality().equals(other._albumSongs, _albumSongs));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_albums),const DeepCollectionEquality().hash(_albumSongs));

@override
String toString() {
  return 'AlbumState.loaded(albums: $albums, albumSongs: $albumSongs)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $AlbumStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<Album> albums, Map<int, List<Song>>? albumSongs
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of AlbumState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? albums = null,Object? albumSongs = freezed,}) {
  return _then(_Loaded(
null == albums ? _self._albums : albums // ignore: cast_nullable_to_non_nullable
as List<Album>,albumSongs: freezed == albumSongs ? _self._albumSongs : albumSongs // ignore: cast_nullable_to_non_nullable
as Map<int, List<Song>>?,
  ));
}


}

/// @nodoc


class _Error implements AlbumState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of AlbumState
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
  return 'AlbumState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $AlbumStateCopyWith<$Res> {
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

/// Create a copy of AlbumState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
