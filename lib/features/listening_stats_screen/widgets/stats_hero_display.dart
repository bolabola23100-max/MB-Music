import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/widgets/app_artwork.dart';

/// Displays the top song with artwork and title.
class StatsHeroDisplay extends StatelessWidget {
  final Map<String, dynamic>? topSong;

  const StatsHeroDisplay({super.key, required this.topSong});

  @override
  Widget build(BuildContext context) {
    final title = (topSong?['title'] ?? 'NO DATA').toString().toUpperCase();
    final artist = (topSong?['artist'] ?? 'START LISTENING').toString().toUpperCase();
    final songId = topSong?['song_id'] as int?;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const _HeroGlowEffect(),
            if (songId != null)
              AppArtwork(id: songId, size: 210, borderRadius: 28)
            else
              const _PlaceholderArtwork(),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}

/// A glowing shadow effect behind the artwork.
class _HeroGlowEffect extends StatelessWidget {
  const _HeroGlowEffect();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 230,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.08),
            spreadRadius: 35,
            blurRadius: 60,
          ),
        ],
      ),
    );
  }
}

/// Placeholder when no artwork is available.
class _PlaceholderArtwork extends StatelessWidget {
  const _PlaceholderArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      height: 210,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Icon(Icons.music_note_rounded, size: 90, color: Colors.grey),
    );
  }
}
