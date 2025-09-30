// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaylistEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistEvent()';
}


}

/// @nodoc
class $PlaylistEventCopyWith<$Res>  {
$PlaylistEventCopyWith(PlaylistEvent _, $Res Function(PlaylistEvent) __);
}


/// Adds pattern-matching-related methods to [PlaylistEvent].
extension PlaylistEventPatterns on PlaylistEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _AddPlaylist value)?  addPlaylist,TResult Function( _AddSongToPlaylist value)?  addSongToPlaylist,TResult Function( _AddMultipleSongsToPlaylist value)?  addMultipleSongsToPlaylist,TResult Function( _RemoveSongFromPlaylist value)?  removeSongFromPlaylist,TResult Function( _RemoveMultipleSongsFromPlaylist value)?  removeMultipleSongsFromPlaylist,TResult Function( _FetchAllPlaylists value)?  fetchAllPlaylists,TResult Function( _RefreshPlaylists value)?  refreshPlaylists,TResult Function( _DeletePlaylist value)?  deletePlaylist,TResult Function( _FetchSongsForSystemPlaylist value)?  fetchSongsForSystemPlaylist,TResult Function( _GetFavoritesPlaylistId value)?  getFavoritesPlaylistId,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddPlaylist() when addPlaylist != null:
return addPlaylist(_that);case _AddSongToPlaylist() when addSongToPlaylist != null:
return addSongToPlaylist(_that);case _AddMultipleSongsToPlaylist() when addMultipleSongsToPlaylist != null:
return addMultipleSongsToPlaylist(_that);case _RemoveSongFromPlaylist() when removeSongFromPlaylist != null:
return removeSongFromPlaylist(_that);case _RemoveMultipleSongsFromPlaylist() when removeMultipleSongsFromPlaylist != null:
return removeMultipleSongsFromPlaylist(_that);case _FetchAllPlaylists() when fetchAllPlaylists != null:
return fetchAllPlaylists(_that);case _RefreshPlaylists() when refreshPlaylists != null:
return refreshPlaylists(_that);case _DeletePlaylist() when deletePlaylist != null:
return deletePlaylist(_that);case _FetchSongsForSystemPlaylist() when fetchSongsForSystemPlaylist != null:
return fetchSongsForSystemPlaylist(_that);case _GetFavoritesPlaylistId() when getFavoritesPlaylistId != null:
return getFavoritesPlaylistId(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _AddPlaylist value)  addPlaylist,required TResult Function( _AddSongToPlaylist value)  addSongToPlaylist,required TResult Function( _AddMultipleSongsToPlaylist value)  addMultipleSongsToPlaylist,required TResult Function( _RemoveSongFromPlaylist value)  removeSongFromPlaylist,required TResult Function( _RemoveMultipleSongsFromPlaylist value)  removeMultipleSongsFromPlaylist,required TResult Function( _FetchAllPlaylists value)  fetchAllPlaylists,required TResult Function( _RefreshPlaylists value)  refreshPlaylists,required TResult Function( _DeletePlaylist value)  deletePlaylist,required TResult Function( _FetchSongsForSystemPlaylist value)  fetchSongsForSystemPlaylist,required TResult Function( _GetFavoritesPlaylistId value)  getFavoritesPlaylistId,}){
final _that = this;
switch (_that) {
case _AddPlaylist():
return addPlaylist(_that);case _AddSongToPlaylist():
return addSongToPlaylist(_that);case _AddMultipleSongsToPlaylist():
return addMultipleSongsToPlaylist(_that);case _RemoveSongFromPlaylist():
return removeSongFromPlaylist(_that);case _RemoveMultipleSongsFromPlaylist():
return removeMultipleSongsFromPlaylist(_that);case _FetchAllPlaylists():
return fetchAllPlaylists(_that);case _RefreshPlaylists():
return refreshPlaylists(_that);case _DeletePlaylist():
return deletePlaylist(_that);case _FetchSongsForSystemPlaylist():
return fetchSongsForSystemPlaylist(_that);case _GetFavoritesPlaylistId():
return getFavoritesPlaylistId(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _AddPlaylist value)?  addPlaylist,TResult? Function( _AddSongToPlaylist value)?  addSongToPlaylist,TResult? Function( _AddMultipleSongsToPlaylist value)?  addMultipleSongsToPlaylist,TResult? Function( _RemoveSongFromPlaylist value)?  removeSongFromPlaylist,TResult? Function( _RemoveMultipleSongsFromPlaylist value)?  removeMultipleSongsFromPlaylist,TResult? Function( _FetchAllPlaylists value)?  fetchAllPlaylists,TResult? Function( _RefreshPlaylists value)?  refreshPlaylists,TResult? Function( _DeletePlaylist value)?  deletePlaylist,TResult? Function( _FetchSongsForSystemPlaylist value)?  fetchSongsForSystemPlaylist,TResult? Function( _GetFavoritesPlaylistId value)?  getFavoritesPlaylistId,}){
final _that = this;
switch (_that) {
case _AddPlaylist() when addPlaylist != null:
return addPlaylist(_that);case _AddSongToPlaylist() when addSongToPlaylist != null:
return addSongToPlaylist(_that);case _AddMultipleSongsToPlaylist() when addMultipleSongsToPlaylist != null:
return addMultipleSongsToPlaylist(_that);case _RemoveSongFromPlaylist() when removeSongFromPlaylist != null:
return removeSongFromPlaylist(_that);case _RemoveMultipleSongsFromPlaylist() when removeMultipleSongsFromPlaylist != null:
return removeMultipleSongsFromPlaylist(_that);case _FetchAllPlaylists() when fetchAllPlaylists != null:
return fetchAllPlaylists(_that);case _RefreshPlaylists() when refreshPlaylists != null:
return refreshPlaylists(_that);case _DeletePlaylist() when deletePlaylist != null:
return deletePlaylist(_that);case _FetchSongsForSystemPlaylist() when fetchSongsForSystemPlaylist != null:
return fetchSongsForSystemPlaylist(_that);case _GetFavoritesPlaylistId() when getFavoritesPlaylistId != null:
return getFavoritesPlaylistId(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name)?  addPlaylist,TResult Function( int playlistId,  int songId,  int position)?  addSongToPlaylist,TResult Function( int playlistId,  List<int> songIds)?  addMultipleSongsToPlaylist,TResult Function( int playlistId,  int songId)?  removeSongFromPlaylist,TResult Function( int playlistId,  List<int> songIds)?  removeMultipleSongsFromPlaylist,TResult Function()?  fetchAllPlaylists,TResult Function()?  refreshPlaylists,TResult Function( int id)?  deletePlaylist,TResult Function( String systemKey)?  fetchSongsForSystemPlaylist,TResult Function()?  getFavoritesPlaylistId,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddPlaylist() when addPlaylist != null:
return addPlaylist(_that.name);case _AddSongToPlaylist() when addSongToPlaylist != null:
return addSongToPlaylist(_that.playlistId,_that.songId,_that.position);case _AddMultipleSongsToPlaylist() when addMultipleSongsToPlaylist != null:
return addMultipleSongsToPlaylist(_that.playlistId,_that.songIds);case _RemoveSongFromPlaylist() when removeSongFromPlaylist != null:
return removeSongFromPlaylist(_that.playlistId,_that.songId);case _RemoveMultipleSongsFromPlaylist() when removeMultipleSongsFromPlaylist != null:
return removeMultipleSongsFromPlaylist(_that.playlistId,_that.songIds);case _FetchAllPlaylists() when fetchAllPlaylists != null:
return fetchAllPlaylists();case _RefreshPlaylists() when refreshPlaylists != null:
return refreshPlaylists();case _DeletePlaylist() when deletePlaylist != null:
return deletePlaylist(_that.id);case _FetchSongsForSystemPlaylist() when fetchSongsForSystemPlaylist != null:
return fetchSongsForSystemPlaylist(_that.systemKey);case _GetFavoritesPlaylistId() when getFavoritesPlaylistId != null:
return getFavoritesPlaylistId();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name)  addPlaylist,required TResult Function( int playlistId,  int songId,  int position)  addSongToPlaylist,required TResult Function( int playlistId,  List<int> songIds)  addMultipleSongsToPlaylist,required TResult Function( int playlistId,  int songId)  removeSongFromPlaylist,required TResult Function( int playlistId,  List<int> songIds)  removeMultipleSongsFromPlaylist,required TResult Function()  fetchAllPlaylists,required TResult Function()  refreshPlaylists,required TResult Function( int id)  deletePlaylist,required TResult Function( String systemKey)  fetchSongsForSystemPlaylist,required TResult Function()  getFavoritesPlaylistId,}) {final _that = this;
switch (_that) {
case _AddPlaylist():
return addPlaylist(_that.name);case _AddSongToPlaylist():
return addSongToPlaylist(_that.playlistId,_that.songId,_that.position);case _AddMultipleSongsToPlaylist():
return addMultipleSongsToPlaylist(_that.playlistId,_that.songIds);case _RemoveSongFromPlaylist():
return removeSongFromPlaylist(_that.playlistId,_that.songId);case _RemoveMultipleSongsFromPlaylist():
return removeMultipleSongsFromPlaylist(_that.playlistId,_that.songIds);case _FetchAllPlaylists():
return fetchAllPlaylists();case _RefreshPlaylists():
return refreshPlaylists();case _DeletePlaylist():
return deletePlaylist(_that.id);case _FetchSongsForSystemPlaylist():
return fetchSongsForSystemPlaylist(_that.systemKey);case _GetFavoritesPlaylistId():
return getFavoritesPlaylistId();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name)?  addPlaylist,TResult? Function( int playlistId,  int songId,  int position)?  addSongToPlaylist,TResult? Function( int playlistId,  List<int> songIds)?  addMultipleSongsToPlaylist,TResult? Function( int playlistId,  int songId)?  removeSongFromPlaylist,TResult? Function( int playlistId,  List<int> songIds)?  removeMultipleSongsFromPlaylist,TResult? Function()?  fetchAllPlaylists,TResult? Function()?  refreshPlaylists,TResult? Function( int id)?  deletePlaylist,TResult? Function( String systemKey)?  fetchSongsForSystemPlaylist,TResult? Function()?  getFavoritesPlaylistId,}) {final _that = this;
switch (_that) {
case _AddPlaylist() when addPlaylist != null:
return addPlaylist(_that.name);case _AddSongToPlaylist() when addSongToPlaylist != null:
return addSongToPlaylist(_that.playlistId,_that.songId,_that.position);case _AddMultipleSongsToPlaylist() when addMultipleSongsToPlaylist != null:
return addMultipleSongsToPlaylist(_that.playlistId,_that.songIds);case _RemoveSongFromPlaylist() when removeSongFromPlaylist != null:
return removeSongFromPlaylist(_that.playlistId,_that.songId);case _RemoveMultipleSongsFromPlaylist() when removeMultipleSongsFromPlaylist != null:
return removeMultipleSongsFromPlaylist(_that.playlistId,_that.songIds);case _FetchAllPlaylists() when fetchAllPlaylists != null:
return fetchAllPlaylists();case _RefreshPlaylists() when refreshPlaylists != null:
return refreshPlaylists();case _DeletePlaylist() when deletePlaylist != null:
return deletePlaylist(_that.id);case _FetchSongsForSystemPlaylist() when fetchSongsForSystemPlaylist != null:
return fetchSongsForSystemPlaylist(_that.systemKey);case _GetFavoritesPlaylistId() when getFavoritesPlaylistId != null:
return getFavoritesPlaylistId();case _:
  return null;

}
}

}

/// @nodoc


class _AddPlaylist implements PlaylistEvent {
  const _AddPlaylist(this.name);
  

 final  String name;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddPlaylistCopyWith<_AddPlaylist> get copyWith => __$AddPlaylistCopyWithImpl<_AddPlaylist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddPlaylist&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'PlaylistEvent.addPlaylist(name: $name)';
}


}

/// @nodoc
abstract mixin class _$AddPlaylistCopyWith<$Res> implements $PlaylistEventCopyWith<$Res> {
  factory _$AddPlaylistCopyWith(_AddPlaylist value, $Res Function(_AddPlaylist) _then) = __$AddPlaylistCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class __$AddPlaylistCopyWithImpl<$Res>
    implements _$AddPlaylistCopyWith<$Res> {
  __$AddPlaylistCopyWithImpl(this._self, this._then);

  final _AddPlaylist _self;
  final $Res Function(_AddPlaylist) _then;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_AddPlaylist(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _AddSongToPlaylist implements PlaylistEvent {
  const _AddSongToPlaylist(this.playlistId, this.songId, this.position);
  

 final  int playlistId;
 final  int songId;
 final  int position;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddSongToPlaylistCopyWith<_AddSongToPlaylist> get copyWith => __$AddSongToPlaylistCopyWithImpl<_AddSongToPlaylist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddSongToPlaylist&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId)&&(identical(other.songId, songId) || other.songId == songId)&&(identical(other.position, position) || other.position == position));
}


@override
int get hashCode => Object.hash(runtimeType,playlistId,songId,position);

@override
String toString() {
  return 'PlaylistEvent.addSongToPlaylist(playlistId: $playlistId, songId: $songId, position: $position)';
}


}

/// @nodoc
abstract mixin class _$AddSongToPlaylistCopyWith<$Res> implements $PlaylistEventCopyWith<$Res> {
  factory _$AddSongToPlaylistCopyWith(_AddSongToPlaylist value, $Res Function(_AddSongToPlaylist) _then) = __$AddSongToPlaylistCopyWithImpl;
@useResult
$Res call({
 int playlistId, int songId, int position
});




}
/// @nodoc
class __$AddSongToPlaylistCopyWithImpl<$Res>
    implements _$AddSongToPlaylistCopyWith<$Res> {
  __$AddSongToPlaylistCopyWithImpl(this._self, this._then);

  final _AddSongToPlaylist _self;
  final $Res Function(_AddSongToPlaylist) _then;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlistId = null,Object? songId = null,Object? position = null,}) {
  return _then(_AddSongToPlaylist(
null == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as int,null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as int,null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _AddMultipleSongsToPlaylist implements PlaylistEvent {
  const _AddMultipleSongsToPlaylist(this.playlistId, final  List<int> songIds): _songIds = songIds;
  

 final  int playlistId;
 final  List<int> _songIds;
 List<int> get songIds {
  if (_songIds is EqualUnmodifiableListView) return _songIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_songIds);
}


/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddMultipleSongsToPlaylistCopyWith<_AddMultipleSongsToPlaylist> get copyWith => __$AddMultipleSongsToPlaylistCopyWithImpl<_AddMultipleSongsToPlaylist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddMultipleSongsToPlaylist&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId)&&const DeepCollectionEquality().equals(other._songIds, _songIds));
}


@override
int get hashCode => Object.hash(runtimeType,playlistId,const DeepCollectionEquality().hash(_songIds));

@override
String toString() {
  return 'PlaylistEvent.addMultipleSongsToPlaylist(playlistId: $playlistId, songIds: $songIds)';
}


}

/// @nodoc
abstract mixin class _$AddMultipleSongsToPlaylistCopyWith<$Res> implements $PlaylistEventCopyWith<$Res> {
  factory _$AddMultipleSongsToPlaylistCopyWith(_AddMultipleSongsToPlaylist value, $Res Function(_AddMultipleSongsToPlaylist) _then) = __$AddMultipleSongsToPlaylistCopyWithImpl;
@useResult
$Res call({
 int playlistId, List<int> songIds
});




}
/// @nodoc
class __$AddMultipleSongsToPlaylistCopyWithImpl<$Res>
    implements _$AddMultipleSongsToPlaylistCopyWith<$Res> {
  __$AddMultipleSongsToPlaylistCopyWithImpl(this._self, this._then);

  final _AddMultipleSongsToPlaylist _self;
  final $Res Function(_AddMultipleSongsToPlaylist) _then;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlistId = null,Object? songIds = null,}) {
  return _then(_AddMultipleSongsToPlaylist(
null == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as int,null == songIds ? _self._songIds : songIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc


class _RemoveSongFromPlaylist implements PlaylistEvent {
  const _RemoveSongFromPlaylist(this.playlistId, this.songId);
  

 final  int playlistId;
 final  int songId;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoveSongFromPlaylistCopyWith<_RemoveSongFromPlaylist> get copyWith => __$RemoveSongFromPlaylistCopyWithImpl<_RemoveSongFromPlaylist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoveSongFromPlaylist&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId)&&(identical(other.songId, songId) || other.songId == songId));
}


@override
int get hashCode => Object.hash(runtimeType,playlistId,songId);

@override
String toString() {
  return 'PlaylistEvent.removeSongFromPlaylist(playlistId: $playlistId, songId: $songId)';
}


}

/// @nodoc
abstract mixin class _$RemoveSongFromPlaylistCopyWith<$Res> implements $PlaylistEventCopyWith<$Res> {
  factory _$RemoveSongFromPlaylistCopyWith(_RemoveSongFromPlaylist value, $Res Function(_RemoveSongFromPlaylist) _then) = __$RemoveSongFromPlaylistCopyWithImpl;
@useResult
$Res call({
 int playlistId, int songId
});




}
/// @nodoc
class __$RemoveSongFromPlaylistCopyWithImpl<$Res>
    implements _$RemoveSongFromPlaylistCopyWith<$Res> {
  __$RemoveSongFromPlaylistCopyWithImpl(this._self, this._then);

  final _RemoveSongFromPlaylist _self;
  final $Res Function(_RemoveSongFromPlaylist) _then;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlistId = null,Object? songId = null,}) {
  return _then(_RemoveSongFromPlaylist(
null == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as int,null == songId ? _self.songId : songId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _RemoveMultipleSongsFromPlaylist implements PlaylistEvent {
  const _RemoveMultipleSongsFromPlaylist(this.playlistId, final  List<int> songIds): _songIds = songIds;
  

 final  int playlistId;
 final  List<int> _songIds;
 List<int> get songIds {
  if (_songIds is EqualUnmodifiableListView) return _songIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_songIds);
}


/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RemoveMultipleSongsFromPlaylistCopyWith<_RemoveMultipleSongsFromPlaylist> get copyWith => __$RemoveMultipleSongsFromPlaylistCopyWithImpl<_RemoveMultipleSongsFromPlaylist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RemoveMultipleSongsFromPlaylist&&(identical(other.playlistId, playlistId) || other.playlistId == playlistId)&&const DeepCollectionEquality().equals(other._songIds, _songIds));
}


@override
int get hashCode => Object.hash(runtimeType,playlistId,const DeepCollectionEquality().hash(_songIds));

@override
String toString() {
  return 'PlaylistEvent.removeMultipleSongsFromPlaylist(playlistId: $playlistId, songIds: $songIds)';
}


}

/// @nodoc
abstract mixin class _$RemoveMultipleSongsFromPlaylistCopyWith<$Res> implements $PlaylistEventCopyWith<$Res> {
  factory _$RemoveMultipleSongsFromPlaylistCopyWith(_RemoveMultipleSongsFromPlaylist value, $Res Function(_RemoveMultipleSongsFromPlaylist) _then) = __$RemoveMultipleSongsFromPlaylistCopyWithImpl;
@useResult
$Res call({
 int playlistId, List<int> songIds
});




}
/// @nodoc
class __$RemoveMultipleSongsFromPlaylistCopyWithImpl<$Res>
    implements _$RemoveMultipleSongsFromPlaylistCopyWith<$Res> {
  __$RemoveMultipleSongsFromPlaylistCopyWithImpl(this._self, this._then);

  final _RemoveMultipleSongsFromPlaylist _self;
  final $Res Function(_RemoveMultipleSongsFromPlaylist) _then;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlistId = null,Object? songIds = null,}) {
  return _then(_RemoveMultipleSongsFromPlaylist(
null == playlistId ? _self.playlistId : playlistId // ignore: cast_nullable_to_non_nullable
as int,null == songIds ? _self._songIds : songIds // ignore: cast_nullable_to_non_nullable
as List<int>,
  ));
}


}

/// @nodoc


class _FetchAllPlaylists implements PlaylistEvent {
  const _FetchAllPlaylists();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FetchAllPlaylists);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistEvent.fetchAllPlaylists()';
}


}




/// @nodoc


class _RefreshPlaylists implements PlaylistEvent {
  const _RefreshPlaylists();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RefreshPlaylists);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistEvent.refreshPlaylists()';
}


}




/// @nodoc


class _DeletePlaylist implements PlaylistEvent {
  const _DeletePlaylist(this.id);
  

 final  int id;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeletePlaylistCopyWith<_DeletePlaylist> get copyWith => __$DeletePlaylistCopyWithImpl<_DeletePlaylist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeletePlaylist&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'PlaylistEvent.deletePlaylist(id: $id)';
}


}

/// @nodoc
abstract mixin class _$DeletePlaylistCopyWith<$Res> implements $PlaylistEventCopyWith<$Res> {
  factory _$DeletePlaylistCopyWith(_DeletePlaylist value, $Res Function(_DeletePlaylist) _then) = __$DeletePlaylistCopyWithImpl;
@useResult
$Res call({
 int id
});




}
/// @nodoc
class __$DeletePlaylistCopyWithImpl<$Res>
    implements _$DeletePlaylistCopyWith<$Res> {
  __$DeletePlaylistCopyWithImpl(this._self, this._then);

  final _DeletePlaylist _self;
  final $Res Function(_DeletePlaylist) _then;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_DeletePlaylist(
null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _FetchSongsForSystemPlaylist implements PlaylistEvent {
  const _FetchSongsForSystemPlaylist(this.systemKey);
  

 final  String systemKey;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FetchSongsForSystemPlaylistCopyWith<_FetchSongsForSystemPlaylist> get copyWith => __$FetchSongsForSystemPlaylistCopyWithImpl<_FetchSongsForSystemPlaylist>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FetchSongsForSystemPlaylist&&(identical(other.systemKey, systemKey) || other.systemKey == systemKey));
}


@override
int get hashCode => Object.hash(runtimeType,systemKey);

@override
String toString() {
  return 'PlaylistEvent.fetchSongsForSystemPlaylist(systemKey: $systemKey)';
}


}

/// @nodoc
abstract mixin class _$FetchSongsForSystemPlaylistCopyWith<$Res> implements $PlaylistEventCopyWith<$Res> {
  factory _$FetchSongsForSystemPlaylistCopyWith(_FetchSongsForSystemPlaylist value, $Res Function(_FetchSongsForSystemPlaylist) _then) = __$FetchSongsForSystemPlaylistCopyWithImpl;
@useResult
$Res call({
 String systemKey
});




}
/// @nodoc
class __$FetchSongsForSystemPlaylistCopyWithImpl<$Res>
    implements _$FetchSongsForSystemPlaylistCopyWith<$Res> {
  __$FetchSongsForSystemPlaylistCopyWithImpl(this._self, this._then);

  final _FetchSongsForSystemPlaylist _self;
  final $Res Function(_FetchSongsForSystemPlaylist) _then;

/// Create a copy of PlaylistEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? systemKey = null,}) {
  return _then(_FetchSongsForSystemPlaylist(
null == systemKey ? _self.systemKey : systemKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _GetFavoritesPlaylistId implements PlaylistEvent {
  const _GetFavoritesPlaylistId();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GetFavoritesPlaylistId);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistEvent.getFavoritesPlaylistId()';
}


}




/// @nodoc
mixin _$PlaylistState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistState()';
}


}

/// @nodoc
class $PlaylistStateCopyWith<$Res>  {
$PlaylistStateCopyWith(PlaylistState _, $Res Function(PlaylistState) __);
}


/// Adds pattern-matching-related methods to [PlaylistState].
extension PlaylistStatePatterns on PlaylistState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Playlist> playlists,  Map<String, List<SongsModel>>? systemPlaylistSongs)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.playlists,_that.systemPlaylistSongs);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Playlist> playlists,  Map<String, List<SongsModel>>? systemPlaylistSongs)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.playlists,_that.systemPlaylistSongs);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Playlist> playlists,  Map<String, List<SongsModel>>? systemPlaylistSongs)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.playlists,_that.systemPlaylistSongs);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements PlaylistState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistState.initial()';
}


}




/// @nodoc


class _Loading implements PlaylistState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PlaylistState.loading()';
}


}




/// @nodoc


class _Loaded implements PlaylistState {
  const _Loaded(final  List<Playlist> playlists, {final  Map<String, List<SongsModel>>? systemPlaylistSongs}): _playlists = playlists,_systemPlaylistSongs = systemPlaylistSongs;
  

 final  List<Playlist> _playlists;
 List<Playlist> get playlists {
  if (_playlists is EqualUnmodifiableListView) return _playlists;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_playlists);
}

 final  Map<String, List<SongsModel>>? _systemPlaylistSongs;
 Map<String, List<SongsModel>>? get systemPlaylistSongs {
  final value = _systemPlaylistSongs;
  if (value == null) return null;
  if (_systemPlaylistSongs is EqualUnmodifiableMapView) return _systemPlaylistSongs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of PlaylistState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._playlists, _playlists)&&const DeepCollectionEquality().equals(other._systemPlaylistSongs, _systemPlaylistSongs));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_playlists),const DeepCollectionEquality().hash(_systemPlaylistSongs));

@override
String toString() {
  return 'PlaylistState.loaded(playlists: $playlists, systemPlaylistSongs: $systemPlaylistSongs)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $PlaylistStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<Playlist> playlists, Map<String, List<SongsModel>>? systemPlaylistSongs
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of PlaylistState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? playlists = null,Object? systemPlaylistSongs = freezed,}) {
  return _then(_Loaded(
null == playlists ? _self._playlists : playlists // ignore: cast_nullable_to_non_nullable
as List<Playlist>,systemPlaylistSongs: freezed == systemPlaylistSongs ? _self._systemPlaylistSongs : systemPlaylistSongs // ignore: cast_nullable_to_non_nullable
as Map<String, List<SongsModel>>?,
  ));
}


}

/// @nodoc


class _Error implements PlaylistState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of PlaylistState
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
  return 'PlaylistState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $PlaylistStateCopyWith<$Res> {
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

/// Create a copy of PlaylistState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
