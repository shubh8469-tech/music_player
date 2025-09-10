import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/screens/tabs/home/homeScreen.dart';
import 'package:music_app/screens/tabs/library/libraryScreen.dart';
import 'package:music_app/themes/color.dart';

import '../../generated/assets.dart';
import '../../themes/font.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;

  List<Widget> screens = [
    Homescreen(),
    Center(child: Text('Search Screen')),
    LibraryScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryOrange,
        leadingWidth: 45.w,
        toolbarHeight: 58.h,
        leading: Padding(
          padding: EdgeInsets.only(left: 22.w),
          child: SizedBox(width: 26.w, height: 26.h, child: SvgPicture.asset(Assets.svgDrawer, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn))),
        ),
        actions: [
          SizedBox(
            width: 40.w,
            height: 40.h,
            child: IconButton(onPressed: () {}, icon: SvgPicture.asset(Assets.svgThemeBrush, height: 26.h, width: 26.w)),
          ),
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(Assets.svgSetting, height: 26.h, width: 26.w, colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn)),
          ),
        ],
      ),
      body: screens[currentIndex],
      bottomNavigationBar: SizedBox(
        height: 80.h,
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
              icon: SvgPicture.asset(Assets.svgHome, colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn)),
              label: 'Home',
              activeIcon: SvgPicture.asset(Assets.svgHome),
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(Assets.svgSearch),
              label: 'Search',
              activeIcon: SvgPicture.asset(Assets.svgSearch, colorFilter: const ColorFilter.mode(AppColors.primaryOrange, BlendMode.srcIn)),
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(Assets.svgMusicLibrary),
              label: 'Library',
              activeIcon: SvgPicture.asset(Assets.svgMusicLibrary, colorFilter: const ColorFilter.mode(AppColors.primaryOrange, BlendMode.srcIn)),
            ),
          ],
        ),
      ),
    );
  }
}
