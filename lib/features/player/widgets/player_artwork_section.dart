import 'package:flutter/material.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/app_artwork.dart';
import 'package:music/core/widgets/vinyl_widget.dart';
import 'package:music/features/player/cubit/player_state.dart';

class PlayerArtworkSection extends StatelessWidget {
  const PlayerArtworkSection({
    super.key,
    required this.state,
    required this.audioService,
  });

  final PlayerState state;
  final AudioService audioService;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final artworkSize = isTablet ? 180.0 : 150.0;
    final vinylSize = isTablet ? 250.0 : 150.0;
    final offset = isTablet ? 130.0 : 100.0;

    return ValueListenableBuilder<int?>(
      valueListenable: audioService.currentSongIdNotifier,
      builder: (context, songId, _) {
        final id = songId ?? state.songs[state.currentIndex.clamp(0, state.songs.length - 1)].id;

        return Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 20, right: 10),
                child: VinylWidget(audioService: audioService, size: vinylSize),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: 20, right: offset),
                child: AppArtwork(
                  id: id,
                  size: artworkSize,
                  borderRadius: isTablet ? 24 : 16,
                  customArtPath: state.customArtPath,
                  highQuality: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
