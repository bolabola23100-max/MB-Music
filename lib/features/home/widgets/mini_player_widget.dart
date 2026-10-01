import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';
import 'package:music/core/widgets/app_artwork.dart';
import 'package:music/core/widgets/app_seek_bar.dart';
import 'package:music/core/widgets/play_pause_button.dart';
import 'package:music/core/widgets/vinyl_widget.dart';
import 'package:music/features/home/cubit/home_cubit.dart';
import 'package:music/features/player/screens/player_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MiniPlayerWidget extends StatefulWidget {
  final List<SongModel> songs;
  final AudioService audioService;

  const MiniPlayerWidget({
    super.key,
    required this.songs,
    required this.audioService,
  });

  @override
  State<MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<MiniPlayerWidget> {
  String? _customTitle;
  String? _customArtist;
  String? _customArtPath;
  int? _lastSongId;

  @override
  void initState() {
    super.initState();

    SongEditService().editNotifier.addListener(_onEditChanged);

    widget.audioService.currentSongIdNotifier.addListener(_onSongChanged);
  }

  @override
  void dispose() {
    SongEditService().editNotifier.removeListener(_onEditChanged);

    widget.audioService.currentSongIdNotifier.removeListener(_onSongChanged);

    super.dispose();
  }

  void _onEditChanged() => _loadEdit(_lastSongId);

  void _onSongChanged() {
    _loadEdit(widget.audioService.currentSongIdNotifier.value);
  }

  Future<void> _loadEdit(int? songId) async {
    if (songId == null) {
      if (mounted) {
        setState(() {
          _customTitle = null;
          _customArtist = null;
          _customArtPath = null;
          _lastSongId = null;
        });
      }

      return;
    }

    _lastSongId = songId;

    final edit = await SongEditService().getEdit(songId);

    if (mounted) {
      setState(() {
        _customTitle = edit?['title'];
        _customArtist = edit?['artist'];
        _customArtPath = edit?['artPath'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.songs.isEmpty) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<int?>(
      valueListenable: widget.audioService.currentSongIdNotifier,
      builder: (context, currentSongId, _) {
        if (currentSongId == null) {
          return const SizedBox.shrink();
        }

        if (currentSongId != _lastSongId) {
          Future.microtask(() => _loadEdit(currentSongId));
        }

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GestureDetector(
              onTap: () {
                final index =
                    widget.audioService.currentIndexNotifier.value ?? 0;

                Future<void> Function(List<SongModel>)? onDelete;

                try {
                  onDelete = context.read<HomeCubit>().onDeleteSongs;
                } catch (_) {}

                AppNavigator.push(
                  context,
                  PlayerScreen(
                    songs: widget.songs,
                    index: index,
                    onDeleteSongs: onDelete,
                  ),
                );
              },
              child: Container(
                height: 82,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: AppColors.gray,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 8, 6),
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                // =========================
                                // Artwork
                                // =========================
                                SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      VinylWidget(
                                        audioService: widget.audioService,
                                        size: 52,
                                      ),

                                      AppArtwork(
                                        id: currentSongId,
                                        size: 30,
                                        borderRadius: 50,
                                        customArtPath: _customArtPath,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // =========================
                                // Song Information
                                // =========================
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ValueListenableBuilder<String?>(
                                        valueListenable: widget
                                            .audioService
                                            .currentTitleNotifier,
                                        builder: (context, title, _) {
                                          return Text(
                                            _customTitle ?? title ?? 'Unknown',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 3),

                                      ValueListenableBuilder<String?>(
                                        valueListenable: widget
                                            .audioService
                                            .currentArtistNotifier,
                                        builder: (context, artist, _) {
                                          return Text(
                                            _customArtist ??
                                                artist ??
                                                'Unknown',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.white.withValues(
                                                alpha: 0.55,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // =========================
                                // Controls
                                // =========================
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                      child: PlayPauseButton(
                                        audioService: widget.audioService,
                                        size: 22,
                                      ),
                                    ),

                                    const SizedBox(width: 4),

                                    IconButton(
                                      splashRadius: 22,
                                      icon: const Icon(
                                        Icons.skip_next_rounded,
                                        color: AppColors.white,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        widget.audioService.playNext();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 2),

                          // =========================
                          // Progress Bar
                          // =========================
                          AppSeekBar(
                            audioService: widget.audioService,
                            maxWidth: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
