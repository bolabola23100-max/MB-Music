import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class SongTitleWidget extends StatelessWidget {
  const SongTitleWidget({
    super.key,
    required this.songs,
    required this.currentIndex,
    this.customTitle,
    this.customArtist,
  });

  final List<SongModel> songs;
  final int currentIndex;
  final String? customTitle;
  final String? customArtist;

  @override
  Widget build(BuildContext context) {
    if (currentIndex < 0 || currentIndex >= songs.length) {
      return const SizedBox.shrink();
    }

    final title = customTitle ?? songs[currentIndex].title;
    final artist = customArtist ?? songs[currentIndex].artist ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
