import 'package:flutter/material.dart';

class VideoPlayerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final bool filled;

  const VideoPlayerButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 46,
    this.iconSize = 25,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white.withValues(alpha: 0.95) : Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: filled ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
