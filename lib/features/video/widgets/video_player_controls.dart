import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:photo_manager/photo_manager.dart';

import 'video_player_button.dart';

class VideoPlayerControls extends StatelessWidget {
  final AssetEntity asset;
  final Player player;
  final bool fullscreen;
  final VoidCallback onBack;
  final VoidCallback onBrightness;
  final VoidCallback onVolume;
  final VoidCallback onSpeed;
  final VoidCallback onAspect;
  final VoidCallback onLock;
  final VoidCallback onFullscreen;
  final Future<void> Function(int seconds) onSeek;

  const VideoPlayerControls({
    super.key,
    required this.asset,
    required this.player,
    required this.fullscreen,
    required this.onBack,
    required this.onBrightness,
    required this.onVolume,
    required this.onSpeed,
    required this.onAspect,
    required this.onLock,
    required this.onFullscreen,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(child: _PlayerGradient()),
          _buildTopBar(),
          _buildSideButtons(),
          _buildCenterControls(),
          _buildProgressBar(context),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 10,
      left: 12,
      right: 12,
      child: Row(
        children: [
          VideoPlayerButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<String>(
              future: asset.titleAsync,
              builder: (context, snapshot) => Text(
                snapshot.data ?? 'Video',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          VideoPlayerButton(icon: Icons.speed_rounded, onTap: onSpeed),
          const SizedBox(width: 8),
          VideoPlayerButton(icon: Icons.aspect_ratio_rounded, onTap: onAspect),
        ],
      ),
    );
  }

  Widget _buildSideButtons() {
    return Stack(
      children: [
        Positioned(
          left: 14,
          top: 0,
          bottom: 0,
          child: Center(
            child: VideoPlayerButton(
              icon: Icons.brightness_6_rounded,
              onTap: onBrightness,
            ),
          ),
        ),
        Positioned(
          right: 14,
          top: 0,
          bottom: 0,
          child: Center(
            child: StreamBuilder<double>(
              stream: player.stream.volume,
              initialData: player.state.volume,
              builder: (context, snapshot) => VideoPlayerButton(
                icon: (snapshot.data ?? 0) <= 0
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                onTap: onVolume,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterControls() {
    return Positioned.fill(
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VideoPlayerButton(
              icon: Icons.replay_10_rounded,
              size: 58,
              onTap: () => onSeek(-10),
            ),
            const SizedBox(width: 26),
            StreamBuilder<bool>(
              stream: player.stream.playing,
              initialData: player.state.playing,
              builder: (context, snapshot) => VideoPlayerButton(
                icon: snapshot.data == true
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 76,
                iconSize: 42,
                filled: true,
                onTap: player.playOrPause,
              ),
            ),
            const SizedBox(width: 26),
            VideoPlayerButton(
              icon: Icons.forward_10_rounded,
              size: 58,
              onTap: () => onSeek(10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
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
                      icon: fullscreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      onTap: onFullscreen,
                    ),
                    const Spacer(),
                    VideoPlayerButton(
                      icon: Icons.lock_outline_rounded,
                      onTap: onLock,
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

class _PlayerGradient extends StatelessWidget {
  const _PlayerGradient();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.62),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.72),
            ],
            stops: const [0, 0.52, 1],
          ),
        ),
      ),
    );
  }
}
