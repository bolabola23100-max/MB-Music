import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/song_tile_widget.dart';
import 'package:music/features/player/screens/player_screen.dart';

class PlaybackModeSheet extends StatelessWidget {
  const PlaybackModeSheet({super.key, required this.audioService});

  final AudioService audioService;

  static Future<void> show(BuildContext context, AudioService audioService) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PlaybackModeSheet(audioService: audioService),
    );
  }

  List<SongModel> _displayQueue(PlaybackMode mode) {
    final queue = audioService.currentQueue;
    if (mode == PlaybackMode.repeatOne) {
      final id = audioService.currentSongIdNotifier.value;
      return queue.where((song) => song.id == id).toList();
    }
    if (mode == PlaybackMode.shuffle) {
      return audioService.shuffledQueue.isEmpty ? queue : audioService.shuffledQueue;
    }
    return queue;
  }

  void _enableShuffle() {
    final queue = List<SongModel>.from(audioService.currentQueue);
    final currentId = audioService.currentSongIdNotifier.value;
    SongModel? current;

    if (currentId != null) {
      for (final song in queue) {
        if (song.id == currentId) {
          current = song;
          break;
        }
      }
    }

    if (current != null) {
      queue.removeWhere((song) => song.id == currentId);
      queue.shuffle();
      queue.insert(0, current);
      audioService.shuffledQueue = queue;
      audioService.updateQueueAndKeepPlaying(queue, 0);
    } else {
      queue.shuffle();
      audioService.shuffledQueue = queue;
    }
  }

  Widget _modeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 78,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue.withValues(alpha: .15) : AppColors.white.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.blue.withValues(alpha: .7) : AppColors.white.withValues(alpha: .06),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? AppColors.blue : AppColors.white.withValues(alpha: .45)),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.blue : AppColors.white.withValues(alpha: .5),
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * .35).clamp(160.0, 350.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width > 550 ? 500 : double.infinity),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.gray,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.white.withValues(alpha: .08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Text(
                  'player.playback_mode'.tr(),
                  style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                ValueListenableBuilder<PlaybackMode>(
                  valueListenable: audioService.playbackModeNotifier,
                  builder: (context, mode, _) => Row(
                    children: [
                      _modeButton(
                        icon: Icons.repeat,
                        label: 'player.sequential'.tr(),
                        selected: mode == PlaybackMode.sequential,
                        onTap: () => audioService.setPlaybackMode(PlaybackMode.sequential),
                      ),
                      const SizedBox(width: 8),
                      _modeButton(
                        icon: Icons.repeat_one,
                        label: 'player.repeat_one'.tr(),
                        selected: mode == PlaybackMode.repeatOne,
                        onTap: () => audioService.setPlaybackMode(PlaybackMode.repeatOne),
                      ),
                      const SizedBox(width: 8),
                      _modeButton(
                        icon: Icons.shuffle,
                        label: 'player.shuffle'.tr(),
                        selected: mode == PlaybackMode.shuffle,
                        onTap: _enableShuffle,
                      ),
                    ],
                  ),
                ),
                if (audioService.currentQueue.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: AppColors.white.withValues(alpha: .08)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'player.playing_queue'.tr(),
                      style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: height,
                    child: ValueListenableBuilder<List<SongModel>>(
                      valueListenable: audioService.currentQueueNotifier,
                      builder: (context, _, __) => ValueListenableBuilder<List<SongModel>>(
                        valueListenable: audioService.shuffledQueueNotifier,
                        builder: (context, _, __) => ValueListenableBuilder<PlaybackMode>(
                          valueListenable: audioService.playbackModeNotifier,
                          builder: (context, mode, _) {
                            final queue = _displayQueue(mode);
                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: queue.length,
                              itemBuilder: (context, index) {
                                final song = queue[index];
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
                                      queue: queue,
                                    );
                                    AppNavigator.pop(context);
                                  },
                                  onMoreTap: () {
                                    AppNavigator.pop(context);
                                    AppNavigator.push(context, PlayerScreen(songs: queue, index: index));
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
