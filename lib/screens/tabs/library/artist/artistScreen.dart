import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/themes/color.dart';
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../features/artists/bloc/artist_bloc.dart';
import '../../../../generated/assets.dart';
import '../../../../themes/font.dart';

class ArtistListScreen extends StatefulWidget {
  const ArtistListScreen({super.key});

  @override
  State<ArtistListScreen> createState() => _ArtistListScreenState();
}

class _ArtistListScreenState extends State<ArtistListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ArtistBloc>().add(const ArtistEvent.fetchAllArtists());
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
                  BlocBuilder<ArtistBloc, ArtistState>(
                    builder: (context, state) {
                      return state.maybeWhen(
                        loaded:
                            (artists, _) => Texts(
                              '${artists.length} Artists',
                              fontSize: 14.sp,
                              fontWeight: AppFontWeights.regular,
                              color: AppColors.textColor,
                            ),
                        orElse:
                            () => Texts(
                              '0 Artists',
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
              BlocBuilder<ArtistBloc, ArtistState>(
                builder: (context, state) {
                  return state.when(
                    initial: () => const SizedBox(),
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    loaded: (artists, _) {
                      if (artists.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50.h),
                            child: Texts(
                              'No artists found',
                              fontSize: 16.sp,
                              color: AppColors.mediumDarkGrey,
                            ),
                          ),
                        );
                      }
                      return Column(
                        children:
                            artists.map((artist) {
                              return MusicListTile(
                                margin: 7.w,
                                height: 66.h,
                                borderRadius: 10.r,
                                backgroundColor:
                                    AppColors.musicTileBackgroundColor,
                                cardHeight: 50.h,
                                cardWidth: 50.w,
                                cardRadius: 100.r,
                                cardIconAsset: Assets.svgMusicIcon,
                                isSvgColorNeeded: false,
                                cardIconSize: 32.r,
                                title: artist.name,
                                subtitle:
                                    '${artist.albumCount} Album${artist.albumCount != 1 ? 's' : ''} - ${artist.songCount} Songs',
                                trailingIconAsset: Assets.svgMenuIcon,
                                trailingIconHeight: 22.5.h,
                                trailingIconWidth: 3.w,
                                trailingMargin: 10.w,
                                onTap: () {
                                  context.push(
                                    '/dashboard/artist-detail',
                                    extra: artist,
                                  );
                                },
                                onPlayTap: () {
                                  // Load songs and play
                                  context.read<ArtistBloc>().add(
                                    ArtistEvent.fetchSongsForArtist(artist.id!),
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
