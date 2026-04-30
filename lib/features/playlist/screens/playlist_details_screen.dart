import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/menu_row.dart';
import 'package:music/core/widgets/song_tile_widget.dart';
import 'package:music/features/home/widgets/mini_player_widget.dart';
import 'package:music/features/home/widgets/song_list_widget.dart';
import 'package:music/features/playlist/widgets/playlist_options_bottom_sheet.dart';
import 'package:music/features/playlist/cubit/playlist_details_cubit.dart';
import 'package:music/features/playlist/cubit/playlist_details_state.dart';

class PlaylistDetailsScreen extends StatelessWidget {
  final PlaylistModels playlist;
  final void Function(SongSortOption option)? onOptionSelected;

  const PlaylistDetailsScreen({
    super.key,
    required this.playlist,
    this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlaylistDetailsCubit(playlistId: playlist.id!),
      child: PlaylistDetailsView(
        playlist: playlist,
        onOptionSelected: onOptionSelected,
      ),
    );
  }
}

class PlaylistDetailsView extends StatelessWidget {
  final PlaylistModels playlist;
  final void Function(SongSortOption option)? onOptionSelected;

  const PlaylistDetailsView({
    super.key,
    required this.playlist,
    this.onOptionSelected,
  });

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
              playlist.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 10),
                child: IconButton(
                  icon: SvgPicture.asset(AppIcons.icon, width: 15, height: 15),
                  onPressed: () async {
                    final RenderBox button =
                        context.findRenderObject() as RenderBox;
                    final RenderBox overlay =
                        Overlay.of(context).context.findRenderObject()
                            as RenderBox;

                    final RelativeRect position = RelativeRect.fromRect(
                      Rect.fromPoints(
                        button.localToGlobal(
                          Offset(button.size.width - 60, 60),
                          ancestor: overlay,
                        ),
                        button.localToGlobal(
                          Offset(button.size.width, 60),
                          ancestor: overlay,
                        ),
                      ),
                      Offset.zero & overlay.size,
                    );

                    final SongSortOption? result =
                        await showMenu<SongSortOption>(
                          context: context,
                          position: position,
                          color: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          items: [
                            PopupMenuItem(
                              value: SongSortOption.oldestFirst,
                              child: MenuRow(
                                icon: Icons.arrow_upward_rounded,
                                label: 'sort.oldest_first'.tr(),
                              ),
                            ),
                            PopupMenuItem(
                              value: SongSortOption.newestFirst,
                              child: MenuRow(
                                icon: Icons.arrow_downward_rounded,
                                label: 'sort.newest_first'.tr(),
                              ),
                            ),
                          ],
                        );

                    if (result != null) {
                      cubit.sortSongs(result);
                      onOptionSelected?.call(result);
                    }
                  },
                ),
              ),
            ],
          ),
          body: state.status == PlaylistDetailsStatus.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.blue),
                )
              : Column(
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
    );
  }

  Widget _buildHeader(PlaylistDetailsCubit cubit) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlayModeButton(
              label: "player.sequential".tr(),
              icon: Icons.play_arrow_rounded,
              onTap: () => cubit.play(0),
              isLeft: true,
            ),
            _buildPlayModeButton(
              label: "player.shuffle".tr(),
              icon: Icons.shuffle_rounded,
              onTap: cubit.playRandom,
              isLeft: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayModeButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    return Material(
      color: AppColors.blue.withValues(alpha: isLeft ? 0.4 : 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.only(
          topStart: isLeft ? const Radius.circular(15) : Radius.zero,
          bottomStart: isLeft ? const Radius.circular(15) : Radius.zero,
          topEnd: isLeft ? Radius.zero : const Radius.circular(15),
          bottomEnd: isLeft ? Radius.zero : const Radius.circular(15),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.only(
            topStart: isLeft ? const Radius.circular(15) : Radius.zero,
            bottomStart: isLeft ? const Radius.circular(15) : Radius.zero,
            topEnd: isLeft ? Radius.zero : const Radius.circular(15),
            bottomEnd: isLeft ? Radius.zero : const Radius.circular(15),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
                  onMoreTap: () => _showOptions(
                    context,
                    state.playlistSongs[index],
                    playlist.id!,
                  ),
                  onLongPress: () => _showOptions(
                    context,
                    state.playlistSongs[index],
                    playlist.id!,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
