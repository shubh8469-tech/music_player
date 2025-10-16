import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/themes/color.dart';
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../features/folders/bloc/folder_bloc.dart';
import '../../../../generated/assets.dart';
import '../../../../themes/font.dart';

class FolderListScreen extends StatefulWidget {
  const FolderListScreen({super.key});

  @override
  State<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends State<FolderListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<FolderBloc>().add(const FolderEvent.fetchAllFolders());
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  SvgPicture.asset(Assets.svgSongsCount),
                  SizedBox(width: 10.w),
                  BlocBuilder<FolderBloc, FolderState>(
                    builder: (context, state) {
                      return state.maybeWhen(
                        loaded:
                            (folders, _) => Texts(
                              '${folders.length} Folders',
                              fontSize: 14.sp,
                              fontWeight: AppFontWeights.regular,
                              color: AppColors.textColor,
                            ),
                        orElse:
                            () => Texts(
                              '0 Folders',
                              fontSize: 14.sp,
                              fontWeight: AppFontWeights.regular,
                              color: AppColors.textColor,
                            ),
                      );
                    },
                  ),
                  Spacer(),
                  SvgPicture.asset(Assets.svgFilter),
                  SizedBox(width: 5.w),
                  Texts(
                    'Name',
                    fontSize: 14.sp,
                    fontWeight: AppFontWeights.regular,
                    color: AppColors.textColor,
                  ),
                  SizedBox(width: 15.w),
                  Icon(Icons.arrow_upward),
                ],
              ),
              SizedBox(height: 25.h),
              BlocBuilder<FolderBloc, FolderState>(
                builder: (context, state) {
                  return state.when(
                    initial: () => const SizedBox(),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    loaded: (folders, _) {
                      if (folders.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50.h),
                            child: Texts(
                              'No folders found',
                              fontSize: 16.sp,
                              color: AppColors.mediumDarkGrey,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children:
                            folders.map((folder) {
                              return MusicListTile(
                                margin: 7.w,
                                height: 66.h,
                                borderRadius: 10.r,
                                backgroundColor:
                                    AppColors.musicTileBackgroundColor,
                                cardHeight: 50.h,
                                cardWidth: 50.w,
                                cardRadius: 7.r,
                                cardIconAsset: Assets.svgDirectory,
                                cardIconSize: 32.r,
                                isSvgColorNeeded: false,
                                title: folder.name,
                                subtitle: '${folder.songCount} Songs',
                                trailingIconAsset: Assets.svgMenuIcon,
                                trailingIconHeight: 22.5.h,
                                trailingIconWidth: 3.w,
                                trailingMargin: 10.w,
                                onTap: () {
                                  context.push(
                                    '/dashboard/folder-detail',
                                    extra: folder,
                                  );
                                },
                                onPlayTap: () {
                                  // Load songs and play
                                  context.read<FolderBloc>().add(
                                    FolderEvent.fetchSongsForFolder(folder.id!),
                                  );
                                },
                              );
                            }).toList(),
                      );
                    },
                    error:
                        (message) => Center(
                          child: Texts(
                            'Error: $message',
                            fontSize: 14.sp,
                            color: Colors.red,
                          ),
                        ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
