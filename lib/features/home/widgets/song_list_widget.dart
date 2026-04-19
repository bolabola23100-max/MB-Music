import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
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

  Future<void> _playOrderedOnly() async {
    if (songs.isEmpty) return;

    onOptionSelected?.call(SongSortOption.orderedPlay);

    final queue = List<SongModel>.from(songs);
    final first = queue[0];

    await audioService.playSong(
      first.data,
      title: first.title,
      artist: first.artist,
      index: 0,
      songId: first.id,
      queue: queue,
    );
  }

  Future<void> _playRandomOnlyKeepOrder() async {
    if (songs.isEmpty) return;

    final queue = List<SongModel>.from(songs);
    final randomIndex = Random().nextInt(queue.length);
    final song = queue[randomIndex];

    await audioService.playSong(
      song.data,
      title: song.title,
      artist: song.artist,
      index: randomIndex,
      songId: song.id,
      queue: queue,
    );
  }

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
                    )
                  else
                    const Spacer(),

                  if (isf)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 40),
                      child: c(),
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
          child: ValueListenableBuilder<int?>(
            valueListenable: audioService.currentSongIdNotifier,
            builder: (context, currentSongId, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: audioService.isPlayingNotifier,
                builder: (context, isPlaying, _) {
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];

                      return SongTileWidget(
                        song: song,
                        isCurrent: currentSongId == song.id,
                        isPlaying: isPlaying,
                        onTap: () async {
                          final queue = List<SongModel>.from(songs);

                          if (openPlayerOnSongTap && context.mounted) {
                            AppNavigator.push(
                              context,
                              PlayerScreen(songs: queue, index: index),
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
                  );
                },
              );
            },
          ),
        ),

        if (showMiniPlayer)
          MiniPlayerWidget(songs: songs, audioService: audioService),
      ],
    );
  }

  Container c() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        // border: Border.all(color: Colors.grey),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: AppColors.blue.withValues(alpha: 0.4),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(15),
                bottomStart: Radius.circular(15),
              ),
            ),
            child: InkWell(
              onTap: _playOrderedOnly,
              customBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(15),
                  bottomStart: Radius.circular(15),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "settings.ordered".tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ الجزء الأيسر - تشغيل عشوائي
          Material(
            color: AppColors.blue.withValues(alpha: 0.6),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.only(
                topEnd: Radius.circular(15),
                bottomEnd: Radius.circular(15),
              ),
            ),
            child: InkWell(
              onTap: _playRandomOnlyKeepOrder,
              customBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.only(
                  topEnd: Radius.circular(15),
                  bottomEnd: Radius.circular(15),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shuffle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "settings.shuffle".tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
