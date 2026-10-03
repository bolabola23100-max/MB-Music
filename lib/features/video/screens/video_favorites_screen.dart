import 'package:flutter/material.dart';

class VideoFavoritesScreen extends StatelessWidget {
  const VideoFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: _VideoEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Video Favorites',
        message: 'Your favorite videos will appear here.',
      ),
    );
  }
}

class _VideoEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _VideoEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
