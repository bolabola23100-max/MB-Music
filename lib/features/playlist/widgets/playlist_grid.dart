import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/core/widgets/app_artwork.dart';

class PlaylistGrid extends StatelessWidget {
  final List<PlaylistModels> playlists;
  final Map<int, List<int>> thumbnails;
  final Function(PlaylistModels) onTap;
  final Function(PlaylistModels) onLongPress;

  const PlaylistGrid({
    super.key,
    required this.playlists,
    required this.thumbnails,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 30,
        childAspectRatio: 0.55,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final p = playlists[index];
        return PlaylistCard(
          playlist: p,
          songIds: thumbnails[p.id] ?? [],
          onTap: () => onTap(p),
          onLongPress: () => onLongPress(p),
        );
      },
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final PlaylistModels playlist;
  final List<int> songIds;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.songIds,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mosaic Cover
          SizedBox(
            height: 90,
            width: 90,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: AppColors.gray,
              ),
              clipBehavior: Clip.antiAlias,
              child: _PlaylistMosaic(songIds: songIds),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          Text(
            "${playlist.songCount} TRACKS",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.white.withValues(alpha: 0.4),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistMosaic extends StatelessWidget {
  final List<int> songIds;

  const _PlaylistMosaic({required this.songIds});

  @override
  Widget build(BuildContext context) {
    if (songIds.isEmpty) {
      return Center(
        child: Icon(
          Icons.music_note_rounded,
          color: AppColors.white.withValues(alpha: 0.1),
          size: 50,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [Expanded(child: AppArtwork(id: songIds[0], size: 100))],
          ),
        ),
      ],
    );
  }
}
