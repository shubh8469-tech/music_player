import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:music_app/screens/tabs/library/songs/songsList.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';

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
            labelColor: AppColors.blackText,
            unselectedLabelColor: AppColors.blackText,
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
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(width: 3.0, color: Colors.orange),
              insets: EdgeInsets.symmetric(horizontal: -8),
            ),
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SongsList(),
                Center(child: Text('Content for Tab 2')),
                Center(child: Text('Content for Tab 3')),
                Center(child: Text('Content for Tab 4')),
                Center(child: Text('Content for Tab 5')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
