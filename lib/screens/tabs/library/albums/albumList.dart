import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/themes/color.dart';
import '../../../../commonWidgets/gradientCard.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../features/albums/bloc/album_bloc.dart';
import '../../../../generated/assets.dart';
import '../../../../themes/font.dart';
import '../../../../utills/globals.dart';
import 'sort_by_bottomsheet.dart';

class AlbumListScreen extends StatefulWidget {
  const AlbumListScreen({super.key});

  @override
  State<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends State<AlbumListScreen> {
  int selectedIndex = 0; // Default to Album Name
  int selectedOrder = 0; // 0 = ascending, 1 = descending
  String selectedAlbumSort = albumSortByItems[0].title;

  @override
  void initState() {
    super.initState();
    context.read<AlbumBloc>().add(const AlbumEvent.fetchAllAlbums());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 30.h,
          bottom: 1.h,
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    context.push('/dashboard/select-albums');
                  },
                  child: Row(
                    children: [
                      SvgPicture.asset(Assets.svgSongsCount),
                      SizedBox(width: 10.w),
                      BlocBuilder<AlbumBloc, AlbumState>(
                        builder: (context, state) {
                          return state.maybeWhen(
                            loaded: (albums, _) => Texts(
                              '${albums.length} Albums',
                              fontSize: 14.sp,
                              fontWeight: AppFontWeights.regular,
                              color: AppColors.textColor,
                            ),
                            orElse: () => Texts(
                              '0 Albums',
                              fontSize: 14.sp,
                              fontWeight: AppFontWeights.regular,
                              color: AppColors.textColor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Spacer(),
                SvgPicture.asset(Assets.svgFilter),
                SizedBox(width: 5.w),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(40),
                        ),
                      ),
                      isScrollControlled: true,
                      builder: (_) => BlocProvider.value(
                        value: context.read<AlbumBloc>(),
                        child: AlbumSortByBottomSheet(
                          selectedIndex: selectedIndex,
                          selectedOrder: selectedOrder,
                          onItemSelected: (index, order) {
                            setState(() {
                              selectedIndex = index;
                              selectedOrder = order;
                              selectedAlbumSort = albumSortByItems[index].title;
                            });
                            // Trigger Bloc sort event
                            context.read<AlbumBloc>().add(
                              AlbumEvent.sortAlbums(index, order),
                            );
                            // Close bottom sheet safely
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (Navigator.canPop(context))
                                Navigator.pop(context);
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Texts(
                        selectedAlbumSort,
                        fontSize: 14.sp,
                        fontWeight: AppFontWeights.regular,
                        color: AppColors.textColor,
                      ),
                      SizedBox(width: 10.w),
                      // Icon(
                      //   selectedOrder == 0
                      //       ? Icons.arrow_upward
                      //       : Icons.arrow_downward,
                      //   size: 16.sp,
                      // ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 25.h),
            Expanded(
              child: BlocBuilder<AlbumBloc, AlbumState>(
                builder: (context, state) {
                  return state.when(
                    initial: () => const SizedBox(),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    loaded: (albums, _) {
                      if (albums.isEmpty) {
                        return Center(
                          child: Texts(
                            'No albums found',
                            fontSize: 16.sp,
                            color: AppColors.mediumDarkGrey,
                          ),
                        );
                      }
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 5.h,
                          crossAxisSpacing: 20.w,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: albums.length,
                        itemBuilder: (context, index) {
                          final album = albums[index];
                          return GestureDetector(
                            onTap: () {
                              context.push(
                                '/dashboard/album-detail',
                                extra: album,
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GradientCard(
                                  height: 120.h,
                                  width: 120.w,
                                  colors: [
                                    AppColors.mildOrange.withValues(
                                      alpha: 0.21,
                                    ),
                                    AppColors.mildOrange,
                                  ],
                                  borderRadius: 13.r,
                                  iconAsset: Assets.svgAlbum,
                                  iconSize: 66.51.r,
                                  onTap: () {
                                    context.push(
                                      '/dashboard/album-detail',
                                      extra: album,
                                    );
                                  },
                                  margin: 0,
                                ),
                                SizedBox(height: 6.h),
                                SizedBox(
                                  width: 118.w,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Texts(
                                              album.name,
                                              fontFamily: AppFonts.inter,
                                              fontWeight: AppFontWeights.medium,
                                              fontSize: 14.sp,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Texts(
                                              '${album.songCount} songs',
                                              fontFamily: AppFonts.inter,
                                              fontWeight:
                                                  AppFontWeights.regular,
                                              fontSize: 10.sp,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 5.w),
                                      SvgPicture.asset(
                                        Assets.svgMenuIcon,
                                        height: 15.h,
                                        width: 15.w,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    error: (message) => Center(
                      child: Texts(
                        'Error: $message',
                        fontSize: 14.sp,
                        color: Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
