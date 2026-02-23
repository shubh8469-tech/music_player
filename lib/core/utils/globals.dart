import 'dart:io';

import 'package:music_app/app_router.dart';

import '../../generated/assets.dart';
import '../../l10n/l10n.dart';
import '../models/song_menu_model.dart';

final List<SongMenuItem> songMenuItems = [
  SongMenuItem(
    icon: Assets.svgIcMenuPlaynext,
    title: S.of(rootNavigatorKey.currentContext!).playNext,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuQueue,
    title: S.of(rootNavigatorKey.currentContext!).addToQueue,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuPlaylist,
    title: S.of(rootNavigatorKey.currentContext!).addToPlaylist,
  ),
  SongMenuItem(
    icon: Assets.svgIcGotoalbum,
    title: S.of(rootNavigatorKey.currentContext!).goToAlbum,
  ),
  SongMenuItem(
    icon: Assets.svgIcArtist,
    title: S.of(rootNavigatorKey.currentContext!).goToArtist,
  ),
  SongMenuItem(
    icon: Assets.svgIcEdit,
    title: S.of(rootNavigatorKey.currentContext!).editDetails,
  ),
  if(!Platform.isIOS)
  SongMenuItem(
    icon: Assets.svgIcRingtone,
    title: S.of(rootNavigatorKey.currentContext!).setAsRingtone,
  ),
  SongMenuItem(
    icon: Assets.svgIcCover,
    title: S.of(rootNavigatorKey.currentContext!).changeCover,
  ),
  SongMenuItem(
    icon: Assets.svgIcHide,
    title: S.of(rootNavigatorKey.currentContext!).hideSong,
  ),
  SongMenuItem(
    icon: Assets.svgIcDelete,
    title: S.of(rootNavigatorKey.currentContext!).deleteSong,
  ),
];

final List<SongMenuItem> playlistSongMenuItems = [
  SongMenuItem(
    icon: Assets.svgIcMenuPlaynext,
    title: S.of(rootNavigatorKey.currentContext!).playNext,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuQueue,
    title: S.of(rootNavigatorKey.currentContext!).addToQueue,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuPlaylist,
    title: S.of(rootNavigatorKey.currentContext!).addToPlaylist,
  ),
  SongMenuItem(
    icon: Assets.svgIcGotoalbum,
    title: S.of(rootNavigatorKey.currentContext!).goToAlbum,
  ),
  SongMenuItem(
    icon: Assets.svgIcArtist,
    title: S.of(rootNavigatorKey.currentContext!).goToArtist,
  ),
  SongMenuItem(
    icon: Assets.svgIcEdit,
    title: S.of(rootNavigatorKey.currentContext!).editDetails,
  ),
  if(!Platform.isIOS)
  SongMenuItem(
    icon: Assets.svgIcRingtone,
    title: S.of(rootNavigatorKey.currentContext!).setAsRingtone,
  ),
  SongMenuItem(
    icon: Assets.svgIcCover,
    title: S.of(rootNavigatorKey.currentContext!).changeCover,
  ),
  SongMenuItem(
    icon: Assets.svgIcHide,
    title: S.of(rootNavigatorKey.currentContext!).hideSong,
  ),
  SongMenuItem(
    icon: Assets.svgIcDelete,
    title: S.of(rootNavigatorKey.currentContext!).removeFromPlaylist,
  ),
  SongMenuItem(
    icon: Assets.svgIcDelete,
    title: S.of(rootNavigatorKey.currentContext!).deleteSong,
  ),
];

final List<SongMenuItem> songPlayingMenuItems = [
  SongMenuItem(
    icon: Assets.svgIcGotoalbum,
    title: S.of(rootNavigatorKey.currentContext!).goToAlbum,
  ),
  SongMenuItem(
    icon: Assets.svgIcArtist,
    title: S.of(rootNavigatorKey.currentContext!).goToArtist,
  ),
  SongMenuItem(
    icon: Assets.svgIcSpeed,
    title: S.of(rootNavigatorKey.currentContext!).speed,
  ),
  SongMenuItem(
    icon: Assets.svgIcKeepscreen,
    title: S.of(rootNavigatorKey.currentContext!).keepScreenOn,
  ),
  SongMenuItem(
    icon: Assets.svgIcEdit,
    title: S.of(rootNavigatorKey.currentContext!).editDetails,
  ),
  SongMenuItem(
    icon: Assets.svgIcRingtone,
    title: S.of(rootNavigatorKey.currentContext!).setAsRingtone,
  ),
  SongMenuItem(
    icon: Assets.svgIcCover,
    title: S.of(rootNavigatorKey.currentContext!).changeCover,
  ),
  SongMenuItem(
    icon: Assets.svgIcHide,
    title: S.of(rootNavigatorKey.currentContext!).hideSong,
  ),
  SongMenuItem(
    icon: Assets.svgIcDelete,
    title: S.of(rootNavigatorKey.currentContext!).deleteSong,
  ),
];

final List<SongMenuItem> playlistMenuItems = [
  SongMenuItem(
    icon: Assets.svgPlayBlackBorder,
    title: S.of(rootNavigatorKey.currentContext!).play,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuPlaynext,
    title: S.of(rootNavigatorKey.currentContext!).playNext,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuQueue,
    title: S.of(rootNavigatorKey.currentContext!).addToQueue,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuPlaylist,
    title: S.of(rootNavigatorKey.currentContext!).addToPlaylist,
  ),
  SongMenuItem(
    icon: Assets.svgIcEdit,
    title: S.of(rootNavigatorKey.currentContext!).rename,
  ),
  SongMenuItem(
    icon: Assets.svgIcCover,
    title: S.of(rootNavigatorKey.currentContext!).changeCover,
  ),
  SongMenuItem(
    icon: Assets.svgIcDelete,
    title: S.of(rootNavigatorKey.currentContext!).deletePlaylist,
  ),
];

final List<SongMenuItem> sortByItems = [
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).songName,
  ),
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).artistName,
  ),
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).albumName,
  ),
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).folderName,
  ),
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).addedTime,
  ),
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).playCount,
  ),
  SongMenuItem(icon: "", title: S.of(rootNavigatorKey.currentContext!).year),
];

final List<SongMenuItem> folderSortByItems = [
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).folderName,
  ),
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).songCount,
  ),
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).modifiedDate,
  ),
  SongMenuItem(icon: "", title: "Random"),
];

final List<SongMenuItem> albumSortByItems = [
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).albumName,
  ),
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).songCount,
  ),
  SongMenuItem(icon: "", title: S.of(rootNavigatorKey.currentContext!).year),
  SongMenuItem(icon: "", title: "Random"),
];

final List<SongMenuItem> artistSortByItems = [
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).artistName,
  ),
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).songCount,
  ),
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).albumName,
  ),
  SongMenuItem(icon: "", title: "Random"),
];

final List<SongMenuItem> genreSortByItems = [
  SongMenuItem(
    icon: "",
    title: "Genre Name",
  ),
  SongMenuItem(
    icon: "",
    title: S.of(rootNavigatorKey.currentContext!).songCount,
  ),
  SongMenuItem(icon: "", title: "Random"),
];

final List<SongMenuItem> albumMenuItems = [
  SongMenuItem(
    icon: Assets.svgPlayBlackBorder,
    title: S.of(rootNavigatorKey.currentContext!).play,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuPlaynext,
    title: S.of(rootNavigatorKey.currentContext!).playNext,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuQueue,
    title: S.of(rootNavigatorKey.currentContext!).addToQueue,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuPlaylist,
    title: S.of(rootNavigatorKey.currentContext!).addToPlaylist,
  ),
  SongMenuItem(
    icon: Assets.svgIcHide,
    title: S.of(rootNavigatorKey.currentContext!).hideFolder,
  ),
  SongMenuItem(
    icon: Assets.svgIcEdit,
    title: S.of(rootNavigatorKey.currentContext!).editTags,
  ),
];

final List<SongMenuItem> artistMenuItems = [
  SongMenuItem(
    icon: Assets.svgPlayBlackBorder,
    title: S.of(rootNavigatorKey.currentContext!).play,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuPlaynext,
    title: S.of(rootNavigatorKey.currentContext!).playNext,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuQueue,
    title: S.of(rootNavigatorKey.currentContext!).addToQueue,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuPlaylist,
    title: S.of(rootNavigatorKey.currentContext!).addToPlaylist,
  ),
  SongMenuItem(
    icon: Assets.svgIcHide,
    title: S.of(rootNavigatorKey.currentContext!).hideFolder,
  ),
  SongMenuItem(
    icon: Assets.svgIcEdit,
    title: S.of(rootNavigatorKey.currentContext!).editTags,
  ),
];

final List<SongMenuItem> genreMenuItems = [
  SongMenuItem(
    icon: Assets.svgPlayBlackBorder,
    title: S.of(rootNavigatorKey.currentContext!).play,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuPlaynext,
    title: S.of(rootNavigatorKey.currentContext!).playNext,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuQueue,
    title: S.of(rootNavigatorKey.currentContext!).addToQueue,
  ),
  SongMenuItem(
    icon: Assets.svgIcMenuPlaylist,
    title: S.of(rootNavigatorKey.currentContext!).addToPlaylist,
  ),
  SongMenuItem(
    icon: Assets.svgIcHide,
    title: S.of(rootNavigatorKey.currentContext!).hideFolder,
  ),
  SongMenuItem(
    icon: Assets.svgIcEdit,
    title: S.of(rootNavigatorKey.currentContext!).editTags,
  ),
];

int selectedItemsCount<T>(List<T> filteredList, Set<int> selectedIds) {
  return filteredList
      .where((song) => selectedIds.contains((song as dynamic).id))
      .length;
}

bool isVideoFile(String path) {
  final videoExtensions = [
    '.mp4',
    '.avi',
    '.mkv',
    '.mov',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.3gp',
    '.ts',
    '.mpg',
    '.mpeg',
  ];
  final lowerPath = path.toLowerCase();
  return videoExtensions.any((ext) => lowerPath.endsWith(ext));
}
