import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'video_player_button.dart';

class VideoPlayerProgress extends StatelessWidget {
  final Player player;
  final bool fullscreen;
  final bool locked;
  final VoidCallback onFullscreen;
  final VoidCallback onLock;
  final Future<void> Function(int seconds) onSeek;

  const VideoPlayerProgress({
    super.key,
    required this.player,
    required this.fullscreen,
    required this.locked,
    required this.onFullscreen,
    required this.onLock,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return Positioned(
        left: 18,
        bottom: 12,
        child: VideoPlayerButton(
          icon: Icons.lock_open_rounded,
          onTap: onLock,
        ),
      );
    }

    return Positioned(
      left: 18,
      right: 18,
      bottom: 12,
      child: StreamBuilder<Duration>(
        stream: player.stream.position,
        initialData: player.state.position,
        builder: (context, positionSnapshot) => StreamBuilder<Duration>(
          stream: player.stream.duration,
          initialData: player.state.duration,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            final max = duration.inMilliseconds.toDouble();
            final value = max <= 0
                ? 0.0
                : position.inMilliseconds
                    .clamp(0, duration.inMilliseconds)
                    .toDouble();

            return Column(
              children: [
                Row(
                  children: [
                    Text(_formatDuration(position), style: _timeStyle),
                    const Spacer(),
                    Text(_formatDuration(duration), style: _timeStyle),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: const Color(0xFFE91E63),
                    thumbColor: Colors.white,
                    inactiveTrackColor: Colors.white38,
                    overlayColor: Colors.white24,
                  ),
                  child: Slider(
                    min: 0,
                    max: max > 0 ? max : 1,
                    value: max > 0 ? value : 0,
                    onChanged: max <= 0
                        ? null
                        : (next) => player.seek(
                              Duration(milliseconds: next.round()),
                            ),
                  ),
                ),
                Row(
                  children: [
                    VideoPlayerButton(
                      icon: Icons.lock_outline_rounded,
                      onTap: onLock,
                    ),
                    const Spacer(),
                    VideoPlayerButton(
                      icon: Icons.replay_10_rounded,
                      size: 44,
                      onTap: () => onSeek(-10),
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<bool>(
                      stream: player.stream.playing,
                      initialData: player.state.playing,
                      builder: (context, snapshot) => VideoPlayerButton(
                        icon: snapshot.data == true
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 52,
                        iconSize: 30,
                        filled: false,
                        onTap: player.playOrPause,
                      ),
                    ),
                    const SizedBox(width: 12),
                    VideoPlayerButton(
                      icon: Icons.forward_10_rounded,
                      size: 44,
                      onTap: () => onSeek(10),
                    ),
                    const Spacer(),
                    VideoPlayerButton(
                      icon: fullscreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      onTap: onFullscreen,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static const _timeStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static String _formatDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
