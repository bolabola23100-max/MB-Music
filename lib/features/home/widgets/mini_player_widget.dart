import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/services/song_edit/song_edit_service.dart';
import 'package:music/core/widgets/app_artwork.dart';
import 'package:music/core/widgets/app_seek_bar.dart';
import 'package:music/core/widgets/play_pause_button.dart';
import 'package:music/core/widgets/vinyl_widget.dart';
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

  void _onSongChanged() =>
      _loadEdit(widget.audioService.currentSongIdNotifier.value);

  Future<void> _loadEdit(int? songId) async {
    if (songId == null) return;
    _lastSongId = songId;
    final edit = await SongEditService().getEdit(songId);
    if (mounted) {
      setState(() {
        _customTitle = edit?['title'];
        _customArtPath = edit?['artPath'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.songs.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder<int?>(
      valueListenable: widget.audioService.currentSongIdNotifier,
      builder: (context, currentSongId, _) {
        if (currentSongId == null) return const SizedBox.shrink();

        if (currentSongId != _lastSongId) {
          Future.microtask(() => _loadEdit(currentSongId));
        }

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () {
                final index =
                    widget.audioService.currentIndexNotifier.value ?? 0;
                final currentQueue = widget.audioService.currentQueue;

                AppNavigator.push(
                  context,
                  PlayerScreen(
                    songs: currentQueue.isNotEmpty
                        ? currentQueue
                        : widget.songs,
                    index: index,
                  ),
                );
              },
              child: Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: AppColors.gray.withValues(alpha: 0.6),
                ),
                padding: const EdgeInsets.only(left: 10, right: 10, top: 8),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 5,
                                  bottom: 3,
                                ),
                                child: VinylWidget(
                                  audioService: widget.audioService,
                                  size: 45,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 9,
                                  left: 15,
                                ),
                                child: AppArtwork(
                                  id: currentSongId,
                                  size: 25,
                                  borderRadius: 50,
                                  customArtPath: _customArtPath,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ValueListenableBuilder<String?>(
                              valueListenable:
                                  widget.audioService.currentTitleNotifier,
                              builder: (context, title, _) => Text(
                                _customTitle ?? title ?? 'Unknown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              PlayPauseButton(
                                audioService: widget.audioService,
                                size: 25,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.double_arrow_rounded,
                                  color: AppColors.white,
                                ),
                                onPressed: () => widget.audioService.playNext(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSeekBar(audioService: widget.audioService, maxWidth: 20),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
