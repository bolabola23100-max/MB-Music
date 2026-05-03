import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/song_tile_widget.dart';
import 'package:music/core/widgets/sort_button.dart';
import 'package:music/features/home/widgets/mini_player_widget.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:music/features/playlist/widgets/playlist_options_bottom_sheet.dart';
import 'package:music/features/playlist/cubit/playlist_details_cubit.dart';
import 'package:music/features/playlist/cubit/playlist_details_state.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final PlaylistModels playlist;
  final void Function(SongSortOption option)? onOptionSelected;

  const PlaylistDetailsScreen({
    super.key,
    required this.playlist,
    this.onOptionSelected,
  });

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.playlist.id == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Invalid playlist',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    return BlocProvider(
      create: (context) =>
          PlaylistDetailsCubit(playlistId: widget.playlist.id!),
      child: PlaylistDetailsView(
        playlist: widget.playlist,
        onOptionSelected: widget.onOptionSelected,
      ),
    );
  }
}

class PlaylistDetailsView extends StatefulWidget {
  final PlaylistModels playlist;
  final void Function(SongSortOption option)? onOptionSelected;

  const PlaylistDetailsView({
    super.key,
    required this.playlist,
    this.onOptionSelected,
  });

  @override
  State<PlaylistDetailsView> createState() => _PlaylistDetailsViewState();
}

class _PlaylistDetailsViewState extends State<PlaylistDetailsView> {
  bool isAscending = true;

  void _showOptions(BuildContext context, PlaylistSong song, int playlistId) {
    final cubit = context.read<PlaylistDetailsCubit>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PlaylistOptionsBottomSheet(
        song: song,
        playlistId: playlistId,
        onPlay: () {
          Navigator.pop(context);
          cubit.play(cubit.state.playlistSongs.indexOf(song));
        },
        onDelete: () {
          Navigator.pop(context);
          cubit.deleteSong(song);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    return BlocBuilder<PlaylistDetailsCubit, PlaylistDetailsState>(
      builder: (context, state) {
        final cubit = context.read<PlaylistDetailsCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 3),
                child: SortButton(
                  isAscending: isAscending,
                  onPressed: () {
                    setState(() {
                      isAscending = !isAscending;
                    });

                    cubit.sortSongs(
                      isAscending
                          ? SongSortOption.oldestFirst
                          : SongSortOption.newestFirst,
                    );
                  },
                ),
              ),
            ],
          ),
          body: state.status == PlaylistDetailsStatus.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.blue),
                )
              : Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final horizontalPadding = screenWidth > 800
                        ? screenWidth * 0.1
                        : 0.0;
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Column(
                        children: [
                          _buildHeader(cubit),
                          Expanded(child: _buildList(state, audioService)),
                          MiniPlayerWidget(
                            songs: state.songs,
                            audioService: audioService,
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  bool isShuffle = false;

  Widget _buildHeader(PlaylistDetailsCubit cubit) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: _buildPlayModeButton(
          icon: isShuffle ? Icons.shuffle_rounded : Icons.play_arrow_rounded,
          onTap: () {
            if (cubit.state.songs.isNotEmpty) {
              setState(() {
                isShuffle = !isShuffle;
              });
              cubit.sortSongs(
                isShuffle
                    ? SongSortOption.shufflePlay
                    : SongSortOption.orderedPlay,
              );
              cubit.play(0);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlayModeButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onTap,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            icon,
            key: ValueKey(icon),
            color: AppColors.blue,
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildList(PlaylistDetailsState state, AudioService audioService) {
    return BlocBuilder<PlaylistDetailsCubit, PlaylistDetailsState>(
      builder: (context, state) {
        final cubit = context.read<PlaylistDetailsCubit>();
        return ValueListenableBuilder<int?>(
          valueListenable: audioService.currentSongIdNotifier,
          builder: (context, currentId, _) => ValueListenableBuilder<bool>(
            valueListenable: audioService.isPlayingNotifier,
            builder: (context, isPlaying, _) => ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.songs.length,
              itemBuilder: (context, index) {
                final s = state.songs[index];
                return SongTileWidget(
                  song: s,
                  isCurrent: currentId == s.id,
                  isPlaying: isPlaying,
                  onTap: () => cubit.play(index),
                  onMoreTap: () {
                    final ps = state.playlistSongs.firstWhere(
                      (ps) => ps.songId == s.id,
                      orElse: () => state.playlistSongs[index],
                    );
                    _showOptions(context, ps, widget.playlist.id!);
                  },
                  onLongPress: () {
                    final ps = state.playlistSongs.firstWhere(
                      (ps) => ps.songId == s.id,
                      orElse: () => state.playlistSongs[index],
                    );
                    _showOptions(context, ps, widget.playlist.id!);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
