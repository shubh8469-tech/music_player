// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folder_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FolderEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FolderEvent()';
}


}

/// @nodoc
class $FolderEventCopyWith<$Res>  {
$FolderEventCopyWith(FolderEvent _, $Res Function(FolderEvent) __);
}


/// Adds pattern-matching-related methods to [FolderEvent].
extension FolderEventPatterns on FolderEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _FetchAllFolders value)?  fetchAllFolders,TResult Function( _FetchSongsForFolder value)?  fetchSongsForFolder,TResult Function( _DeleteFolder value)?  deleteFolder,TResult Function( _SortFolders value)?  sortFolders,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FetchAllFolders() when fetchAllFolders != null:
return fetchAllFolders(_that);case _FetchSongsForFolder() when fetchSongsForFolder != null:
return fetchSongsForFolder(_that);case _DeleteFolder() when deleteFolder != null:
return deleteFolder(_that);case _SortFolders() when sortFolders != null:
return sortFolders(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _FetchAllFolders value)  fetchAllFolders,required TResult Function( _FetchSongsForFolder value)  fetchSongsForFolder,required TResult Function( _DeleteFolder value)  deleteFolder,required TResult Function( _SortFolders value)  sortFolders,}){
final _that = this;
switch (_that) {
case _FetchAllFolders():
return fetchAllFolders(_that);case _FetchSongsForFolder():
return fetchSongsForFolder(_that);case _DeleteFolder():
return deleteFolder(_that);case _SortFolders():
return sortFolders(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _FetchAllFolders value)?  fetchAllFolders,TResult? Function( _FetchSongsForFolder value)?  fetchSongsForFolder,TResult? Function( _DeleteFolder value)?  deleteFolder,TResult? Function( _SortFolders value)?  sortFolders,}){
final _that = this;
switch (_that) {
case _FetchAllFolders() when fetchAllFolders != null:
return fetchAllFolders(_that);case _FetchSongsForFolder() when fetchSongsForFolder != null:
return fetchSongsForFolder(_that);case _DeleteFolder() when deleteFolder != null:
return deleteFolder(_that);case _SortFolders() when sortFolders != null:
return sortFolders(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  fetchAllFolders,TResult Function( int folderId)?  fetchSongsForFolder,TResult Function( int folderId)?  deleteFolder,TResult Function( int sortIndex,  int orderIndex)?  sortFolders,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FetchAllFolders() when fetchAllFolders != null:
return fetchAllFolders();case _FetchSongsForFolder() when fetchSongsForFolder != null:
return fetchSongsForFolder(_that.folderId);case _DeleteFolder() when deleteFolder != null:
return deleteFolder(_that.folderId);case _SortFolders() when sortFolders != null:
return sortFolders(_that.sortIndex,_that.orderIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  fetchAllFolders,required TResult Function( int folderId)  fetchSongsForFolder,required TResult Function( int folderId)  deleteFolder,required TResult Function( int sortIndex,  int orderIndex)  sortFolders,}) {final _that = this;
switch (_that) {
case _FetchAllFolders():
return fetchAllFolders();case _FetchSongsForFolder():
return fetchSongsForFolder(_that.folderId);case _DeleteFolder():
return deleteFolder(_that.folderId);case _SortFolders():
return sortFolders(_that.sortIndex,_that.orderIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  fetchAllFolders,TResult? Function( int folderId)?  fetchSongsForFolder,TResult? Function( int folderId)?  deleteFolder,TResult? Function( int sortIndex,  int orderIndex)?  sortFolders,}) {final _that = this;
switch (_that) {
case _FetchAllFolders() when fetchAllFolders != null:
return fetchAllFolders();case _FetchSongsForFolder() when fetchSongsForFolder != null:
return fetchSongsForFolder(_that.folderId);case _DeleteFolder() when deleteFolder != null:
return deleteFolder(_that.folderId);case _SortFolders() when sortFolders != null:
return sortFolders(_that.sortIndex,_that.orderIndex);case _:
  return null;

}
}

}

/// @nodoc


class _FetchAllFolders implements FolderEvent {
  const _FetchAllFolders();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FetchAllFolders);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FolderEvent.fetchAllFolders()';
}


}




/// @nodoc


class _FetchSongsForFolder implements FolderEvent {
  const _FetchSongsForFolder(this.folderId);
  

 final  int folderId;

/// Create a copy of FolderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FetchSongsForFolderCopyWith<_FetchSongsForFolder> get copyWith => __$FetchSongsForFolderCopyWithImpl<_FetchSongsForFolder>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FetchSongsForFolder&&(identical(other.folderId, folderId) || other.folderId == folderId));
}


@override
int get hashCode => Object.hash(runtimeType,folderId);

@override
String toString() {
  return 'FolderEvent.fetchSongsForFolder(folderId: $folderId)';
}


}

/// @nodoc
abstract mixin class _$FetchSongsForFolderCopyWith<$Res> implements $FolderEventCopyWith<$Res> {
  factory _$FetchSongsForFolderCopyWith(_FetchSongsForFolder value, $Res Function(_FetchSongsForFolder) _then) = __$FetchSongsForFolderCopyWithImpl;
@useResult
$Res call({
 int folderId
});




}
/// @nodoc
class __$FetchSongsForFolderCopyWithImpl<$Res>
    implements _$FetchSongsForFolderCopyWith<$Res> {
  __$FetchSongsForFolderCopyWithImpl(this._self, this._then);

  final _FetchSongsForFolder _self;
  final $Res Function(_FetchSongsForFolder) _then;

/// Create a copy of FolderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? folderId = null,}) {
  return _then(_FetchSongsForFolder(
null == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _DeleteFolder implements FolderEvent {
  const _DeleteFolder(this.folderId);
  

 final  int folderId;

/// Create a copy of FolderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteFolderCopyWith<_DeleteFolder> get copyWith => __$DeleteFolderCopyWithImpl<_DeleteFolder>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteFolder&&(identical(other.folderId, folderId) || other.folderId == folderId));
}


@override
int get hashCode => Object.hash(runtimeType,folderId);

@override
String toString() {
  return 'FolderEvent.deleteFolder(folderId: $folderId)';
}


}

/// @nodoc
abstract mixin class _$DeleteFolderCopyWith<$Res> implements $FolderEventCopyWith<$Res> {
  factory _$DeleteFolderCopyWith(_DeleteFolder value, $Res Function(_DeleteFolder) _then) = __$DeleteFolderCopyWithImpl;
@useResult
$Res call({
 int folderId
});




}
/// @nodoc
class __$DeleteFolderCopyWithImpl<$Res>
    implements _$DeleteFolderCopyWith<$Res> {
  __$DeleteFolderCopyWithImpl(this._self, this._then);

  final _DeleteFolder _self;
  final $Res Function(_DeleteFolder) _then;

/// Create a copy of FolderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? folderId = null,}) {
  return _then(_DeleteFolder(
null == folderId ? _self.folderId : folderId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _SortFolders implements FolderEvent {
  const _SortFolders(this.sortIndex, this.orderIndex);
  

 final  int sortIndex;
 final  int orderIndex;

/// Create a copy of FolderEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SortFoldersCopyWith<_SortFolders> get copyWith => __$SortFoldersCopyWithImpl<_SortFolders>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SortFolders&&(identical(other.sortIndex, sortIndex) || other.sortIndex == sortIndex)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex));
}


@override
int get hashCode => Object.hash(runtimeType,sortIndex,orderIndex);

@override
String toString() {
  return 'FolderEvent.sortFolders(sortIndex: $sortIndex, orderIndex: $orderIndex)';
}


}

/// @nodoc
abstract mixin class _$SortFoldersCopyWith<$Res> implements $FolderEventCopyWith<$Res> {
  factory _$SortFoldersCopyWith(_SortFolders value, $Res Function(_SortFolders) _then) = __$SortFoldersCopyWithImpl;
@useResult
$Res call({
 int sortIndex, int orderIndex
});




}
/// @nodoc
class __$SortFoldersCopyWithImpl<$Res>
    implements _$SortFoldersCopyWith<$Res> {
  __$SortFoldersCopyWithImpl(this._self, this._then);

  final _SortFolders _self;
  final $Res Function(_SortFolders) _then;

/// Create a copy of FolderEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sortIndex = null,Object? orderIndex = null,}) {
  return _then(_SortFolders(
null == sortIndex ? _self.sortIndex : sortIndex // ignore: cast_nullable_to_non_nullable
as int,null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$FolderState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FolderState()';
}


}

/// @nodoc
class $FolderStateCopyWith<$Res>  {
$FolderStateCopyWith(FolderState _, $Res Function(FolderState) __);
}


/// Adds pattern-matching-related methods to [FolderState].
extension FolderStatePatterns on FolderState {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Folder> folders,  Map<int, List<Song>>? folderSongs)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.folders,_that.folderSongs);case _Error() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Folder> folders,  Map<int, List<Song>>? folderSongs)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.folders,_that.folderSongs);case _Error():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Folder> folders,  Map<int, List<Song>>? folderSongs)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.folders,_that.folderSongs);case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements FolderState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FolderState.initial()';
}


}




/// @nodoc


class _Loading implements FolderState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FolderState.loading()';
}


}




/// @nodoc


class _Loaded implements FolderState {
  const _Loaded(final  List<Folder> folders, {final  Map<int, List<Song>>? folderSongs}): _folders = folders,_folderSongs = folderSongs;
  

 final  List<Folder> _folders;
 List<Folder> get folders {
  if (_folders is EqualUnmodifiableListView) return _folders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_folders);
}

 final  Map<int, List<Song>>? _folderSongs;
 Map<int, List<Song>>? get folderSongs {
  final value = _folderSongs;
  if (value == null) return null;
  if (_folderSongs is EqualUnmodifiableMapView) return _folderSongs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of FolderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._folders, _folders)&&const DeepCollectionEquality().equals(other._folderSongs, _folderSongs));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_folders),const DeepCollectionEquality().hash(_folderSongs));

@override
String toString() {
  return 'FolderState.loaded(folders: $folders, folderSongs: $folderSongs)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $FolderStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<Folder> folders, Map<int, List<Song>>? folderSongs
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of FolderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? folders = null,Object? folderSongs = freezed,}) {
  return _then(_Loaded(
null == folders ? _self._folders : folders // ignore: cast_nullable_to_non_nullable
as List<Folder>,folderSongs: freezed == folderSongs ? _self._folderSongs : folderSongs // ignore: cast_nullable_to_non_nullable
as Map<int, List<Song>>?,
  ));
}


}

/// @nodoc


class _Error implements FolderState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of FolderState
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
  return 'FolderState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $FolderStateCopyWith<$Res> {
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

/// Create a copy of FolderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
