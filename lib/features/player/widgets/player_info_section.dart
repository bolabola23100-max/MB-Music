import 'package:flutter/material.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/app_seek_bar.dart';
import 'package:music/features/home/widgets/song_title_widget.dart';
import 'package:music/features/player/cubit/player_state.dart';

class PlayerInfoSection extends StatelessWidget {
  const PlayerInfoSection({
    super.key,
    required this.state,
    required this.audioService,
  });

  final PlayerState state;
  final AudioService audioService;

  @override
  Widget build(BuildContext context) {
    final index = state.currentIndex.clamp(0, state.songs.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: ValueListenableBuilder<String?>(
            valueListenable: audioService.currentTitleNotifier,
            builder: (context, title, _) => ValueListenableBuilder<String?>(
              valueListenable: audioService.currentArtistNotifier,
              builder: (context, artist, _) => SongTitleWidget(
                songs: state.songs,
                currentIndex: index,
                customTitle: state.customTitle ?? title,
                customArtist: state.customArtist ?? artist,
              ),
            ),
          ),
        ),
        AppSeekBar(audioService: audioService, isT: true),
      ],
    );
  }
}
