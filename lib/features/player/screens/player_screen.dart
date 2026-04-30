import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/core/widgets/app_artwork.dart';
import 'package:music/core/widgets/app_seek_bar.dart';
import 'package:music/core/widgets/song_tile_widget.dart';
import 'package:music/core/widgets/vinyl_widget.dart';
import 'package:music/features/home/widgets/song_options_bottom_sheet.dart';
import 'package:music/features/player/widgets/player_controls_widget.dart';
import 'package:music/features/player/widgets/sleep_timer_widget.dart';
import 'package:music/features/home/widgets/song_title_widget.dart';
import 'package:music/features/playlist/widgets/add_to_playlist_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/features/player/cubit/player_cubit.dart';
import 'package:music/features/player/cubit/player_state.dart';

class PlayerScreen extends StatelessWidget {
  final List<SongModel> songs;
  final int index;

  const PlayerScreen({super.key, required this.songs, required this.index});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerCubit(songs: songs, index: index),
      child: const PlayerView(),
    );
  }
}

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        final cubit = context.read<PlayerCubit>();
        return Directionality(
          textDirection: ui.TextDirection.ltr,
          child: GestureDetector(
            onVerticalDragStart: (details) {
              cubit.setCanDrag(details.globalPosition.dy < 400);
            },
            onVerticalDragUpdate: (details) {
              if (!state.canDrag) return;
              cubit.updateDrag(details.delta.dy);
            },
            onVerticalDragEnd: (details) {
              if (!state.canDrag) return;
              if (state.offsetY > 200 || details.primaryVelocity! > 1000) {
                Navigator.pop(context);
              } else {
                cubit.resetDrag();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: Matrix4.translationValues(0, state.offsetY, 0),
              child: Scaffold(
                appBar: _buildAppBar(
                  context,
                  state.songs,
                  state.currentIndex,
                  audioService,
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildArtworkSection(
                      state.songs,
                      state.currentIndex,
                      state.customArtPath,
                      audioService,
                    ),
                    const SizedBox(height: 50),
                    _buildInfoSection(
                      state.songs,
                      state.currentIndex,
                      state.customTitle,
                      state.customArtist,
                      audioService,
                    ),
                    AppSeekBar(audioService: audioService, isT: true),
                    _buildControlsSection(
                      context,
                      state.songs,
                      state.currentIndex,
                      audioService,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    List<SongModel> songs,
    int currentIndex,
    AudioService audioService,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: Text(
        "player.title".tr(),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.white),
          onPressed: () {
            final favoritesService = FavoritesService();
            final safeIndex = currentIndex.clamp(0, songs.length - 1);
            SongOptionsBottomSheet.show(
              context,
              song: songs[safeIndex],
              index: safeIndex,
              audioService: audioService,
              isFavoriteChecker: (s) => favoritesService.isFavorite(s.id),
              onToggleFavorite: (s) => favoritesService.toggleFavorite(s.id),
              playlist: false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildArtworkSection(
    List<SongModel> songs,
    int currentIndex,
    String? customArtPath,
    AudioService audioService,
  ) {
    return ValueListenableBuilder<int?>(
      valueListenable: audioService.currentSongIdNotifier,
      builder: (context, currentSongId, _) {
        return Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 5, right: 10),
                child: VinylWidget(audioService: audioService, size: 130),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 140),
                child: AppArtwork(
                  id:
                      currentSongId ??
                      songs[currentIndex.clamp(0, songs.length - 1)].id,
                  size: 150,
                  borderRadius: 20,
                  customArtPath: customArtPath,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoSection(
    List<SongModel> songs,
    int currentIndex,
    String? customTitle,
    String? customArtist,
    AudioService audioService,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: ValueListenableBuilder<String?>(
        valueListenable: audioService.currentTitleNotifier,
        builder: (context, title, _) => ValueListenableBuilder<String?>(
          valueListenable: audioService.currentArtistNotifier,
          builder: (context, artist, _) => SongTitleWidget(
            songs: songs,
            currentIndex: currentIndex.clamp(0, songs.length - 1),
            customTitle: customTitle ?? title,
            customArtist: customArtist ?? artist,
          ),
        ),
      ),
    );
  }

  Widget _buildControlsSection(
    BuildContext context,
    List<SongModel> songs,
    int currentIndex,
    AudioService audioService,
  ) {
    return Column(
      children: [
        PlayerControlsWidget(
          audioService: audioService,
          onPlayNext: audioService.playNext,
          onPlayPrevious: audioService.playPrevious,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<PlaybackMode>(
                valueListenable: audioService.playbackModeNotifier,
                builder: (context, mode, _) {
                  IconData icon;
                  switch (mode) {
                    case PlaybackMode.sequential:
                      icon = Icons.repeat;
                      break;
                    case PlaybackMode.repeatOne:
                      icon = Icons.repeat_one;
                      break;
                    case PlaybackMode.shuffle:
                      icon = Icons.shuffle;
                      break;
                  }
                  return IconButton(
                    icon: Icon(icon, color: AppColors.white, size: 28),
                    onPressed: () =>
                        _showPlaybackModeSheet(context, mode, audioService),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.playlist_add,
                  color: AppColors.white,
                  size: 28,
                ),
                onPressed: () {
                  final safeIndex = currentIndex.clamp(0, songs.length - 1);
                  showDialog(
                    context: context,
                    builder: (_) =>
                        AddToPlaylistDialog(songs: [songs[safeIndex]]),
                  );
                },
              ),
              SleepTimerWidget(audioService: audioService),
            ],
          ),
        ),
      ],
    );
  }

  void _showPlaybackModeSheet(
    BuildContext context,
    PlaybackMode currentMode,
    AudioService audioService,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.gray,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'player.playback_mode'.tr(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ValueListenableBuilder<PlaybackMode>(
                    valueListenable: audioService.playbackModeNotifier,
                    builder: (context, mode, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildModeButton(
                            icon: Icons.repeat,
                            label: 'player.sequential'.tr(),
                            isSelected: mode == PlaybackMode.sequential,
                            onTap: () {
                              audioService.setPlaybackMode(
                                PlaybackMode.sequential,
                              );
                              setSheetState(() {});
                            },
                          ),
                          _buildModeButton(
                            icon: Icons.repeat_one,
                            label: 'player.repeat_one'.tr(),
                            isSelected: mode == PlaybackMode.repeatOne,
                            onTap: () {
                              audioService.setPlaybackMode(
                                PlaybackMode.repeatOne,
                              );
                              setSheetState(() {});
                            },
                          ),
                          _buildModeButton(
                            icon: Icons.shuffle,
                            label: 'player.shuffle'.tr(),
                            isSelected: mode == PlaybackMode.shuffle,
                            onTap: () {
                              audioService.setPlaybackMode(
                                PlaybackMode.shuffle,
                              );

                              final currentQueue = List<SongModel>.from(
                                audioService.currentQueue,
                              );
                              final currentId =
                                  audioService.currentSongIdNotifier.value;

                              SongModel? currentSong;
                              if (currentId != null) {
                                try {
                                  currentSong = currentQueue.firstWhere(
                                    (s) => s.id == currentId,
                                  );
                                } catch (_) {}
                              }

                              if (currentSong != null) {
                                currentQueue.removeWhere(
                                  (s) => s.id == currentId,
                                );
                                currentQueue.shuffle();
                                currentQueue.insert(0, currentSong);

                                audioService.shuffledQueue = currentQueue;
                                audioService.updateQueueAndKeepPlaying(
                                  currentQueue,
                                  0,
                                );
                              } else {
                                currentQueue.shuffle();
                                audioService.shuffledQueue = currentQueue;

                                if (currentQueue.isNotEmpty) {
                                  final first = currentQueue[0];
                                  audioService.playSong(
                                    first.data,
                                    title: first.title,
                                    artist: first.artist,
                                    index: 0,
                                    songId: first.id,
                                    queue: currentQueue,
                                  );
                                }
                              }
                              setSheetState(() {});
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (audioService.currentQueue.isNotEmpty) ...[
                    Divider(color: AppColors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'player.playing_queue'.tr(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 300,
                      child: ValueListenableBuilder<List<SongModel>>(
                        valueListenable: audioService.currentQueueNotifier,
                        builder: (context, currentQueue, _) {
                          return ValueListenableBuilder<List<SongModel>>(
                            valueListenable: audioService.shuffledQueueNotifier,
                            builder: (context, shuffledQueue, _) {
                              return ValueListenableBuilder<PlaybackMode>(
                                valueListenable:
                                    audioService.playbackModeNotifier,
                                builder: (context, mode, _) {
                                  List<SongModel> displayQueue;
                                  if (mode == PlaybackMode.repeatOne) {
                                    final currentId = audioService
                                        .currentSongIdNotifier
                                        .value;
                                    displayQueue = currentQueue
                                        .where((s) => s.id == currentId)
                                        .toList();
                                  } else if (mode == PlaybackMode.shuffle) {
                                    displayQueue = shuffledQueue.isEmpty
                                        ? currentQueue
                                        : shuffledQueue;
                                  } else {
                                    displayQueue = currentQueue;
                                  }

                                  return ValueListenableBuilder<int?>(
                                    valueListenable:
                                        audioService.currentSongIdNotifier,
                                    builder: (context, currentSongId, _) {
                                      return ValueListenableBuilder<bool>(
                                        valueListenable:
                                            audioService.isPlayingNotifier,
                                        builder: (context, isPlaying, _) {
                                          return ListView.builder(
                                            itemCount: displayQueue.length,
                                            itemBuilder: (context, index) {
                                              final song = displayQueue[index];
                                              final isCurrentSong =
                                                  song.id == currentSongId;
                                              return SongTileWidget(
                                                song: song,
                                                isCurrent: isCurrentSong,
                                                isPlaying: isPlaying,
                                                onTap: () {
                                                  final playIndex = displayQueue
                                                      .indexOf(song);
                                                  audioService.playSong(
                                                    song.data,
                                                    title: song.title,
                                                    artist: song.artist,
                                                    index: playIndex,
                                                    songId: song.id,
                                                    queue: displayQueue,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                onMoreTap: () {
                                                  Navigator.pop(context);
                                                  AppNavigator.push(
                                                    context,
                                                    PlayerScreen(
                                                      songs: displayQueue,
                                                      index: displayQueue
                                                          .indexOf(song),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue.withValues(alpha: 0.15)
              : AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.blue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.blue
                  : AppColors.white.withValues(alpha: 0.4),
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.blue
                    : AppColors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
