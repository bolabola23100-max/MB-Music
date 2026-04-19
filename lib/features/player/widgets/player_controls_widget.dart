import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/play_pause_button.dart';

class PlayerControlsWidget extends StatelessWidget {
  const PlayerControlsWidget({
    super.key,
    required this.audioService,
    required this.onPlayNext,
    required this.onPlayPrevious,
  });

  final AudioService audioService;
  final VoidCallback onPlayNext;
  final VoidCallback onPlayPrevious;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: SvgPicture.asset(
              AppIcons.skipPrevious,
              height: 40,
              width: 40,
            ),
            onPressed: onPlayPrevious,
          ),
          const SizedBox(width: 20),
          PlayPauseButton(audioService: audioService, size: 40),
          const SizedBox(width: 20),
          IconButton(
            icon: SvgPicture.asset(AppIcons.skipNext, height: 40, width: 40),
            onPressed: onPlayNext,
          ),
        ],
      ),
    );
  }
}
