import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/song_select_screen.dart';
import 'package:music/core/widgets/song_tile_widget.dart';

import 'package:music/features/home/widgets/mini_player_widget.dart';
import 'package:music/features/home/widgets/song_options_bottom_sheet.dart';
import 'package:music/features/player/screens/player_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';

enum SongSortOption { oldestFirst, newestFirst, orderedPlay, shufflePlay }

class SongListWidget extends StatelessWidget {
  final List<SongModel> songs;
  final AudioService audioService;
  final bool Function(SongModel song)? isFavoriteChecker;
  final Future<void> Function(SongModel song)? onToggleFavorite;
  final String title;
  final String subtitle;
  final double titleFontSize;
  final void Function(SongSortOption option)? onOptionSelected;
  final bool showMiniPlayer;
  final bool isTitle;
  final bool isf;
  final bool openPlayerOnSongTap;
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  const SongListWidget({
    super.key,
    required this.songs,
    required this.audioService,
    this.isFavoriteChecker,
    this.onToggleFavorite,
    this.title = "Songs",
    this.subtitle = "TRACKS IN YOUR ETHER",
    this.titleFontSize = 40,
    this.onOptionSelected,
    this.showMiniPlayer = true,
    this.isTitle = true,
    this.openPlayerOnSongTap = true,
    this.isf = true,
    this.onDeleteSongs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 16,
                end: 16,
                top: 8,
              ),
              child: Row(
                children: [
                  if (isTitle)
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.blue,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isTitle)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 16, top: 8),
                child: Text(
                  "${songs.length} $subtitle",
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 15),
        Expanded(
          // ✅ لا ValueListenableBuilder هنا — كل SongTileWidget يستمع بنفسه
          // ✅ نتيجة: لما تتغير الأغنية، tile واحد فقط يُعاد بناؤه بدلاً من القائمة كلها
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: songs.length,
            // ✅ cacheExtent: يبني الـ tiles مسبقاً خارج الشاشة لتمرير أسلس
            cacheExtent: 500,
            itemBuilder: (context, index) {
              final song = songs[index];

              return SongTileWidget(
                song: song,
                audioService: audioService,
                onTap: () async {
                  final queue = List<SongModel>.from(songs);

                  if (openPlayerOnSongTap && context.mounted) {
                    AppNavigator.push(
                      context,
                      PlayerScreen(
                        songs: queue,
                        index: index,
                        onDeleteSongs: onDeleteSongs,
                      ),
                    );
                  }

                  await audioService.playSong(
                    song.data,
                    title: song.title,
                    artist: song.artist,
                    index: index,
                    songId: song.id,
                    queue: queue,
                  );
                },
                onLongPress: () => SongSelectScreen.show(
                  context,
                  songs,
                  audioService,
                  isFavoriteChecker,
                  onToggleFavorite,
                  initialSelectedSongId: song.id,
                  onDeleteSongs: onDeleteSongs,
                ),

                onMoreTap: () => SongOptionsBottomSheet.show(
                  context,
                  song: song,
                  index: index,
                  audioService: audioService,
                  isFavoriteChecker: isFavoriteChecker,
                  onToggleFavorite: onToggleFavorite,
                  onDeleteSongs: onDeleteSongs,
                ),
              );
            },
          ),
        ),

        if (showMiniPlayer)
          MiniPlayerWidget(songs: songs, audioService: audioService),
      ],
    );
  }
}
