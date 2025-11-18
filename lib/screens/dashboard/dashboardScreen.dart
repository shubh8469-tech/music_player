import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/screens/tabs/home/homeScreen.dart';
import 'package:music_app/screens/tabs/library/libraryScreen.dart';
import 'package:music_app/screens/tabs/search/search_screen.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/screens/tabs/library/widgets/mini_player_bar.dart';

import '../../generated/assets.dart';
import '../../themes/font.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../tabs/music_service.dart';
import '../../features/playlists/bloc/playlist_bloc.dart';
import '../../features/songs/data/models/song_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;
  final _musicService = MusicPlayerService();
  final _libraryController = LibraryScreenController();

  late List<Widget> screens;

  StreamSubscription<void>? _libChangedSub;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();

    screens = [
      HomeScreen(
        onNavigateToLibraryPlaylists: () {
          setState(() {
            currentIndex = 2; // Switch to Library tab
          });
          // Switch to Playlists tab in Library after the frame is built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _libraryController.switchToPlaylistsTab();
          });
        },
      ),
      const SearchScreen(),
      LibraryScreen(controller: _libraryController),
    ];

    _libChangedSub = MusicPlayerService().libraryChanged.listen((_) {
      if (!mounted) return;
      // context.read<PlaylistBloc>().add(const PlaylistEvent.fetchAllPlaylists());
      final now = DateTime.now();
      if (_lastRefreshTime == null ||
          now.difference(_lastRefreshTime!).inSeconds > 1) {
        _lastRefreshTime = now;
        context.read<PlaylistBloc>().add(
          const PlaylistEvent.refreshPlaylists(),
        );
      }
    });
  }

  @override
  void dispose() {
    _libChangedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: currentIndex != 1
          ? AppBar(
              backgroundColor: AppColors.primaryOrange,
              leadingWidth: 45.w,
              toolbarHeight: 58.h,
              leading: Padding(
                padding: EdgeInsets.only(left: 22.w),
                child: SizedBox(
                  width: 26.w,
                  height: 26.h,
                  child: SvgPicture.asset(
                    Assets.svgDrawer,
                    colorFilter: const ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: 40.w,
                  height: 40.h,
                  child: IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Themes feature coming soon'),
                          backgroundColor: AppColors.primaryOrange,
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: SvgPicture.asset(
                      Assets.svgThemeBrush,
                      height: 26.h,
                      width: 26.w,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    context.push('/dashboard/settings');
                  },
                  icon: SvgPicture.asset(
                    Assets.svgSetting,
                    height: 26.h,
                    width: 26.w,
                    colorFilter: const ColorFilter.mode(
                      AppColors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                if (Platform.isIOS)
                  IconButton(
                    onPressed: () {
                      context.push('/dashboard/import-songs');
                    },
                    icon: Icon(Icons.add, color: AppColors.white, size: 28.r),
                  ),
              ],
            )
          : null,
      body: StreamBuilder<List<SongsModel>>(
        stream: _musicService.songsChanged,
        initialData: _musicService.songs,
        builder: (context, snapshot) {
          // Always check the current state, not just the snapshot
          final hasAny = _musicService.songs.isNotEmpty;
          final showMiniPlayer = hasAny;

          return Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: showMiniPlayer ? 74.h : 0,
                  ), // Space for MiniPlayerBar (which includes system nav bar padding)
                  child: screens[currentIndex],
                ),
              ),
              Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayerBar()),
            ],
          );
        },
      ),
      bottomNavigationBar: SizedBox(
        height: 95.h,
        child: BottomNavigationBar(
          selectedItemColor: AppColors.primaryOrange,
          unselectedItemColor: AppColors.black,
          selectedLabelStyle: TextStyle(
            fontSize: 12.sp,
            fontFamily: AppFonts.inter,
            fontWeight: AppFontWeights.regular,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12.sp,
            fontFamily: AppFonts.inter,
            fontWeight: AppFontWeights.regular,
          ),
          backgroundColor: AppColors.white,
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                Assets.svgHome,
                colorFilter: const ColorFilter.mode(
                  AppColors.black,
                  BlendMode.srcIn,
                ),
              ),
              label: 'Home',
              activeIcon: SvgPicture.asset(Assets.svgHome),
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(Assets.svgSearch),
              label: 'Search',
              activeIcon: SvgPicture.asset(
                Assets.svgSearch,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryOrange,
                  BlendMode.srcIn,
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(Assets.svgMusicLibrary),
              label: 'Library',
              activeIcon: SvgPicture.asset(
                Assets.svgMusicLibrary,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryOrange,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
