import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:photo_manager/photo_manager.dart';

import 'video_player_button.dart';
import 'video_player_progress.dart';

class VideoPlayerControls extends StatelessWidget {
  final AssetEntity asset;
  final Player player;
  final bool fullscreen;
  final VoidCallback onBack;
  final VoidCallback onSpeed;
  final VoidCallback onAspect;
  final VoidCallback onLock;
  final VoidCallback onFullscreen;
  final Future<void> Function(int seconds) onSeek;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const VideoPlayerControls({
    super.key,
    required this.asset,
    required this.player,
    required this.fullscreen,
    required this.onBack,
    required this.onSpeed,
    required this.onAspect,
    required this.onLock,
    required this.onFullscreen,
    required this.onSeek,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(child: _PlayerGradient()),
          _buildTopBar(),
          VideoPlayerProgress(
            player: player,
            fullscreen: fullscreen,
            locked: false,
            onFullscreen: onFullscreen,
            onLock: onLock,
            onSeek: onSeek,
            onPrevious: onPrevious,
            onNext: onNext,
          ),
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
          VideoPlayerButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
            filled: false,
          ),
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
          VideoPlayerButton(
            icon: Icons.speed_rounded,
            onTap: onSpeed,
            filled: false,
          ),
          const SizedBox(width: 8),
          VideoPlayerButton(
            icon: Icons.aspect_ratio_rounded,
            onTap: onAspect,
            filled: false,
          ),
        ],
      ),
    );
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
              Colors.black.withValues(alpha: 0.42),
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
