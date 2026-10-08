import 'package:flutter/material.dart';

class VideoPlayerError extends StatelessWidget {
  const VideoPlayerError({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Unable to play this video',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
