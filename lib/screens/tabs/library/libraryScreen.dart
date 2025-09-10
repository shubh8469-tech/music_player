import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_app/screens/tabs/library/playlists/playlist.dart';
import 'package:music_app/screens/tabs/library/songs/songsList.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

import 'albums/albumList.dart';
import 'artist/artistScreen.dart';
import 'folders/folders.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {

  late TabController _tabController;
  final List<String> _tabs = ["SONGS", "PLAYLISTS", "FOLDERS", "ALBUMS", "ARTISTS"];

  @override
  void initState() {
    _tabController = TabController(length: _tabs.length, vsync: this);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.textColor,
            unselectedLabelColor: AppColors.textColor,
            labelStyle: TextStyle(
              fontSize: 15.sp,
              fontWeight: AppFontWeights.medium,
              fontFamily: AppFonts.inter,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 15.sp,
              fontWeight: AppFontWeights.regular,
              fontFamily: AppFonts.inter,
            ),
            isScrollable: true,
            padding: EdgeInsets.zero,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.0.w, color: Colors.orange),
              insets: EdgeInsets.symmetric(horizontal: -8.w),
            ),
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SongsList(),
                PlayListScreen(),
                FolderListScreen(),
                AlbumListScreen(),
                ArtistListScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
