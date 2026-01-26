import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:music_app/commonWidgets/MusicListTile.dart';
import 'package:music_app/commonWidgets/common_functions.dart';
import 'package:music_app/commonWidgets/playlist_menu_screen.dart';
import 'package:music_app/commonWidgets/song_menu_screen.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/albums/bloc/album_bloc.dart';
import 'package:music_app/features/albums/domain/entities/album.dart';
import 'package:music_app/features/albums/domain/repositories/album_repository.dart';
import 'package:music_app/features/artists/bloc/artist_bloc.dart';
import 'package:music_app/features/artists/domain/entities/artist.dart';
import 'package:music_app/features/artists/domain/repositories/artist_repository.dart';
import 'package:music_app/features/folders/bloc/folder_bloc.dart';
import 'package:music_app/features/folders/domain/entities/folder.dart';
import 'package:music_app/features/folders/domain/repositories/folder_repository.dart';
import 'package:music_app/features/folders/domain/usecases/update_folder_hidden_status.dart';
import 'package:music_app/features/playlists/bloc/playlist_bloc.dart';
import 'package:music_app/features/playlists/domain/entities/playlist.dart' as domain;
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/l10n/l10n.dart';
import 'package:music_app/screens/play_song/playing_song_screen.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/screens/play_song/widget/playlist_bottomsheet.dart';
import 'package:music_app/screens/tabs/library/playlists/rename_playlist_bottom_sheet.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/utills/globals.dart';
import 'package:music_app/utills/snack_bar.dart';
import 'package:music_app/model/song_menu_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<String> _tabs = const ['ALL', 'SONGS', 'PLAYLISTS', 'FOLDERS', 'ALBUMS', 'ARTISTS'];

  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSongsLoaded();
      _ensurePlaylistsLoaded();
      _ensureFoldersLoaded();
      _ensureAlbumsLoaded();
      _ensureArtistsLoaded();
    });
  }

  void _ensureSongsLoaded() {
    final bloc = context.read<SongsBloc>();
    final hasData = bloc.state.maybeWhen(loaded: (_) => true, orElse: () => false);
    if (!hasData) {
      bloc.add(const SongsEvent.getAllSongs());
    }
  }

  void _ensurePlaylistsLoaded() {
    final bloc = context.read<PlaylistBloc>();
    final hasData = bloc.state.maybeWhen(loaded: (_, __) => true, orElse: () => false);
    if (!hasData) {
      bloc.add(const PlaylistEvent.fetchAllPlaylists());
    }
  }

  void _ensureFoldersLoaded() {
    final bloc = context.read<FolderBloc>();
    final hasData = bloc.state.maybeWhen(loaded: (_, __) => true, orElse: () => false);
    if (!hasData) {
      bloc.add(const FolderEvent.fetchAllFolders());
    }
  }

  void _ensureAlbumsLoaded() {
    final bloc = context.read<AlbumBloc>();
    final hasData = bloc.state.maybeWhen(loaded: (_, __) => true, orElse: () => false);
    if (!hasData) {
      bloc.add(const AlbumEvent.fetchAllAlbums());
    }
  }

  void _ensureArtistsLoaded() {
    final bloc = context.read<ArtistBloc>();
    final hasData = bloc.state.maybeWhen(loaded: (_, __) => true, orElse: () => false);
    if (!hasData) {
      bloc.add(const ArtistEvent.fetchAllArtists());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _switchToTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _tabController.animateTo(index);
    }
  }

  void _clearQuery() {
    if (_query.isEmpty) return;
    setState(() => _query = '');
    _queryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(150.h),
        child: _SearchHeader(
          controller: _queryController,
          focusNode: _focusNode,
          onChanged: (value) => setState(() => _query = value),
          onBackTap: () => Navigator.of(context).maybePop(),
          onClearTap: _clearQuery,
          hasQuery: _query.isNotEmpty,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12.h),
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 0.w),
              child: TabBar(
                indicatorWeight: 8.r,
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.textColor,
                labelStyle: TextStyle(fontSize: 15.sp, fontWeight: AppFontWeights.medium, color: AppColors.black, fontFamily: AppFonts.inter),
                unselectedLabelStyle: TextStyle(fontSize: 15.sp, fontWeight: AppFontWeights.medium, color: AppColors.black, fontFamily: AppFonts.inter),

                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3.0.w, color: AppColors.primaryOrange),
                  insets: EdgeInsets.symmetric(horizontal: -8.w),
                ),
                dividerColor: Colors.transparent,
                tabs: _tabs.map((label) => Tab(text: label)).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AllTab(query: normalizedQuery, onViewAll: _switchToTab),
                  _SongsTab(query: normalizedQuery),
                  _PlaylistsTab(query: normalizedQuery),
                  _FoldersTab(query: normalizedQuery),
                  _AlbumsTab(query: normalizedQuery),
                  _ArtistsTab(query: normalizedQuery),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackTap;
  final VoidCallback onClearTap;
  final bool hasQuery;

  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackTap,
    required this.onClearTap,
    required this.hasQuery,
  });

  @override
  Widget build(BuildContext context) {
    final searchFillColor = Color.lerp(AppColors.primaryOrange, Colors.white, 0.15)!;

    return Container(
      color: AppColors.primaryOrange,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(13.w, 20.h, 20.w, 20.h),
          child: Row(
            children: [
              // SizedBox(
              //   height: 40.r,
              //   width: 40.r,
              //   child: IconButton(
              //     padding: EdgeInsets.zero,
              //     onPressed: onBackTap,
              //     icon: Icon(
              //       Icons.arrow_back_ios_new,
              //       color: Colors.white,
              //       size: 20.r,
              //     ),
              //   ),
              // ),
              // SizedBox(width: 6.w),
              Expanded(
                child: Container(
                  height: 55.h,
                  decoration: BoxDecoration(color: searchFillColor, borderRadius: BorderRadius.circular(28.r)),
                  child: Row(
                    children: [
                      SizedBox(width: 16.w),
                      Icon(Icons.search, color: Colors.white, size: 30.r),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: onChanged,
                          cursorColor: Colors.white,
                          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontFamily: AppFonts.inter),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search In Library',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 16.sp, fontFamily: AppFonts.inter),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (hasQuery)
                        IconButton(
                          onPressed: onClearTap,
                          splashRadius: 18.r,
                          icon: Icon(Icons.close, color: Colors.white, size: 18.r),
                        )
                      else
                        SizedBox(width: 16.w),
                      SizedBox(width: 8.w),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllTab extends StatelessWidget {
  final String query;
  final void Function(int index) onViewAll;

  const _AllTab({required this.query, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Songs', onViewAll: () => onViewAll(1)),
          SizedBox(height: 12.h),
          _SongsSection(query: query, limit: 4),
          SizedBox(height: 24.h),
          _SectionHeader(title: 'Playlists', onViewAll: () => onViewAll(2)),
          SizedBox(height: 12.h),
          _PlaylistsSection(query: query, limit: 3),
          SizedBox(height: 24.h),
          _SectionHeader(title: 'Folders', onViewAll: () => onViewAll(3)),
          SizedBox(height: 12.h),
          _FoldersSection(query: query, limit: 3),
          SizedBox(height: 24.h),
          _SectionHeader(title: 'Albums', onViewAll: () => onViewAll(4)),
          SizedBox(height: 12.h),
          _AlbumsSection(query: query, limit: 4),
          SizedBox(height: 24.h),
          _SectionHeader(title: 'Artists', onViewAll: () => onViewAll(5)),
          SizedBox(height: 12.h),
          _ArtistsSection(query: query, limit: 4),
          SizedBox(height: 70.h),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Texts(title, fontSize: 18.sp, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter, color: AppColors.textColor),
        GestureDetector(
          onTap: onViewAll,
          child: Texts('View All', fontSize: 14.sp, fontWeight: AppFontWeights.medium, fontFamily: AppFonts.inter, color: AppColors.primaryOrange),
        ),
      ],
    );
  }
}

class _SongsSection extends StatelessWidget {
  final String query;
  final int? limit;

  const _SongsSection({required this.query, this.limit});

  @override
  Widget build(BuildContext context) {
    final musicService = MusicPlayerService();

    return BlocBuilder<SongsBloc, SongsState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (message) => _ErrorMessage(message: message),
          loaded: (songs) {
            final filtered = _filterSongs(songs, query);
            final visibleSongs = limit != null ? filtered.take(limit!).toList() : filtered;

            if (visibleSongs.isEmpty) {
              return _EmptyMessage(message: query.isEmpty ? 'No songs available' : 'No songs match your search');
            }

            return Column(
              children: List.generate(visibleSongs.length, (index) {
                final song = visibleSongs[index];
                final artworkPath = (song.artwork_path?.isNotEmpty ?? false) ? song.artwork_path! : Assets.svgMusicIcon;
                final isSvg = artworkPath.contains('.svg');
                final cardColors = artworkPath.contains('.svg') || artworkPath.isEmpty ? [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.mildOrange] : null;
                final currentIndex = filtered.indexOf(song);

                return MusicListTile(
                  margin: 7.w,
                  height: 66.h,
                  borderRadius: 10.r,
                  backgroundColor: AppColors.musicTileBackgroundColor,
                  cardHeight: 50.h,
                  cardWidth: 50.h,
                  cardRadius: 7.r,
                  noLogoGradientColor: cardColors,
                  cardIconAsset: artworkPath,
                  cardIconSize: 32.r,
                  isSvgCardIcon: isSvg,
                  isSvgColorNeeded: true,
                  title: song.title,
                  subtitle: song.artist,
                  songLength: formatDuration(song.duration),
                  songLengthRequired: true,
                  trailingIconAsset: Assets.svgMenuIcon,
                  trailingIconHeight: 19.5.h,
                  trailingIconWidth: 3.w,
                  trailingMargin: 10.w,
                  onTap: () async {
                    await musicService.setPlaylist(filtered, startIndex: currentIndex >= 0 ? currentIndex : index);
                    if (!context.mounted) return;
                    context.push('/dashboard/playing', extra: PlayingSongArgs(songs: filtered));
                  },
                  onPlayTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
                      isScrollControlled: true,
                      builder: (_) => SongMenuScreen(
                        songMenuList: songMenuItems,
                        isPlaying: false,
                        currentSong: song,
                        songIndex: currentIndex >= 0 ? currentIndex : index,
                        songsList: filtered,
                        maxHeight: 0.87.sh,
                        onSongDeleted: () {
                          // Refresh global songs after deletion so search results stay in sync
                          final bloc = context.read<SongsBloc>();
                          bloc.add(const SongsEvent.getAllSongs());
                        },
                      ),
                    );
                  },
                );
              }),
            );
          },
        );
      },
    );
  }
}

class _PlaylistsSection extends StatelessWidget {
  final String query;
  final int? limit;

  const _PlaylistsSection({required this.query, this.limit});

  static final Map<String, String> _systemPlaylistIcons = {
    'most_played': Assets.svgMostPlayed,
    'recently_added': Assets.svgRecentlyAdded,
    'recently_played': Assets.svgRecentlyPlayed,
    'favorites': Assets.svgFavorites,
  };

  static final Map<String, Color> _systemPlaylistColors = {
    'most_played': AppColors.mildOrange,
    'recently_added': AppColors.mildBlue,
    'recently_played': AppColors.mildYellow,
    'favorites': AppColors.mildPink,
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistBloc, PlaylistState>(
      builder: (context, state) {
        return state.maybeWhen(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (message) => _ErrorMessage(message: message),
          loaded: (playlists, __) {
            final filtered = _filterPlaylists(playlists, query);
            final visible = limit != null ? filtered.where((element) => element.systemKey == null).take(limit!).toList() : filtered;

            if (visible.isEmpty) {
              return _EmptyMessage(message: query.isEmpty ? 'No playlists available' : 'No playlists match your search');
            }

            return Column(
              children: visible.map((playlist) {
                final isSystem = playlist.isSystem == true;
                final systemKey = playlist.systemKey ?? '';
                final hasCover = (playlist.coverPath?.isNotEmpty ?? false);
                final userCoverAsset = hasCover ? playlist.coverPath! : Assets.svgMusicIcon;
                final iconAsset = isSystem ? _systemPlaylistIcons[systemKey] ?? Assets.svgMusicIcon : userCoverAsset;
                final baseColor = isSystem ? _systemPlaylistColors[systemKey] ?? AppColors.mildBlue : AppColors.primaryOrange;
                final gradientColors = [baseColor.withValues(alpha: 0.21), baseColor];
                final iconIsSvg = iconAsset.contains('.svg');
                return MusicListTile(
                  margin: 7.w,
                  height: 66.h,
                  borderRadius: 10.r,
                  backgroundColor: AppColors.musicTileBackgroundColor,
                  cardHeight: 50.h,
                  cardWidth: 50.h,
                  cardRadius: 7.r,
                  noLogoGradientColor: iconIsSvg ? gradientColors : null,
                  cardIconAsset: iconAsset,
                  cardIconSize: 32.r,
                  isSvgCardIcon: iconIsSvg,
                  isSvgColorNeeded: iconIsSvg,
                  title: playlist.name,
                  subtitle: '${playlist.songCount} songs',
                  trailingIconAsset: Assets.svgMenuIcon,
                  trailingIconHeight: 19.5.h,
                  trailingIconWidth: 3.w,
                  trailingMargin: 10.w,
                  onTap: () {
                    context.push('/dashboard/playlist-detail', extra: {'playlist': playlist, 'assetIcon': iconAsset, 'colors': gradientColors});
                  },
                  onPlayTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
                      isScrollControlled: true,
                      builder: (_) => BlocProvider.value(
                        value: context.read<PlaylistBloc>(),
                        child: PlaylistMenuScreen(
                          playlist: playlist,
                          playlistIconAsset: iconAsset,
                          playlistGradientColors: gradientColors,
                          isSystemPlaylist: isSystem,
                          systemKeyOrId: isSystem ? systemKey : playlist.id?.toString() ?? '',
                          onRename: isSystem
                              ? null
                              : () async {
                                  final result = await showModalBottomSheet<String>(
                                    context: context,
                                    backgroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
                                    isScrollControlled: true,
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<PlaylistBloc>(),
                                      child: RenamePlaylistBottomSheet(playlist: playlist),
                                    ),
                                  );
                                  if (!context.mounted) return;
                                  if (result != null && result.isNotEmpty) {
                                    showSnackBar(context, () {}, message: 'Playlist renamed successfully', alertBannerLocation: AlertBannerLocation.bottom);
                                  }
                                },
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
          orElse: () => const SizedBox.shrink(),
        );
      },
    );
  }
}

class _FoldersSection extends StatelessWidget {
  final String query;
  final int? limit;

  const _FoldersSection({required this.query, this.limit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FolderBloc, FolderState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (message) => _ErrorMessage(message: message),
          loaded: (folders, folderSongs) {
            final filtered = _filterFolders(folders, query);
            final visible = limit != null ? filtered.take(limit!).toList() : filtered;

            if (visible.isEmpty) {
              return _EmptyMessage(message: query.isEmpty ? 'No folders available' : 'No folders match your search');
            }

            return Column(
              children: visible.map((folder) {
                final iconAsset = (folder.artworkPath?.isNotEmpty ?? false) ? folder.artworkPath! : Assets.svgDirectory;
                final isSvg = iconAsset.contains('.svg');
                final colors = iconAsset.contains('.svg') ? [AppColors.mildYellow.withValues(alpha: 0.21), AppColors.mildYellow] : null;
                return MusicListTile(
                  margin: 7.w,
                  height: 66.h,
                  borderRadius: 10.r,
                  backgroundColor: AppColors.musicTileBackgroundColor,
                  cardHeight: 50.h,
                  cardWidth: 50.h,
                  cardRadius: 7.r,
                  noLogoGradientColor: colors,
                  cardIconAsset: iconAsset,
                  cardIconSize: 32.r,
                  isSvgCardIcon: isSvg,
                  isSvgColorNeeded: !isSvg ? true : false,
                  title: folder.name,
                  subtitle: '${folder.songCount} songs',
                  trailingIconAsset: Assets.svgMenuIcon,
                  trailingIconHeight: 19.5.h,
                  trailingIconWidth: 3.w,
                  trailingMargin: 10.w,
                  onTap: () {
                    context.push('/dashboard/folder-detail', extra: folder);
                  },
                  onPlayTap: () {
                    _showFolderMenuSheet(context, folder);
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _AlbumsSection extends StatelessWidget {
  final String query;
  final int? limit;

  const _AlbumsSection({required this.query, this.limit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlbumBloc, AlbumState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (message) => _ErrorMessage(message: message),
          loaded: (albums, albumSongs) {
            final filtered = _filterAlbums(albums, query);
            final visible = limit != null ? filtered.take(limit!).toList() : filtered;

            if (visible.isEmpty) {
              return _EmptyMessage(message: query.isEmpty ? 'No albums available' : 'No albums match your search');
            }

            return Column(
              children: visible.map((album) {
                final iconAsset = (album.artworkPath?.isNotEmpty ?? false) ? album.artworkPath! : Assets.svgAlbum;
                final isSvg = iconAsset.contains('.svg');
                final colors = iconAsset.contains('.svg') ? [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.mildOrange] : null;
                final subtitle = [if ((album.artist ?? '').isNotEmpty) album.artist, '${album.songCount} songs'].whereType<String>().join(' • ');

                return MusicListTile(
                  margin: 7.w,
                  height: 66.h,
                  borderRadius: 10.r,
                  backgroundColor: AppColors.musicTileBackgroundColor,
                  cardHeight: 50.h,
                  cardWidth: 50.h,
                  cardRadius: 7.r,
                  noLogoGradientColor: colors,
                  cardIconAsset: iconAsset,
                  cardIconSize: 32.r,
                  isSvgCardIcon: isSvg,
                  isSvgColorNeeded: true,
                  title: album.name,
                  subtitle: subtitle,
                  trailingIconAsset: Assets.svgMenuIcon,
                  trailingIconHeight: 19.5.h,
                  trailingIconWidth: 3.w,
                  trailingMargin: 10.w,
                  onTap: () {
                    context.push('/dashboard/album-detail', extra: album);
                  },
                  onPlayTap: () {
                    _showAlbumMenuSheet(context, album);
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _ArtistsSection extends StatelessWidget {
  final String query;
  final int? limit;

  const _ArtistsSection({required this.query, this.limit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArtistBloc, ArtistState>(
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (message) => _ErrorMessage(message: message),
          loaded: (artists, artistSongs) {
            final filtered = _filterArtists(artists, query);
            final visible = limit != null ? filtered.take(limit!).toList() : filtered;

            if (visible.isEmpty) {
              return _EmptyMessage(message: query.isEmpty ? 'No artists available' : 'No artists match your search');
            }

            return Column(
              children: visible.map((artist) {
                final iconAsset = (artist.artworkPath?.isNotEmpty ?? false) ? artist.artworkPath! : Assets.svgProxyArtist;
                final isSvg = iconAsset.contains('.svg');
                final colors = iconAsset.contains('.svg') ? [AppColors.black.withValues(alpha: 0.14), AppColors.black.withValues(alpha: 0.14)] : null;

                return MusicListTile(
                  margin: 7.w,
                  height: 66.h,
                  borderRadius: 10.r,
                  backgroundColor: AppColors.musicTileBackgroundColor,
                  cardHeight: 50.h,
                  cardWidth: 50.h,
                  cardRadius: 100.r,
                  noLogoGradientColor: colors,
                  cardIconAsset: iconAsset,
                  cardIconSize: 19.r,
                  isSvgCardIcon: isSvg,
                  isSvgColorNeeded: true,
                  title: artist.name,
                  subtitle: '${artist.albumCount} albums • ${artist.songCount} songs',
                  trailingIconAsset: Assets.svgMenuIcon,
                  trailingIconHeight: 19.5.h,
                  trailingIconWidth: 3.w,
                  trailingMargin: 10.w,
                  onTap: () {
                    context.push('/dashboard/artist-detail', extra: artist);
                  },
                  onPlayTap: () {
                    _showArtistMenuSheet(context, artist);
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _SongsTab extends StatelessWidget {
  final String query;

  const _SongsTab({required this.query});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: _SongsSection(query: query),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  final String query;

  const _PlaylistsTab({required this.query});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: _PlaylistsSection(query: query),
    );
  }
}

class _FoldersTab extends StatelessWidget {
  final String query;

  const _FoldersTab({required this.query});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: _FoldersSection(query: query),
    );
  }
}

class _AlbumsTab extends StatelessWidget {
  final String query;

  const _AlbumsTab({required this.query});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: _AlbumsSection(query: query),
    );
  }
}

class _ArtistsTab extends StatelessWidget {
  final String query;

  const _ArtistsTab({required this.query});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: _ArtistsSection(query: query),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Texts(message, fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.mediumDarkGrey, fontFamily: AppFonts.inter),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Texts('Error: $message', fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: Colors.red, fontFamily: AppFonts.inter),
      ),
    );
  }
}

List<SongsModel> _filterSongs(List<SongsModel> songs, String query) {
  if (query.isEmpty) return songs;
  return songs.where((song) {
    final normalized = query.toLowerCase();
    return song.title.toLowerCase().contains(normalized) || song.artist.toLowerCase().contains(normalized) || song.album.toLowerCase().contains(normalized);
  }).toList();
}

List<domain.Playlist> _filterPlaylists(List<domain.Playlist> playlists, String query) {
  if (query.isEmpty) return playlists;
  final normalized = query.toLowerCase();
  return playlists.where((playlist) => playlist.name.toLowerCase().contains(normalized)).toList();
}

List<Folder> _filterFolders(List<Folder> folders, String query) {
  if (query.isEmpty) return folders;
  final normalized = query.toLowerCase();
  return folders.where((folder) => folder.name.toLowerCase().contains(normalized) || folder.path.toLowerCase().contains(normalized)).toList();
}

List<Album> _filterAlbums(List<Album> albums, String query) {
  if (query.isEmpty) return albums;
  final normalized = query.toLowerCase();
  return albums.where((album) => album.name.toLowerCase().contains(normalized) || (album.artist ?? '').toLowerCase().contains(normalized)).toList();
}

List<Artist> _filterArtists(List<Artist> artists, String query) {
  if (query.isEmpty) return artists;
  final normalized = query.toLowerCase();
  return artists.where((artist) => artist.name.toLowerCase().contains(normalized)).toList();
}

void _showFolderMenuSheet(BuildContext context, Folder folder) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
    isScrollControlled: true,
    builder: (_) => _FolderActionSheet(folder: folder),
  );
}

class _FolderActionSheet extends StatelessWidget {
  _FolderActionSheet({required this.folder});

  final Folder folder;
  final MusicPlayerService musicService = MusicPlayerService();
  final FolderRepository _repo = locator<FolderRepository>();
  final UpdateFolderHiddenStatus _updateFolderHiddenStatus = locator<UpdateFolderHiddenStatus>();

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;
    final menuItems = _buildFolderMenuItems(context);

    return Container(
      constraints: BoxConstraints(maxHeight: 0.63.sh),
      padding: EdgeInsets.only(top: 10.h, bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 10.h),
          Flexible(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: MusicListTile(
                    margin: 7.w,
                    height: 66.h,
                    borderRadius: 10.r,
                    backgroundColor: AppColors.musicTileBackgroundColor,
                    cardHeight: 50.h,
                    cardWidth: 50.h,
                    cardRadius: 7.r,
                    noLogoGradientColor: [AppColors.mildYellow.withValues(alpha: 0.21), AppColors.mildYellow],
                    cardIconAsset: Assets.svgDirectory,
                    cardIconSize: 32.r,
                    isSvgCardIcon: true,
                    title: folder.name,
                    subtitle: '${folder.songCount} Songs',
                    trailingIconAsset: Assets.svgIcShare,
                    trailingIconHeight: 25.h,
                    trailingIconWidth: 25.w,
                    trailingMargin: 2.w,
                    onTap: () {
                      showSnackBar(context, () {}, message: 'Share folder feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
                    },
                    onPlayTap: () {
                      showSnackBar(context, () {}, message: 'Play folder feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final menuItem = menuItems[index];
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(horizontal: 0.w, vertical: 0.h),
                            leading: SvgPicture.asset(menuItem.icon, height: 24, width: 24),
                            title: Texts(menuItem.title, fontSize: 16.sp, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
                            onTap: () {
                              Navigator.pop(context);
                              _handleFolderMenuAction(context, menuItem.title);
                            },
                          ),
                          if (index == menuItems.length - 2)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                              child: Divider(height: 1, thickness: 1, color: AppColors.black.withValues(alpha: .1)),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(80.r),
                      border: Border.all(color: AppColors.black.withValues(alpha: 0.10), width: 1),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 15.w),
                    height: 50.w,
                    child: Texts(
                      S.of(context).cancel,
                      fontSize: 14.sp,
                      align: TextAlign.center,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColor,
                      fontFamily: AppFonts.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25.h),
        ],
      ),
    );
  }

  void _handleFolderMenuAction(BuildContext context, String menuTitle) {
    if (menuTitle == S.of(context).play) {
      _playFolder(context);
    } else if (menuTitle == S.of(context).playNext) {
      _playNextFolder(context);
    } else if (menuTitle == S.of(context).addToQueue) {
      _addFolderToQueue(context);
    } else if (menuTitle == S.of(context).addToPlaylist) {
      _addFolderToPlaylist(context);
    } else if (menuTitle == S.of(context).hideFolder || menuTitle == S.of(context).unhideFolder) {
      final hide = menuTitle == S.of(context).hideFolder;
      _toggleFolderHidden(context, hide);
    }
  }

  List<SongMenuItem> _buildFolderMenuItems(BuildContext context) {
    final localization = S.of(context);
    final hideTitle = folder.isHidden ? localization.unhideFolder : localization.hideFolder;

    return [
      SongMenuItem(icon: Assets.svgPlayBlackBorder, title: localization.play),
      SongMenuItem(icon: Assets.svgIcMenuPlaynext, title: localization.playNext),
      SongMenuItem(icon: Assets.svgIcMenuQueue, title: localization.addToQueue),
      SongMenuItem(icon: Assets.svgIcMenuPlaylist, title: localization.addToPlaylist),
      SongMenuItem(icon: Assets.svgIcHide, title: hideTitle),
    ];
  }

  Future<void> _playFolder(BuildContext context) async {
    if (folder.id == null) {
      showSnackBar(context, () {}, message: 'Folder contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final folderSongs = (await _repo.getSongsForFolder(folder.id!)).cast<SongsModel>();

      if (folderSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Folder contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      await musicService.setPlaylist(folderSongs, startIndex: 0);
      await musicService.play();

      showSnackBar(context, () {}, message: 'Playing ${folderSongs.length} songs from ${folder.name}', alertBannerLocation: AlertBannerLocation.bottom);
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error playing folder: $e', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _playNextFolder(BuildContext context) async {
    if (folder.id == null) {
      showSnackBar(context, () {}, message: 'Folder contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final folderSongs = (await _repo.getSongsForFolder(folder.id!)).cast<SongsModel>();

      if (folderSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Folder contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      if (musicService.songs.isEmpty) {
        await musicService.setPlaylist(folderSongs, startIndex: 0);
        await musicService.play();
      } else {
        // final currentIndex = musicService.currentIndex;
        // final insertIndex = currentIndex + 1;
        // final newSongsList = List<SongsModel>.from(musicService.songs);
        //
        // final songsToAdd = folderSongs.where((song) {
        //   return !newSongsList.any((existingSong) => existingSong.id == song.id);
        // }).toList();
        //
        // newSongsList.insertAll(insertIndex, songsToAdd);
        //
        // await musicService.setPlaylist(newSongsList, startIndex: currentIndex >= 0 ? currentIndex : 0, autoPlay: false);
        final updateCount = await musicService.playNextMultipleSongs(folderSongs);

        if(updateCount < 1){
          showSnackBar(
            context,
                () {},
            message: "Songs already added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
        else{
          showSnackBar(
            context,
                () {},
            message: "$updateCount songs added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
      }

    } catch (e) {
      showSnackBar(context, () {}, message: 'Error adding folder to play next', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _addFolderToQueue(BuildContext context) async {
    if (folder.id == null) {
      showSnackBar(context, () {}, message: 'Folder contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final folderSongs = (await _repo.getSongsForFolder(folder.id!)).cast<SongsModel>();

      if (folderSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Folder contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      final addedSong = await musicService.addMultipleSongsToQueue(folderSongs);

        if (addedSong < 1) {
          showSnackBar(
            context,
                () {},
            message: "Songs already added to queue",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        } else {
          showSnackBar(
            context,
                () {},
            message: "$addedSong songs added to queue",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error adding folder to queue', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _addFolderToPlaylist(BuildContext context) async {
    if (folder.id == null) {
      showSnackBar(context, () {}, message: 'Folder contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final playlistBloc = context.read<PlaylistBloc>();
      final folderSongs = (await _repo.getSongsForFolder(folder.id!)).cast<SongsModel>();

      if (folderSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Folder contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
        isScrollControlled: true,
        builder: (_) => BlocProvider.value(
          value: playlistBloc,
          child: PlaylistBottomSheet(songsList: folderSongs),
        ),
      );
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error fetching songs from folder: $e', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _toggleFolderHidden(BuildContext context, bool hide) async {
    if (folder.id == null) return;

    try {
      await _updateFolderHiddenStatus(folder.id!, hide);
      context.read<FolderBloc>().add(const FolderEvent.fetchAllFolders());
      context.read<SongsBloc>().add(const SongsEvent.getAllSongs());
      showSnackBar(
        context,
        () {},
        message: hide ? '"${folder.name}" hidden successfully' : '"${folder.name}" is visible again',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      showSnackBar(context, () {}, message: 'Failed to update folder: $e', backgroundColor: Colors.red, alertBannerLocation: AlertBannerLocation.bottom);
    }
  }
}

void _showAlbumMenuSheet(BuildContext context, Album album) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
    isScrollControlled: true,
    builder: (_) => _AlbumActionSheet(album: album),
  );
}

class _AlbumActionSheet extends StatelessWidget {
  _AlbumActionSheet({required this.album});

  final Album album;
  final MusicPlayerService musicService = MusicPlayerService();
  final AlbumRepository _repo = locator<AlbumRepository>();

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    final albumArtworkPath = (album.artworkPath?.isNotEmpty ?? false) ? album.artworkPath! : Assets.svgAlbum;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.63.sh),
      padding: EdgeInsets.only(top: 10.h, bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 10.h),
          Flexible(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: MusicListTile(
                    margin: 7.w,
                    height: 66.h,
                    borderRadius: 10.r,
                    backgroundColor: AppColors.musicTileBackgroundColor,
                    cardHeight: 50.h,
                    cardWidth: 50.h,
                    cardRadius: 7.r,
                    noLogoGradientColor: [AppColors.mildOrange.withValues(alpha: 0.21), AppColors.mildOrange],
                    cardIconAsset: albumArtworkPath,
                    cardIconSize: 32.r,
                    isSvgCardIcon: true,
                    title: album.name,
                    subtitle: '${album.songCount} Songs',
                    trailingIconAsset: Assets.svgIcShare,
                    trailingIconHeight: 25.h,
                    trailingIconWidth: 25.w,
                    trailingMargin: 2.w,
                    onTap: () {
                      showSnackBar(context, () {}, message: 'Share album feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
                    },
                    onPlayTap: () {
                      showSnackBar(context, () {}, message: 'Play album feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: albumMenuItems.length,
                    itemBuilder: (context, index) {
                      final menuItem = albumMenuItems[index];
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(horizontal: 0.w, vertical: 0.h),
                            leading: SvgPicture.asset(menuItem.icon, height: 24, width: 24),
                            title: Texts(menuItem.title, fontSize: 16.sp, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
                            onTap: () {
                              Navigator.pop(context);
                              _handleAlbumMenuAction(context, menuItem.title);
                            },
                          ),
                          if (index == 3)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                              child: Divider(height: 1, thickness: 1, color: AppColors.black.withValues(alpha: .1)),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(80.r),
                      border: Border.all(color: AppColors.black.withValues(alpha: 0.10), width: 1),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 15.w),
                    height: 50.w,
                    child: Texts(
                      S.of(context).cancel,
                      fontSize: 14.sp,
                      align: TextAlign.center,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColor,
                      fontFamily: AppFonts.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25.h),
        ],
      ),
    );
  }

  void _handleAlbumMenuAction(BuildContext context, String menuTitle) {
    if (menuTitle == S.of(context).play) {
      _playAlbum(context);
    } else if (menuTitle == S.of(context).playNext) {
      _playNextAlbum(context);
    } else if (menuTitle == S.of(context).addToQueue) {
      _addAlbumToQueue(context);
    } else if (menuTitle == S.of(context).addToPlaylist) {
      _addAlbumToPlaylist(context);
    }
  }

  Future<void> _playAlbum(BuildContext context) async {
    if (album.id == null) {
      showSnackBar(context, () {}, message: 'Album contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final albumSongs = (await _repo.getSongsForAlbum(album.id!)).cast<SongsModel>();

      if (albumSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Album contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      await musicService.setPlaylist(albumSongs, startIndex: 0);
      await musicService.play();

      showSnackBar(context, () {}, message: 'Playing ${albumSongs.length} songs from ${album.name}', alertBannerLocation: AlertBannerLocation.bottom);
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error playing album: $e', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _playNextAlbum(BuildContext context) async {
    if (album.id == null) {
      showSnackBar(context, () {}, message: 'Album contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final albumSongs = (await _repo.getSongsForAlbum(album.id!)).cast<SongsModel>();

      if (albumSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Album contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      if (musicService.songs.isEmpty) {
        await musicService.setPlaylist(albumSongs, startIndex: 0);
        await musicService.play();
      } else {
        // final currentIndex = musicService.currentIndex;
        // final insertIndex = currentIndex + 1;
        // final newSongsList = List<SongsModel>.from(musicService.songs);
        //
        // final songsToAdd = albumSongs.where((song) {
        //   return !newSongsList.any((existingSong) => existingSong.id == song.id);
        // }).toList();
        //
        // newSongsList.insertAll(insertIndex, songsToAdd);
        //
        // await musicService.setPlaylist(newSongsList, startIndex: currentIndex >= 0 ? currentIndex : 0, autoPlay: false);
        final updateCount = await musicService.playNextMultipleSongs(albumSongs);

        if(updateCount < 1){
          showSnackBar(
            context,
                () {},
            message: "Songs already added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
        else{
          showSnackBar(
            context,
                () {},
            message: "$updateCount songs added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
      }
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error adding album to play next', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _addAlbumToQueue(BuildContext context) async {
    if (album.id == null) {
      showSnackBar(context, () {}, message: 'Album contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final albumSongs = (await _repo.getSongsForAlbum(album.id!)).cast<SongsModel>();

      if (albumSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Album contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      final addedSong = await musicService.addMultipleSongsToQueue(albumSongs);

        if (addedSong < 1) {
          showSnackBar(
            context,
                () {},
            message: "Songs already added to queue",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        } else {
          showSnackBar(
            context,
                () {},
            message: "$addedSong songs added to queue",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
      }
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error adding album to queue', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _addAlbumToPlaylist(BuildContext context) async {
    if (album.id == null) {
      showSnackBar(context, () {}, message: 'Album contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final playlistBloc = context.read<PlaylistBloc>();
      final albumSongs = (await _repo.getSongsForAlbum(album.id!)).cast<SongsModel>();

      if (albumSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Album contains no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
        isScrollControlled: true,
        builder: (_) => BlocProvider.value(
          value: playlistBloc,
          child: PlaylistBottomSheet(songsList: albumSongs),
        ),
      );
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error fetching songs from album: $e', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }
}

void _showArtistMenuSheet(BuildContext context, Artist artist) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
    isScrollControlled: true,
    builder: (_) => _ArtistActionSheet(artist: artist),
  );
}

class _ArtistActionSheet extends StatelessWidget {
  _ArtistActionSheet({required this.artist});

  final Artist artist;
  final MusicPlayerService musicService = MusicPlayerService();
  final ArtistRepository _repo = locator<ArtistRepository>();

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final viewPadding = MediaQuery.of(context).viewPadding.bottom;
    final bottomPadding = viewInsets > 0 ? viewInsets + 16.h : (viewPadding > 0 ? viewPadding : 16.h) + 16.h;

    final artistArtworkPath = (artist.artworkPath?.isNotEmpty ?? false) ? artist.artworkPath! : Assets.svgMusicIcon;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.63.sh),
      padding: EdgeInsets.only(top: 10.h, bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(Assets.svgIcLineBottom),
          SizedBox(height: 10.h),
          Flexible(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: MusicListTile(
                    margin: 7.w,
                    height: 66.h,
                    borderRadius: 10.r,
                    backgroundColor: AppColors.musicTileBackgroundColor,
                    cardHeight: 50.h,
                    cardWidth: 50.h,
                    cardRadius: 100.r,
                    cardIconAsset: artistArtworkPath,
                    cardIconSize: 32.r,
                    isSvgCardIcon: true,
                    isSvgColorNeeded: false,
                    title: artist.name,
                    subtitle: '${artist.albumCount} Album${artist.albumCount != 1 ? 's' : ''} - ${artist.songCount} Songs',
                    trailingIconAsset: Assets.svgIcShare,
                    trailingIconHeight: 25.h,
                    trailingIconWidth: 25.w,
                    trailingMargin: 2.w,
                    onTap: () {
                      showSnackBar(context, () {}, message: 'Share artist feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
                    },
                    onPlayTap: () {
                      showSnackBar(context, () {}, message: 'Play artist feature coming soon', alertBannerLocation: AlertBannerLocation.bottom);
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: artistMenuItems.length,
                    itemBuilder: (context, index) {
                      final menuItem = artistMenuItems[index];
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity(horizontal: 0.w, vertical: 0.h),
                            leading: SvgPicture.asset(menuItem.icon, height: 24, width: 24),
                            title: Texts(menuItem.title, fontSize: 16.sp, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
                            onTap: () {
                              Navigator.pop(context);
                              _handleArtistMenuAction(context, menuItem.title);
                            },
                          ),
                          if (index == 3)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                              child: Divider(height: 1, thickness: 1, color: AppColors.black.withValues(alpha: .1)),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(80.r),
                      border: Border.all(color: AppColors.black.withValues(alpha: 0.10), width: 1),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 15.w),
                    height: 50.w,
                    child: Texts(
                      S.of(context).cancel,
                      fontSize: 14.sp,
                      align: TextAlign.center,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColor,
                      fontFamily: AppFonts.medium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 25.h),
        ],
      ),
    );
  }

  void _handleArtistMenuAction(BuildContext context, String menuTitle) {
    if (menuTitle == S.of(context).play) {
      _playArtist(context);
    } else if (menuTitle == S.of(context).playNext) {
      _playNextArtist(context);
    } else if (menuTitle == S.of(context).addToQueue) {
      _addArtistToQueue(context);
    } else if (menuTitle == S.of(context).addToPlaylist) {
      _addArtistToPlaylist(context);
    }
  }

  Future<void> _playArtist(BuildContext context) async {
    if (artist.id == null) {
      showSnackBar(context, () {}, message: 'Artist has no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final artistSongs = (await _repo.getSongsForArtist(artist.id!)).cast<SongsModel>();

      if (artistSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Artist has no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      await musicService.setPlaylist(artistSongs, startIndex: 0);
      await musicService.play();

      showSnackBar(context, () {}, message: 'Playing ${artistSongs.length} songs from ${artist.name}', alertBannerLocation: AlertBannerLocation.bottom);
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error playing artist: $e', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _playNextArtist(BuildContext context) async {
    if (artist.id == null) {
      showSnackBar(context, () {}, message: 'Artist has no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final artistSongs = (await _repo.getSongsForArtist(artist.id!)).cast<SongsModel>();

      if (artistSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Artist has no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      if (musicService.songs.isEmpty) {
        await musicService.setPlaylist(artistSongs, startIndex: 0);
        await musicService.play();
      } else {
        // final currentIndex = musicService.currentIndex;
        // final insertIndex = currentIndex + 1;
        // final newSongsList = List<SongsModel>.from(musicService.songs);
        //
        // final songsToAdd = artistSongs.where((song) {
        //   return !newSongsList.any((existingSong) => existingSong.id == song.id);
        // }).toList();
        //
        // newSongsList.insertAll(insertIndex, songsToAdd);
        //
        // await musicService.setPlaylist(newSongsList, startIndex: currentIndex >= 0 ? currentIndex : 0, autoPlay: false);

        final updateCount = await musicService.playNextMultipleSongs(artistSongs);

        if(updateCount < 1){
          showSnackBar(
            context,
                () {},
            message: "Songs already added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
        else{
          showSnackBar(
            context,
                () {},
            message: "$updateCount songs added to play next",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
      }

      showSnackBar(context, () {}, message: '${artistSongs.length} songs from ${artist.name} added to play next', alertBannerLocation: AlertBannerLocation.bottom);
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error adding artist to play next', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _addArtistToQueue(BuildContext context) async {
    if (artist.id == null) {
      showSnackBar(context, () {}, message: 'Artist has no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final artistSongs = (await _repo.getSongsForArtist(artist.id!)).cast<SongsModel>();

      if (artistSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Artist has no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      final addedSong = await musicService.addMultipleSongsToQueue(artistSongs);

        if (addedSong < 1) {
          showSnackBar(
            context,
                () {},
            message: "Songs already added to queue",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        } else {
          showSnackBar(
            context,
                () {},
            message: "$addedSong songs added to queue",
            alertBannerLocation: AlertBannerLocation.bottom,
          );
        }
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error adding artist to queue', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }

  Future<void> _addArtistToPlaylist(BuildContext context) async {
    if (artist.id == null) {
      showSnackBar(context, () {}, message: 'Artist has no songs', alertBannerLocation: AlertBannerLocation.bottom);
      return;
    }
    try {
      final playlistBloc = context.read<PlaylistBloc>();
      final artistSongs = (await _repo.getSongsForArtist(artist.id!)).cast<SongsModel>();

      if (artistSongs.isEmpty) {
        showSnackBar(context, () {}, message: 'Artist has no songs', alertBannerLocation: AlertBannerLocation.bottom);
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40.r))),
        isScrollControlled: true,
        builder: (_) => BlocProvider.value(
          value: playlistBloc,
          child: PlaylistBottomSheet(songsList: artistSongs),
        ),
      );
    } catch (e) {
      showSnackBar(context, () {}, message: 'Error fetching songs from artist: $e', alertBannerLocation: AlertBannerLocation.bottom);
    }
  }
}
