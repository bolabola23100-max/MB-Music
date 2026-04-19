import 'package:flutter/material.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/services/audio/audio_service.dart';

class VinylWidget extends StatefulWidget {
  final AudioService audioService;
  final double size;

  const VinylWidget({super.key, required this.audioService, this.size = 200});

  @override
  State<VinylWidget> createState() => _VinylWidgetState();
}

class _VinylWidgetState extends State<VinylWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  void _listener() {
    if (widget.audioService.isPlayingNotifier.value) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    widget.audioService.isPlayingNotifier.addListener(_listener);

    // ✅ شغل الأنيميشن لو الأغنية شغالة من الأول
    if (widget.audioService.isPlayingNotifier.value) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    widget.audioService.isPlayingNotifier.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Image.asset(
        AppIcons.vinylRecord,
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
