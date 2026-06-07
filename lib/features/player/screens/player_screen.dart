import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/core/widgets/app_artwork.dart';
import 'package:music/core/widgets/app_seek_bar.dart';
import 'package:music/core/widgets/dialog/my_snack_bar.dart';
import 'package:music/core/widgets/song_tile_widget.dart';
import 'package:music/core/widgets/vinyl_widget.dart';
import 'package:music/features/home/widgets/song_options_bottom_sheet.dart';
import 'package:music/features/home/widgets/song_title_widget.dart';
import 'package:music/features/player/cubit/player_cubit.dart';
import 'package:music/features/player/cubit/player_state.dart';
import 'package:music/features/player/widgets/player_controls_widget.dart';
import 'package:music/features/player/widgets/sleep_timer_widget.dart';
import 'package:music/features/playlist/widgets/add_to_playlist_dialog.dart';

class PlayerScreen extends StatelessWidget {
  final List<SongModel> songs;
  final int index;
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  const PlayerScreen({
    super.key,
    required this.songs,
    required this.index,
    this.onDeleteSongs,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlayerCubit(songs: songs, index: index),
      child: PlayerView(onDeleteSongs: onDeleteSongs),
    );
  }
}

class PlayerView extends StatelessWidget {
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  const PlayerView({super.key, this.onDeleteSongs});

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        if (state.songs.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pop(context);
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final cubit = context.read<PlayerCubit>();

        return GestureDetector(
          onVerticalDragStart: (details) =>
              cubit.setCanDrag(details.globalPosition.dy < 400),
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
              extendBodyBehindAppBar: true,
              backgroundColor: AppColors.gray,

              appBar: _buildAppBar(context, state),

              body: Stack(
                fit: StackFit.expand,
                children: [
                  // 🖼️ الخلفية: صورة الاغنية
                  ValueListenableBuilder<int?>(
                    valueListenable: audioService.currentSongIdNotifier,
                    builder: (context, songId, _) {
                      return AppArtwork(
                        id:
                            songId ??
                            state
                                .songs[state.currentIndex.clamp(
                                  0,
                                  state.songs.length - 1,
                                )]
                                .id,
                        size: 500,
                        highQuality: true,
                        customArtPath: state.customArtPath,
                      );
                    },
                  ),

                  // 🌫️ البلر
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX:80, sigmaY: 80),
                    child: Container(color: Colors.black.withOpacity(0.3)),
                  ),

                  // 🌑 تدرج اسود في الاسفل عشان الازرار واضحة
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.45),
                        ],
                        stops: const [0.55, 1.0],
                      ),
                    ),
                  ),

                  // 🎵 المحتوى الرئيسي
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 60),

                      _buildArtworkSection(state, audioService),
                      const SizedBox(height: 50),

                      _buildInfoSection(state, audioService),

                      AppSeekBar(audioService: audioService, isT: true),

                      _buildControlsSection(context, state, audioService),

                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, PlayerState state) {
    final audioService = AudioService();
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.2),
      title: Text(
        "player.title".tr(),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.white, size: 26),
          onPressed: () {
            final favoritesService = FavoritesService();
            final safeIndex = state.currentIndex.clamp(
              0,
              state.songs.length - 1,
            );
            SongOptionsBottomSheet.show(
              context,
              song: state.songs[safeIndex],
              index: safeIndex,
              audioService: audioService,
              isFavoriteChecker: (s) => favoritesService.isFavorite(s.id),
              onToggleFavorite: (s) => favoritesService.toggleFavorite(s.id),
              playlist: false,
              onDeleteSongs: onDeleteSongs,
            );
          },
        ),
      ],
    );
  }

  Widget _buildArtworkSection(PlayerState state, AudioService audioService) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final artworkSize = isTablet ? 180.0 : 150.0;
        final vinylSize = isTablet ? 250.0 : 150.0;
        final horizontalOffset = isTablet ? 130.0 : 100.0;

        return ValueListenableBuilder<int?>(
          valueListenable: audioService.currentSongIdNotifier,
          builder: (context, currentSongId, _) {
            return Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, right: 10),
                    child: VinylWidget(
                      audioService: audioService,
                      size: vinylSize,
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20, right: horizontalOffset),
                    child: AppArtwork(
                      id:
                          currentSongId ??
                          state
                              .songs[state.currentIndex.clamp(
                                0,
                                state.songs.length - 1,
                              )]
                              .id,
                      size: artworkSize,
                      borderRadius: isTablet ? 24 : 16,
                      customArtPath: state.customArtPath,
                      highQuality: true,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoSection(PlayerState state, AudioService audioService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: ValueListenableBuilder<String?>(
        valueListenable: audioService.currentTitleNotifier,
        builder: (context, title, _) => ValueListenableBuilder<String?>(
          valueListenable: audioService.currentArtistNotifier,
          builder: (context, artist, _) => SongTitleWidget(
            songs: state.songs,
            currentIndex: state.currentIndex.clamp(0, state.songs.length - 1),
            customTitle: state.customTitle ?? title,
            customArtist: state.customArtist ?? artist,
          ),
        ),
      ),
    );
  }

  Widget _buildControlsSection(
    BuildContext context,
    PlayerState state,
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
                  IconData icon = switch (mode) {
                    PlaybackMode.sequential => Icons.repeat,
                    PlaybackMode.repeatOne => Icons.repeat_one,
                    PlaybackMode.shuffle => Icons.shuffle,
                  };

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
                  final safeIndex = state.currentIndex.clamp(
                    0,
                    state.songs.length - 1,
                  );
                  showDialog(
                    context: context,
                    builder: (_) =>
                        AddToPlaylistDialog(songs: [state.songs[safeIndex]]),
                  ).then((_) {
                    MySnackBar(context: context).showSnackBar(
                      "playlist_dialogs.add_to_playlist".tr(),
                      AppColors.blue,
                    );
                  });
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
    // باقي دالة الـ Bottom Sheet نفسها بالضبط زي ما كانت
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
                      color: AppColors.white.withOpacity(0.2),
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
                            onTap: () => audioService.setPlaybackMode(
                              PlaybackMode.sequential,
                            ),
                          ),
                          _buildModeButton(
                            icon: Icons.repeat_one,
                            label: 'player.repeat_one'.tr(),
                            isSelected: mode == PlaybackMode.repeatOne,
                            onTap: () => audioService.setPlaybackMode(
                              PlaybackMode.repeatOne,
                            ),
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
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (audioService.currentQueue.isNotEmpty) ...[
                    Divider(color: AppColors.white.withOpacity(0.1)),
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

                                  return ListView.builder(
                                    itemCount: displayQueue.length,
                                    itemBuilder: (context, index) {
                                      final song = displayQueue[index];
                                      return SongTileWidget(
                                        song: song,
                                        audioService: audioService,
                                        onTap: () {
                                          audioService.playSong(
                                            song.data,
                                            title: song.title,
                                            artist: song.artist,
                                            index: index,
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
                                              index: index,
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
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
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
              ? AppColors.blue.withOpacity(0.15)
              : AppColors.white.withOpacity(0.05),
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
                  : AppColors.white.withOpacity(0.4),
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.blue
                    : AppColors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
