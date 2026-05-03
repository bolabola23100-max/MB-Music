import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class EmptyPlaylistsState extends StatelessWidget {
  const EmptyPlaylistsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(
            Icons.playlist_add_rounded,
            size: 80,
            color: AppColors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 15),
          Text(
            "no_playlists".tr(),
            style: const TextStyle(color: AppColors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
