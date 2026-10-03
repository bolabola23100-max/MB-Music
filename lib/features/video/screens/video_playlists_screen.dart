import 'package:flutter/material.dart';

class VideoPlaylistsScreen extends StatelessWidget {
  const VideoPlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: _VideoPlaylistEmptyState(),
    );
  }
}

class _VideoPlaylistEmptyState extends StatelessWidget {
  const _VideoPlaylistEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.playlist_play_rounded, size: 52),
          SizedBox(height: 14),
          Text(
            'Video Playlists',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Your video playlists will appear here.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
