import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';

class PlaylistPlayModeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const PlaylistPlayModeButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            icon,
            key: ValueKey(icon),
            color: AppColors.blue,
            size: 26,
          ),
        ),
      ),
    );
  }
}
