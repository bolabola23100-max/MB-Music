import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/play_pause_button.dart';

class PlayerControlsWidget extends StatefulWidget {
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
  State<PlayerControlsWidget> createState() => _PlayerControlsWidgetState();
}

class _PlayerControlsWidgetState extends State<PlayerControlsWidget> {
  bool isPlay = true;
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
            onPressed: widget.onPlayPrevious,
          ),
          const SizedBox(width: 30),
          PlayPauseButton(
            audioService: widget.audioService,
            size: 40,
            pauseIcon: Image.asset(AppIcons.pause, height: 40, width: 40),
            playIcon: Image.asset(AppIcons.playArrow, height: 40, width: 40),
          ),
          const SizedBox(width: 30),
          IconButton(
            icon: SvgPicture.asset(AppIcons.skipNext, height: 40, width: 40),
            onPressed: widget.onPlayNext,
          ),
        ],
      ),
    );
  }
}
