import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/player_builder.dart';
import 'package:music/core/widgets/sort_button.dart';
import 'package:music/features/home/widgets/mini_player_widget.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:music/features/playlist/widgets/playlist_details_header.dart';
import 'package:music/features/playlist/widgets/playlist_songs_list.dart';
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

  void _playAndOpenPlayer(
    BuildContext context,
    PlaylistDetailsCubit cubit,
    List<SongModel> songs,
    int index,
  ) {
    if (index < 0 || index >= songs.length) return;

    cubit.play(index);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => resolvePlayerScreen(
          songs: songs,
          index: index,
        ),
      ),
    );
  }

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
          final songIndex =
              cubit.state.songs.indexWhere((s) => s.id == song.songId);
          if (songIndex != -1) {
            _playAndOpenPlayer(
              this.context,
              cubit,
              cubit.state.songs,
              songIndex,
            );
          }
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
                          PlaylistDetailsHeader(
                            cubit: cubit,
                            audioService: audioService,
                          ),
                          Expanded(
                            child: PlaylistSongsList(
                              state: state,
                              audioService: audioService,
                              cubit: cubit,
                              onPlay: (index) => _playAndOpenPlayer(
                                context,
                                cubit,
                                state.songs,
                                index,
                              ),
                              onLongPress: (playlistSong) => _showOptions(
                                context,
                                playlistSong,
                                widget.playlist.id!,
                              ),
                            ),
                          ),
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
}
