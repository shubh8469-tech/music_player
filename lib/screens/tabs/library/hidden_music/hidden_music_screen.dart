import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:music_app/commonWidgets/textWidget.dart';
import 'package:music_app/features/folders/bloc/folder_bloc.dart';
import 'package:music_app/core/di/injection.dart';
import 'package:music_app/features/folders/data/dataSource/folder_local_data_source.dart';
import 'package:music_app/features/folders/data/models/folder_model.dart';
import 'package:music_app/features/songs/bloc/songs_bloc.dart';
import 'package:music_app/features/songs/data/dataSource/song_local_data_source.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/generated/assets.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import 'package:music_app/utills/snack_bar.dart';

class HiddenMusicScreen extends StatefulWidget {
  const HiddenMusicScreen({super.key});

  @override
  State<HiddenMusicScreen> createState() => _HiddenMusicScreenState();
}

class _HiddenMusicScreenState extends State<HiddenMusicScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final SongLocalDataSource _songLocalDataSource =
      locator<SongLocalDataSource>();
  final FolderLocalDataSource _folderLocalDataSource =
      locator<FolderLocalDataSource>();

  bool _isLoading = true;
  bool _hiddenExpanded = true;
  bool _visibleExpanded = true;
  bool _hiddenFoldersExpanded = true;
  bool _visibleFoldersExpanded = true;

  List<SongsModel> _hiddenSongs = [];
  List<SongsModel> _visibleSongs = [];
  List<FolderModel> _hiddenFolders = [];
  List<FolderModel> _visibleFolders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hidden = await _songLocalDataSource.getHiddenSongs();
      final visible = await _songLocalDataSource.getAllSongs();
      final hiddenFolders = await _folderLocalDataSource.getHiddenFolders();
      final visibleFolders =
          await _folderLocalDataSource.getAllFolders(includeHidden: false);

      if (!mounted) return;
      setState(() {
        _hiddenSongs = hidden;
        _visibleSongs = visible;
        _hiddenFolders = hiddenFolders;
        _visibleFolders = visibleFolders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showSnackBar(
        context,
        () {},
        message: 'Failed to load songs: $e',
        backgroundColor: Colors.red,
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  Future<void> _toggleHidden(SongsModel song, bool hide) async {
    if (song.id == null) return;

    try {
      await _songLocalDataSource.updateSongHiddenStatus(song.id!, hide);
      if (mounted) {
        context.read<SongsBloc>().add(const SongsEvent.getAllSongs());
      }
      await _loadContent();

      if (!mounted) return;
      showSnackBar(
        context,
        () {},
        message: hide
            ? '"${song.title}" hidden'
            : '"${song.title}" is visible again',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        context,
        () {},
        message: 'Failed to update song: $e',
        backgroundColor: Colors.red,
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  Future<void> _toggleFolderHidden(FolderModel folder, bool hide) async {
    if (folder.id == null) return;

    try {
      await _folderLocalDataSource.updateFolderHiddenStatus(folder.id!, hide);
      if (mounted) {
        context.read<FolderBloc>().add(const FolderEvent.fetchAllFolders());
        context.read<SongsBloc>().add(const SongsEvent.getAllSongs());
      }
      await _loadContent();

      if (!mounted) return;
      showSnackBar(
        context,
        () {},
        message: hide
            ? '"${folder.name}" hidden'
            : '"${folder.name}" is visible again',
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        context,
        () {},
        message: 'Failed to update folder: $e',
        backgroundColor: Colors.red,
        alertBannerLocation: AlertBannerLocation.bottom,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            Assets.svgIcBack,
            colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Texts(
          'Hidden Music',
          fontSize: 18.sp,
          fontWeight: AppFontWeights.semiBold,
          fontFamily: AppFonts.inter,
          color: AppColors.white,
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryOrange,
              labelColor: AppColors.textColor,
              unselectedLabelColor: AppColors.textColor,
              indicatorWeight: 3,
              indicatorPadding: EdgeInsets.zero,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 3.0.w,
                  color: AppColors.primaryOrange,
                ),
                // insets: EdgeInsets.symmetric(horizontal: -65.w),
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'SONGS'),
                Tab(text: 'FOLDERS'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSongsTab(),
                _buildFoldersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          children: [
            _buildSection(
              title: 'Hidden (${_hiddenSongs.length})',
              expanded: _hiddenExpanded,
              onToggle: (value) {
                setState(() => _hiddenExpanded = value);
              },
              songs: _hiddenSongs,
              isHidden: true,
            ),
            SizedBox(height: 16.h),
            _buildSection(
              title: 'Unhidden (${_visibleSongs.length})',
              expanded: _visibleExpanded,
              onToggle: (value) {
                setState(() => _visibleExpanded = value);
              },
              songs: _visibleSongs,
              isHidden: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool expanded,
    required ValueChanged<bool> onToggle,
    required List<SongsModel> songs,
    required bool isHidden,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('hidden_music_$title'),
          initiallyExpanded: expanded,
          onExpansionChanged: onToggle,
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          title: Texts(
            title,
            fontSize: 16.sp,
            fontWeight: AppFontWeights.semiBold,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          trailing: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            color: AppColors.textColor,
          ),
          children: [
            if (songs.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Texts(
                  isHidden
                      ? 'No hidden songs yet'
                      : 'All songs are visible',
                  fontSize: 14.sp,
                  fontWeight: AppFontWeights.regular,
                  fontFamily: AppFonts.inter,
                  color: AppColors.textColor.withValues(alpha: 0.6),
                ),
              )
            else
              ...songs.map(
                (song) => _HiddenSongTile(
                  song: song,
                  isHidden: isHidden,
                  onToggle: () => _toggleHidden(song, !isHidden),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadContent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          children: [
            _buildFolderSection(
              title: 'Hidden (${_hiddenFolders.length})',
              expanded: _hiddenFoldersExpanded,
              onToggle: (value) {
                setState(() => _hiddenFoldersExpanded = value);
              },
              folders: _hiddenFolders,
              isHidden: true,
            ),
            SizedBox(height: 16.h),
            _buildFolderSection(
              title: 'Unhidden (${_visibleFolders.length})',
              expanded: _visibleFoldersExpanded,
              onToggle: (value) {
                setState(() => _visibleFoldersExpanded = value);
              },
              folders: _visibleFolders,
              isHidden: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSection({
    required String title,
    required bool expanded,
    required ValueChanged<bool> onToggle,
    required List<FolderModel> folders,
    required bool isHidden,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('hidden_folder_$title'),
          initiallyExpanded: expanded,
          onExpansionChanged: onToggle,
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          title: Texts(
            title,
            fontSize: 16.sp,
            fontWeight: AppFontWeights.semiBold,
            fontFamily: AppFonts.inter,
            color: AppColors.textColor,
          ),
          trailing: Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            color: AppColors.textColor,
          ),
          children: [
            if (folders.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Texts(
                  isHidden
                      ? 'No hidden folders yet'
                      : 'All folders are visible',
                  fontSize: 14.sp,
                  fontWeight: AppFontWeights.regular,
                  fontFamily: AppFonts.inter,
                  color: AppColors.textColor.withValues(alpha: 0.6),
                  align: TextAlign.center,
                ),
              )
            else
              ...folders.map(
                (folder) => _HiddenFolderTile(
                  folder: folder,
                  isHidden: isHidden,
                  onToggle: () => _toggleFolderHidden(folder, !isHidden),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HiddenSongTile extends StatelessWidget {
  const _HiddenSongTile({
    required this.song,
    required this.isHidden,
    required this.onToggle,
  });

  final SongsModel song;
  final bool isHidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.musicTileBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            height: 52.w,
            width: 52.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryOrange.withValues(alpha: 0.2),
                  AppColors.primaryOrange,
                ],
              ),
            ),
            child: Center(
              child: SvgPicture.asset(
                Assets.svgMusicIcon,
                height: 28.w,
                width: 28.w,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Texts(
                  song.title,
                  fontSize: 16.sp,
                  fontWeight: AppFontWeights.semiBold,
                  fontFamily: AppFonts.inter,
                  color: AppColors.textColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Texts(
                  _buildSubtitle(song),
                  fontSize: 12.sp,
                  fontWeight: AppFontWeights.regular,
                  fontFamily: AppFonts.inter,
                  color: AppColors.textColor.withValues(alpha: 0.6),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggle,
            icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
            color: isHidden
                ? AppColors.primaryOrange
                : AppColors.textColor.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(SongsModel song) {
    final artist = song.artist.isNotEmpty ? song.artist : 'Unknown Artist';
    final folder = song.folder?.isNotEmpty == true ? song.folder! : 'Unknown';
    return '$artist - $folder';
  }
}

class _HiddenFolderTile extends StatelessWidget {
  const _HiddenFolderTile({
    required this.folder,
    required this.isHidden,
    required this.onToggle,
  });

  final FolderModel folder;
  final bool isHidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.musicTileBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Center(
            child: SvgPicture.asset(
              Assets.svgDirectory,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Texts(
                  folder.name,
                  fontSize: 16.sp,
                  fontWeight: AppFontWeights.semiBold,
                  fontFamily: AppFonts.inter,
                  color: AppColors.textColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Texts(
                  '${folder.songCount} songs • ${folder.path}',
                  fontSize: 12.sp,
                  fontWeight: AppFontWeights.regular,
                  fontFamily: AppFonts.inter,
                  color: AppColors.textColor.withValues(alpha: 0.6),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggle,
            icon: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
            color: isHidden
                ? AppColors.primaryOrange
                : AppColors.textColor.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
