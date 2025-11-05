import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/artists/domain/entities/artist.dart';
import 'package:music_app/features/songs/data/models/song_model.dart';
import 'package:music_app/screens/tabs/music_service.dart';
import 'package:music_app/themes/color.dart';
import 'package:music_app/themes/font.dart';
import '../../../../commonWidgets/MusicListTile.dart';
import '../../../../commonWidgets/textWidget.dart';
import '../../../../features/artists/domain/repositories/artist_repository.dart';
import '../../../../generated/assets.dart';
import '../../../../core/di/injection.dart';
import '../../../play_song/playing_song_screen.dart';
import '../widgets/mini_player_bar.dart';

class ArtistDetailScreen extends StatefulWidget {
  final Artist artist;
  const ArtistDetailScreen({super.key, required this.artist});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  final _repo = locator<ArtistRepository>();
  final musicService = MusicPlayerService();

  List<SongsModel> _songs = [];

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final songs = await _repo.getSongsForArtist(widget.artist.id!);
    _songs = songs.cast<SongsModel>();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textColor),
          onPressed: () => context.pop(),
        ),
        title: Texts(widget.artist.name, fontSize: 18.sp, fontWeight: AppFontWeights.semiBold, color: AppColors.textColor),
        actions: [IconButton(
          icon: SvgPicture.asset(Assets.svgMenuIcon), 
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Artist menu coming soon'),
                backgroundColor: AppColors.primaryOrange,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        )],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  children: [
                    SvgPicture.asset(Assets.svgSongsCount),
                    SizedBox(width: 10.w),
                    Texts('${_songs.length} Songs', fontSize: 14.sp, fontWeight: AppFontWeights.regular, color: AppColors.textColor),
                    Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_songs.isNotEmpty) {
                          await musicService.setPlaylist(_songs, startIndex: 0, autoPlay: true);
                          await musicService.play();
                        }
                      },
                      icon: Icon(Icons.play_arrow, size: 20.r),
                      label: Texts('Play All', fontSize: 14.sp, fontWeight: AppFontWeights.medium),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<SongsModel>>(
                  stream: musicService.songsChanged,
                  initialData: musicService.songs,
                  builder: (context, snapshot) {
                    // Always check the current state, not just the snapshot
                    final hasAny = musicService.songs.isNotEmpty;
                    final showMiniPlayer = hasAny;

                    return _songs.isEmpty
                        ? Center(
                            child: Texts('No songs by this artist', fontSize: 16.sp, color: AppColors.mediumDarkGrey),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              left: 20.w,
                              right: 20.w,
                              bottom: showMiniPlayer ? 74.h : 10.h, // Space for MiniPlayerBar (which includes system nav bar padding)
                            ),
                            itemCount: _songs.length,
                            itemBuilder: (context, index) {
                              final song = _songs[index];
                              return MusicListTile(
                                margin: 7.w,
                                height: 66.h,
                                borderRadius: 10.r,
                                backgroundColor: AppColors.musicTileBackgroundColor,
                                cardHeight: 50.h,
                                cardWidth: 50.w,
                                cardRadius: 7.r,
                                cardIconAsset: Assets.svgMusicIcon,
                                cardIconSize: 32.r,
                                title: song.title,
                                subtitle: song.album,
                                trailingIconAsset: Assets.svgMenuIcon,
                                trailingIconHeight: 19.5.h,
                                trailingIconWidth: 3.w,
                                trailingMargin: 10.w,
                                onTap: () async {
                                  if(musicService.songs.isNotEmpty && musicService.songs[musicService.currentIndex].id == song.id && musicService.isPlaying){
                                    context.push(
                                      '/dashboard/playing',
                                      extra: PlayingSongArgs(songs: musicService.songs),
                                    );
                                  }
                                  else{
                                    await musicService.setPlaylist(_songs, startIndex: index, autoPlay: true);
                                    await musicService.play();
                                  }
                                },
                                onPlayTap: () async {
                                  if(musicService.songs.isNotEmpty && musicService.songs[musicService.currentIndex].id == song.id && musicService.isPlaying){
                                    context.push(
                                      '/dashboard/playing',
                                      extra: PlayingSongArgs(songs: musicService.songs),
                                    );
                                  }
                                  else{
                                    await musicService.setPlaylist(_songs, startIndex: index, autoPlay: true);
                                    await musicService.play();
                                  }
                                },
                              );
                            },
                          );
                  },
                ),
              ),
            ],
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayerBar()),
        ],
      ),
    );
  }
}
