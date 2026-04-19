import 'package:flutter/material.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/services/audio/audio_service.dart';

class PlayPauseButton extends StatelessWidget {
  final AudioService audioService;
  final double size;
  final Color? color;

  const PlayPauseButton({
    super.key,
    required this.audioService,
    this.size = 30,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: audioService.isPlayingNotifier,
      builder: (context, isPlaying, _) {
        return IconButton(
          icon: Image.asset(
            isPlaying ? AppIcons.pause : AppIcons.playArrow,
            height: size,
            width: size,
          ),
          onPressed: () {
            if (isPlaying) {
              audioService.pause();
            } else {
              audioService.resume();
            }
          },
        );
      },
    );
  }
}
