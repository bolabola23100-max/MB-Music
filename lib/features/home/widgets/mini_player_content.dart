import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/audio/audio_service.dart';
import 'package:music/core/widgets/app_artwork.dart';
import 'package:music/core/widgets/app_seek_bar.dart';
import 'package:music/core/widgets/play_pause_button.dart';
import 'package:music/core/widgets/vinyl_widget.dart';

class MiniPlayerContent extends StatelessWidget {
  final AudioService audioService;
  final int currentSongId;
  final String? customTitle;
  final String? customArtist;
  final String? customArtPath;
  final VoidCallback onTap;

  const MiniPlayerContent({
    super.key,
    required this.audioService,
    required this.currentSongId,
    required this.customTitle,
    required this.customArtist,
    required this.customArtPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: GestureDetector(
          onTap: onTap,
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
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  VinylWidget(
                                    audioService: audioService,
                                    size: 52,
                                  ),
                                  AppArtwork(
                                    id: currentSongId,
                                    size: 30,
                                    borderRadius: 50,
                                    customArtPath: customArtPath,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ValueListenableBuilder<String?>(
                                    valueListenable:
                                        audioService.currentTitleNotifier,
                                    builder: (context, title, _) {
                                      return Text(
                                        customTitle ?? title ?? 'Unknown',
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
                                    valueListenable:
                                        audioService.currentArtistNotifier,
                                    builder: (context, artist, _) {
                                      return Text(
                                        customArtist ?? artist ?? 'Unknown',
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
                                    audioService: audioService,
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
                                  onPressed: audioService.playNext,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      AppSeekBar(
                        audioService: audioService,
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
  }
}
