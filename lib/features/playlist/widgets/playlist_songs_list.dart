import 'package:flutter/material.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/song_tile_widget.dart';
import 'package:music/features/playlist/cubit/playlist_details_cubit.dart';
import 'package:music/features/playlist/cubit/playlist_details_state.dart';

class PlaylistSongsList extends StatelessWidget {
  final PlaylistDetailsState state;
  final AudioService audioService;
  final PlaylistDetailsCubit cubit;
  final void Function(int index) onPlay;
  final void Function(PlaylistSong song) onLongPress;

  const PlaylistSongsList({
    super.key,
    required this.state,
    required this.audioService,
    required this.cubit,
    required this.onPlay,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.songs.length,
      itemBuilder: (context, index) {
        final song = state.songs[index];
        return SongTileWidget(
          song: song,
          audioService: audioService,
          onTap: () => onPlay(index),
          onLongPress: () {
            final playlistSong = state.playlistSongs.firstWhere(
              (item) => item.songId == song.id,
              orElse: () => state.playlistSongs[index],
            );
            onLongPress(playlistSong);
          },
        );
      },
    );
  }
}
