import 'package:flutter/material.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:music/features/playlist/cubit/playlist_details_cubit.dart';
import 'package:music/features/playlist/widgets/playlist_play_mode_button.dart';

class PlaylistDetailsHeader extends StatelessWidget {
  final PlaylistDetailsCubit cubit;
  final AudioService audioService;

  const PlaylistDetailsHeader({
    super.key,
    required this.cubit,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PlaybackMode>(
      valueListenable: audioService.playbackModeNotifier,
      builder: (context, mode, _) {
        final isShuffle = mode == PlaybackMode.shuffle;
        return Padding(
          padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
          child: Align(
            alignment: Alignment.centerRight,
            child: PlaylistPlayModeButton(
              icon: isShuffle
                  ? Icons.shuffle_rounded
                  : Icons.play_arrow_rounded,
              onTap: () {
                if (cubit.state.songs.isNotEmpty) {
                  if (isShuffle) {
                    audioService.setPlaybackMode(PlaybackMode.sequential);
                    cubit.sortSongs(SongSortOption.orderedPlay);
                    cubit.play(0);
                  } else {
                    audioService.setPlaybackMode(PlaybackMode.shuffle);
                    cubit.playRandom();
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }
}
