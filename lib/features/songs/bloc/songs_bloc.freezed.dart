// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'songs_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SongsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SongsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SongsEvent()';
}


}

/// @nodoc
class $SongsEventCopyWith<$Res>  {
$SongsEventCopyWith(SongsEvent _, $Res Function(SongsEvent) __);
}


/// Adds pattern-matching-related methods to [SongsEvent].
extension SongsEventPatterns on SongsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _AddSong value)?  addSong,TResult Function( _GetAllSongs value)?  getAllSongs,TResult Function( _RemoveSong value)?  removeSong,TResult Function( _ShuffleSongs value)?  shuffleSongs,TResult Function( _UpdateSongFavorite value)?  updateSongFavorite,TResult Function( _SortSongs value)?  sortSongs,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddSong() when addSong != null:
return addSong(_that);case _GetAllSongs() when getAllSongs != null:
return getAllSongs(_that);case _RemoveSong() when removeSong != null:
return removeSong(_that);case _ShuffleSongs() when shuffleSongs != null:
return shuffleSongs(_that);case _UpdateSongFavorite() when updateSongFavorite != null:
return updateSongFavorite(_that);case _SortSongs() when sortSongs != null:
return sortSongs(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _AddSong value)  addSong,required TResult Function( _GetAllSongs value)  getAllSongs,required TResult Function( _RemoveSong value)  removeSong,required TResult Function( _ShuffleSongs value)  shuffleSongs,required TResult Function( _UpdateSongFavorite value)  updateSongFavorite,required TResult Function( _SortSongs value)  sortSongs,}){
final _that = this;
switch (_that) {
case _AddSong():
return addSong(_that);case _GetAllSongs():
return getAllSongs(_that);case _RemoveSong():
return removeSong(_that);case _ShuffleSongs():
return shuffleSongs(_that);case _UpdateSongFavorite():
return updateSongFavorite(_that);case _SortSongs():
return sortSongs(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _AddSong value)?  addSong,TResult? Function( _GetAllSongs value)?  getAllSongs,TResult? Function( _RemoveSong value)?  removeSong,TResult? Function( _ShuffleSongs value)?  shuffleSongs,TResult? Function( _UpdateSongFavorite value)?  updateSongFavorite,TResult? Function( _SortSongs value)?  sortSongs,}){
final _that = this;
switch (_that) {
case _AddSong() when addSong != null:
return addSong(_that);case _GetAllSongs() when getAllSongs != null:
return getAllSongs(_that);case _RemoveSong() when removeSong != null:
return removeSong(_that);case _ShuffleSongs() when shuffleSongs != null:
return shuffleSongs(_that);case _UpdateSongFavorite() when updateSongFavorite != null:
return updateSongFavorite(_that);case _SortSongs() when sortSongs != null:
return sortSongs(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( SongsModel song)?  addSong,TResult Function()?  getAllSongs,TResult Function( int id)?  removeSong,TResult Function( List<SongsModel> songs)?  shuffleSongs,TResult Function( int songId,  bool isFavorite)?  updateSongFavorite,TResult Function( int sortIndex,  int sortOrder)?  sortSongs,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddSong() when addSong != null:
return addSong(_that.song);case _GetAllSongs() when getAllSongs != null:
return getAllSongs();case _RemoveSong() when removeSong != null:
return removeSong(_that.id);case _ShuffleSongs() when shuffleSongs != null:
return shuffleSongs(_that.songs);case _UpdateSongFavorite() when updateSongFavorite != null:
return updateSongFavorite(_that.songId,_that.isFavorite);case _SortSongs() when sortSongs != null:
return sortSongs(_that.sortIndex,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( SongsModel song)  addSong,required TResult Function()  getAllSongs,required TResult Function( int id)  removeSong,required TResult Function( List<SongsModel> songs)  shuffleSongs,required TResult Function( int songId,  bool isFavorite)  updateSongFavorite,required TResult Function( int sortIndex,  int sortOrder)  sortSongs,}) {final _that = this;
switch (_that) {
case _AddSong():
return addSong(_that.song);case _GetAllSongs():
return getAllSongs();case _RemoveSong():
return removeSong(_that.id);case _ShuffleSongs():
return shuffleSongs(_that.songs);case _UpdateSongFavorite():
return updateSongFavorite(_that.songId,_that.isFavorite);case _SortSongs():
return sortSongs(_that.sortIndex,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( SongsModel song)?  addSong,TResult? Function()?  getAllSongs,TResult? Function( int id)?  removeSong,TResult? Function( List<SongsModel> songs)?  shuffleSongs,TResult? Function( int songId,  bool isFavorite)?  updateSongFavorite,TResult? Function( int sortIndex,  int sortOrder)?  sortSongs,}) {final _that = this;
switch (_that) {
case _AddSong() when addSong != null:
return addSong(_that.song);case _GetAllSongs() when getAllSongs != null:
return getAllSongs();case _RemoveSong() when removeSong != null:
return removeSong(_that.id);case _ShuffleSongs() when shuffleSongs != null:
return shuffleSongs(_that.songs);case _UpdateSongFavorite() when updateSongFavorite != null:
return updateSongFavorite(_that.songId,_that.isFavorite);case _SortSongs() when sortSongs != null:
return sortSongs(_that.sortIndex,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc


class _AddSong implements SongsEvent {
  const _AddSong(this.song);
  

 final  SongsModel song;

/// Create a copy of SongsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddSongCopyWith<_AddSong> get copyWith => __$AddSongCopyWithImpl<_AddSong>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddSong&&(identical(other.song, song) || other.song == song));
}


@override
int get hashCode => Object.hash(runtimeType,song);

@override
String toString() {
  return 'SongsEvent.addSong(song: $song)';
}


}

/// @nodoc
abstract mixin class _$AddSongCopyWith<$Res> implements $SongsEventCopyWith<$Res> {
  factory _$AddSongCopyWith(_AddSong value, $Res Function(_AddSong) _then) = __$AddSongCopyWithImpl;
@useResult
$Res call({
 SongsModel song
});




}
/// @nodoc
class __$AddSongCopyWithImpl<$Res>
    implements _$AddSongCopyWith<$Res> {
  __$AddSongCopyWithImpl(this._self, this._then);

  final _AddSong _self;
  final $Res Function(_AddSong) _then;

/// Create a copy of SongsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? song = null,}) {
  return _then(_AddSong(
null == song ? _self.song : song // ignore: cast_nullable_to_non_nullable
as SongsModel,
  ));
}


}

/// @nodoc


class _GetAllSongs implements SongsEvent {
  const _GetAllSongs();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GetAllSongs);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SongsEvent.getAllSongs()';
}


}




/// @nodoc


class _RemoveSong implements SongsEvent {
  const _RemoveSong(this.id);
  

 final  int id;

/// Create a copy of SongsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoveSongCopyWith<_RemoveSong> get copyWith => __$RemoveSongCopyWithImpl<_RemoveSong>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoveSong&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'SongsEvent.removeSong(id: $id)';
}


}

/// @nodoc
abstract mixin class _$RemoveSongCopyWith<$Res> implements $SongsEventCopyWith<$Res> {
  factory _$RemoveSongCopyWith(_RemoveSong value, $Res Function(_RemoveSong) _then) = __$RemoveSongCopyWithImpl;
@useResult
$Res call({
 int id
});




}
/// @nodoc
class __$RemoveSongCopyWithImpl<$Res>
    implements _$RemoveSongCopyWith<$Res> {
  __$RemoveSongCopyWithImpl(this._self, this._then);

  final _RemoveSong _self;
  final $Res Function(_RemoveSong) _then;

/// Create a copy of SongsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_RemoveSong(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _ShuffleSongs implements SongsEvent {
  const _ShuffleSongs(final  List<SongsModel> songs): _songs = songs;
  

 final  List<SongsModel> _songs;
 List<SongsModel> get songs {
  if (_songs is EqualUnmodifiableListView) return _songs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_songs);
}


/// Create a copy of SongsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShuffleSongsCopyWith<_ShuffleSongs> get copyWith => __$ShuffleSongsCopyWithImpl<_ShuffleSongs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShuffleSongs&&const DeepCollectionEquality().equals(other._songs, _songs));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_songs));

@override
String toString() {
  return 'SongsEvent.shuffleSongs(songs: $songs)';
}


}

/// @nodoc
abstract mixin class _$ShuffleSongsCopyWith<$Res> implements $SongsEventCopyWith<$Res> {
  factory _$ShuffleSongsCopyWith(_ShuffleSongs value, $Res Function(_ShuffleSongs) _then) = __$ShuffleSongsCopyWithImpl;
@useResult
$Res call({
 List<SongsModel> songs
});




}
/// @nodoc
class __$ShuffleSongsCopyWithImpl<$Res>
    implements _$ShuffleSongsCopyWith<$Res> {
  __$ShuffleSongsCopyWithImpl(this._self, this._then);

  final _ShuffleSongs _self;
  final $Res Function(_ShuffleSongs) _then;

/// Create a copy of SongsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? songs = null,}) {
  return _then(_ShuffleSongs(
null == songs ? _self._songs : songs // ignore: cast_nullable_to_non_nullable
as List<SongsModel>,
  ));
}


}

/// @nodoc


class _UpdateSongFavorite implements SongsEvent {
  const _UpdateSongFavorite(this.songId, this.isFavorite);
  

 final  int songId;
 final  bool isFavorite;

/// Create a copy of SongsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateSongFavoriteCopyWith<_UpdateSongFavorite> get copyWith => __$UpdateSongFavoriteCopyWithImpl<_UpdateSongFavorite>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateSongFavorite&&(identical(other.songId, songId) || other.songId == songId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}


@override
int get hashCode => Object.hash(runtimeType,songId,isFavorite);

@override
String toString() {
  return 'SongsEvent.updateSongFavorite(songId: $songId, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class _$UpdateSongFavoriteCopyWith<$Res> implements $SongsEventCopyWith<$Res> {
  factory _$UpdateSongFavoriteCopyWith(_UpdateSongFavorite value, $Res Function(_UpdateSongFavorite) _then) = __$UpdateSongFavoriteCopyWithImpl;
@useResult
$Res call({
 int songId, bool isFavorite
});




}
/// @nodoc
class __$UpdateSongFavoriteCopyWithImpl<$Res>
    implements _$UpdateSongFavoriteCopyWith<$Res> {
  __$UpdateSongFavoriteCopyWithImpl(this._self, this._then);

  final _UpdateSongFavorite _self;
  final $Res Function(_UpdateSongFavorite) _then;

/// Create a copy of SongsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? songId = null,Object? isFavorite = null,}) {
  return _then(_UpdateSongFavorite(
null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as int,null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _SortSongs implements SongsEvent {
  const _SortSongs(this.sortIndex, [this.sortOrder = 0]);
  

 final  int sortIndex;
@JsonKey() final  int sortOrder;

/// Create a copy of SongsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SortSongsCopyWith<_SortSongs> get copyWith => __$SortSongsCopyWithImpl<_SortSongs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SortSongs&&(identical(other.sortIndex, sortIndex) || other.sortIndex == sortIndex)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,sortIndex,sortOrder);

@override
String toString() {
  return 'SongsEvent.sortSongs(sortIndex: $sortIndex, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$SortSongsCopyWith<$Res> implements $SongsEventCopyWith<$Res> {
  factory _$SortSongsCopyWith(_SortSongs value, $Res Function(_SortSongs) _then) = __$SortSongsCopyWithImpl;
@useResult
$Res call({
 int sortIndex, int sortOrder
});




}
/// @nodoc
class __$SortSongsCopyWithImpl<$Res>
    implements _$SortSongsCopyWith<$Res> {
  __$SortSongsCopyWithImpl(this._self, this._then);

  final _SortSongs _self;
  final $Res Function(_SortSongs) _then;

/// Create a copy of SongsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sortIndex = null,Object? sortOrder = null,}) {
  return _then(_SortSongs(
null == sortIndex ? _self.sortIndex : sortIndex // ignore: cast_nullable_to_non_nullable
as int,null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$SongsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SongsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SongsState()';
}


}

/// @nodoc
class $SongsStateCopyWith<$Res>  {
$SongsStateCopyWith(SongsState _, $Res Function(SongsState) __);
}


/// Adds pattern-matching-related methods to [SongsState].
extension SongsStatePatterns on SongsState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<SongsModel> songs)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.songs);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<SongsModel> songs)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.songs);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<SongsModel> songs)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.songs);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements SongsState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SongsState.initial()';
}


}




/// @nodoc


class _Loading implements SongsState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SongsState.loading()';
}


}




/// @nodoc


class _Loaded implements SongsState {
  const _Loaded(final  List<SongsModel> songs): _songs = songs;
  

 final  List<SongsModel> _songs;
 List<SongsModel> get songs {
  if (_songs is EqualUnmodifiableListView) return _songs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_songs);
}


/// Create a copy of SongsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._songs, _songs));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_songs));

@override
String toString() {
  return 'SongsState.loaded(songs: $songs)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $SongsStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<SongsModel> songs
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of SongsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? songs = null,}) {
  return _then(_Loaded(
null == songs ? _self._songs : songs // ignore: cast_nullable_to_non_nullable
as List<SongsModel>,
  ));
}


}

/// @nodoc


class _Error implements SongsState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of SongsState
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
  return 'SongsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $SongsStateCopyWith<$Res> {
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

/// Create a copy of SongsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
