import 'dart:async';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';
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

class PlayerScreen extends StatefulWidget {
  final List<SongModel> songs;
  final int index;

  const PlayerScreen({super.key, required this.songs, required this.index});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final audioService = AudioService();
  bool isPlaying = true;
  late int currentIndex;
  StreamSubscription<bool>? _playingSubscription;
  double offsetY = 0;
  bool canDrag = false;

  String? _customTitle;
  String? _customArtist;
  String? _customArtPath;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.index;
    audioService.currentIndexNotifier.addListener(_onIndexChanged);
    _playingSubscription = audioService.player.playingStream.listen((playing) {
      if (mounted) setState(() => isPlaying = playing);
    });
    SongEditService().editNotifier.addListener(_onEditChanged);
    _loadEdit();
  }

  @override
  void dispose() {
    audioService.currentIndexNotifier.removeListener(_onIndexChanged);
    SongEditService().editNotifier.removeListener(_onEditChanged);
    _playingSubscription?.cancel();
    super.dispose();
  }

  void _onEditChanged() => _loadEdit();

  void _onIndexChanged() {
    if (mounted) {
      final newIndex = audioService.currentIndexNotifier.value ?? currentIndex;
      if (newIndex >= 0 && newIndex < widget.songs.length) {
        setState(() => currentIndex = newIndex);
        _loadEdit();
      }
    }
  }

  Future<void> _loadEdit() async {
    final safeIndex = currentIndex.clamp(0, widget.songs.length - 1);
    final songId = widget.songs[safeIndex].id;
    final edit = await SongEditService().getEdit(songId);
    if (mounted) {
      setState(() {
        _customTitle = edit?['title'];
        _customArtist = edit?['artist'];
        _customArtPath = edit?['artPath'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: GestureDetector(
        onVerticalDragStart: (details) {
          canDrag = details.globalPosition.dy < 400;
        },
        onVerticalDragUpdate: (details) {
          if (!canDrag) return;
          if (details.delta.dy > 0) {
            setState(() => offsetY += details.delta.dy);
          }
        },
        onVerticalDragEnd: (details) {
          if (!canDrag) return;
          if (offsetY > 200 || details.primaryVelocity! > 1000) {
            Navigator.pop(context);
          } else {
            setState(() => offsetY = 0);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          transform: Matrix4.translationValues(0, offsetY, 0),
          child: Scaffold(
            appBar: _buildAppBar(context),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _buildArtworkSection(context),
                const SizedBox(height: 50),
                _buildInfoSection(),
                AppSeekBar(audioService: audioService, isT: true),
                _buildControlsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
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
            final safeIndex = currentIndex.clamp(0, widget.songs.length - 1);
            SongOptionsBottomSheet.show(
              context,
              song: widget.songs[safeIndex],
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

  Widget _buildArtworkSection(BuildContext context) {
    final safeIndex = currentIndex.clamp(0, widget.songs.length - 1);
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
              id: widget.songs[safeIndex].id,
              size: 150,
              borderRadius: 20,
              customArtPath: _customArtPath,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final safeIndex = currentIndex.clamp(0, widget.songs.length - 1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: SongTitleWidget(
        songs: widget.songs,
        currentIndex: safeIndex,
        customTitle: _customTitle,
        customArtist: _customArtist,
      ),
    );
  }

  Widget _buildControlsSection() {
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
                    onPressed: () => _showPlaybackModeSheet(context, mode),
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
                  final safeIndex = currentIndex.clamp(
                    0,
                    widget.songs.length - 1,
                  );
                  showDialog(
                    context: context,
                    builder: (_) =>
                        AddToPlaylistDialog(songs: [widget.songs[safeIndex]]),
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

  // ─── Bottom Sheet ─────────────────────────────────────────────────────────────

  void _showPlaybackModeSheet(BuildContext context, PlaybackMode currentMode) {
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
                  // Handle bar
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
                  const SizedBox(height: 16),

                  // ─── 3 Mode Buttons ─────────────────────────────────────────
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
                              final queue = audioService.currentQueue;
                              if (queue.isNotEmpty) {
                                final first = queue[0];
                                audioService.playSong(
                                  first.data,
                                  title: first.title,
                                  artist: first.artist,
                                  index: 0,
                                  songId: first.id,
                                  queue: queue,
                                );
                              }
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
                              audioService.shuffledQueue = List<SongModel>.from(
                                audioService.currentQueue,
                              )..shuffle();
                              if (audioService.shuffledQueue.isNotEmpty) {
                                final first = audioService.shuffledQueue[0];
                                final originalIndex = audioService.currentQueue
                                    .indexOf(first);
                                audioService.playSong(
                                  first.data,
                                  title: first.title,
                                  artist: first.artist,
                                  index: originalIndex,
                                  songId: first.id,
                                  queue: audioService.currentQueue,
                                );
                              }
                              setSheetState(() {});
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ─── Songs Queue List ────────────────────────────────────────
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
                      child: ValueListenableBuilder<PlaybackMode>(
                        valueListenable: audioService.playbackModeNotifier,
                        builder: (context, mode, _) {
                          List<SongModel> displayQueue;
                          if (mode == PlaybackMode.repeatOne) {
                            final currentId =
                                audioService.currentSongIdNotifier.value;
                            displayQueue = audioService.currentQueue
                                .where((s) => s.id == currentId)
                                .toList();
                          } else if (mode == PlaybackMode.shuffle) {
                            displayQueue = audioService.shuffledQueue.isEmpty
                                ? audioService.currentQueue
                                : audioService.shuffledQueue;
                          } else {
                            displayQueue = audioService.currentQueue;
                          }

                          return ValueListenableBuilder<int?>(
                            valueListenable: audioService.currentSongIdNotifier,
                            builder: (context, currentSongId, _) {
                              return ValueListenableBuilder<bool>(
                                valueListenable: audioService.isPlayingNotifier,
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
                                          final originalIndex = audioService
                                              .currentQueue
                                              .indexOf(song);
                                          audioService.playSong(
                                            song.data,
                                            title: song.title,
                                            artist: song.artist,
                                            index: originalIndex,
                                            songId: song.id,
                                            queue: audioService.currentQueue,
                                          );
                                          Navigator.pop(context);
                                        },
                                        onMoreTap: () {
                                          Navigator.pop(context);
                                          AppNavigator.push(
                                            context,
                                            PlayerScreen(
                                              songs: audioService.currentQueue,
                                              index: audioService.currentQueue
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

  // ─── Mode Button Widget ───────────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
