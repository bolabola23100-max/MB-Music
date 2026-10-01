import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:easy_localization/easy_localization.dart';

class PlaylistMenuBottomSheet extends StatelessWidget {
  final PlaylistModels playlist;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const PlaylistMenuBottomSheet({
    super.key,
    required this.playlist,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            playlist.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: AppColors.blue),
            title: Text(
              "common.rename".tr(),
              style: const TextStyle(color: AppColors.white),
            ),
            onTap: onRename,
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_rounded,
              color: Colors.redAccent,
            ),
            title: Text(
              "options.delete".tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
