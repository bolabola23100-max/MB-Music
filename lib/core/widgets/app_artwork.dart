import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:on_audio_query/on_audio_query.dart';

class AppArtwork extends StatelessWidget {
  final int id;
  final double size;
  final double borderRadius;
  final bool isCurrent;
  final String? customArtPath;

  const AppArtwork({
    super.key,
    required this.id,
    this.size = 50,
    this.borderRadius = 10,
    this.isCurrent = false,
    this.customArtPath,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: AppColors.gray,
        border: Border.all(
          color: isCurrent ? AppColors.gray : Colors.transparent,
          width: isCurrent ? 2 : 0,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.25),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: customArtPath != null
            ? Image.file(
                File(customArtPath!),
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : QueryArtworkWidget(
                id: id,
                type: ArtworkType.AUDIO,
                artworkQuality: FilterQuality.high,
                artworkBorder: BorderRadius.circular(borderRadius),
                artworkFit: BoxFit.cover,
                size: 1000,
                keepOldArtwork: true,
                nullArtworkWidget: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    color: AppColors.gray,
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: size * 0.6,
                    color: AppColors.blue,
                  ),
                ),
              ),
      ),
    );
  }
}
