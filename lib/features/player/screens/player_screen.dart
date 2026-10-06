import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/favorites/favorites_service.dart';
import 'package:music/core/widgets/app_artwork.dart';
import 'package:music/core/widgets/dialog/my_snack_bar.dart';
import 'package:music/features/home/widgets/song_options_bottom_sheet.dart';
import 'package:music/features/player/cubit/player_cubit.dart';
import 'package:music/features/player/cubit/player_state.dart';
import 'package:music/features/player/widgets/playback_mode_sheet.dart';
import 'package:music/features/player/widgets/player_artwork_section.dart';
import 'package:music/features/player/widgets/player_controls_widget.dart';
import 'package:music/features/player/widgets/player_info_section.dart';
import 'package:music/features/player/widgets/sleep_timer_widget.dart';
import 'package:music/features/playlist/widgets/add_to_playlist_dialog.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({
    super.key,
    required this.songs,
    required this.index,
    this.onDeleteSongs,
  });

  final List<SongModel> songs;
  final int index;
  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlayerCubit(songs: songs, index: index),
      child: PlayerView(onDeleteSongs: onDeleteSongs),
    );
  }
}

class PlayerView extends StatelessWidget {
  const PlayerView({super.key, this.onDeleteSongs});

  final Future<void> Function(List<SongModel> songs)? onDeleteSongs;

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService();

    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        if (state.songs.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) AppNavigator.pop(context);
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final cubit = context.read<PlayerCubit>();

        return GestureDetector(
          onVerticalDragStart: (details) =>
              cubit.setCanDrag(details.globalPosition.dy < 400),
          onVerticalDragUpdate: (details) {
            if (state.canDrag) cubit.updateDrag(details.delta.dy);
          },
          onVerticalDragEnd: (details) {
            if (!state.canDrag) return;
            final velocity = details.primaryVelocity ?? 0;
            if (state.offsetY > 200 || velocity > 1000) {
              AppNavigator.pop(context);
            } else {
              cubit.resetDrag();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.translationValues(0, state.offsetY, 0),
            child: Scaffold(
              extendBodyBehindAppBar: true,
              backgroundColor: AppColors.gray,
              appBar: _buildAppBar(context, state, audioService),
              body: Stack(
                fit: StackFit.expand,
                children: [
                  _BackgroundArtwork(state: state, audioService: audioService),
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: Container(color: Colors.black.withValues(alpha: .3)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: .45)],
                        stops: const [.55, 1],
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: MediaQuery.paddingOf(context).top + 60),
                        PlayerArtworkSection(state: state, audioService: audioService),
                        const SizedBox(height: 50),
                        PlayerInfoSection(state: state, audioService: audioService),
                        _buildControls(context, state, audioService),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    PlayerState state,
    AudioService audioService,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'player.title'.tr(),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.white, size: 26),
          onPressed: () {
            final index = state.currentIndex.clamp(0, state.songs.length - 1);
            final favorites = FavoritesService();

            SongOptionsBottomSheet.show(
              context,
              song: state.songs[index],
              index: index,
              audioService: audioService,
              isFavoriteChecker: (song) => favorites.isFavorite(song.id),
              onToggleFavorite: (song) => favorites.toggleFavorite(song.id),
              playlist: false,
              onDeleteSongs: onDeleteSongs,
            );
          },
        ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    PlayerState state,
    AudioService audioService,
  ) {
    return Column(
      children: [
        PlayerControlsWidget(
          audioService: audioService,
          onPlayNext: audioService.playNext,
          onPlayPrevious: audioService.playPrevious,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<PlaybackMode>(
                valueListenable: audioService.playbackModeNotifier,
                builder: (context, mode, _) => IconButton(
                  icon: Icon(_modeIcon(mode), color: AppColors.white, size: 28),
                  onPressed: () => PlaybackModeSheet.show(context, audioService),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.playlist_add, color: AppColors.white, size: 28),
                onPressed: () => _addToPlaylist(context, state),
              ),
              SleepTimerWidget(audioService: audioService),
            ],
          ),
        ),
      ],
    );
  }

  IconData _modeIcon(PlaybackMode mode) => switch (mode) {
        PlaybackMode.sequential => Icons.repeat,
        PlaybackMode.repeatOne => Icons.repeat_one,
        PlaybackMode.shuffle => Icons.shuffle,
      };

  Future<void> _addToPlaylist(BuildContext context, PlayerState state) async {
    final index = state.currentIndex.clamp(0, state.songs.length - 1);
    await showDialog(
      context: context,
      builder: (_) => AddToPlaylistDialog(songs: [state.songs[index]]),
    );
    if (!context.mounted) return;

    MySnackBar(context: context).showSnackBar(
      'playlist_dialogs.add_to_playlist'.tr(),
      AppColors.blue,
    );
  }
}

class _BackgroundArtwork extends StatelessWidget {
  const _BackgroundArtwork({required this.state, required this.audioService});

  final PlayerState state;
  final AudioService audioService;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: audioService.currentSongIdNotifier,
      builder: (context, songId, _) {
        final id = songId ?? state.songs[state.currentIndex.clamp(0, state.songs.length - 1)].id;
        return AppArtwork(
          id: id,
          size: 500,
          highQuality: true,
          customArtPath: state.customArtPath,
        );
      },
    );
  }
}
