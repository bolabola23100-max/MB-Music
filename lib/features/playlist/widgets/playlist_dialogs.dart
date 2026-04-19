import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/models/playlist_model.dart';
import 'package:music/core/services/playlist/playlist_service.dart';
import 'package:easy_localization/easy_localization.dart';

class PlaylistDialogs {
  static final PlaylistService _playlistService = PlaylistService();

  static void showCreateDialog(BuildContext context, VoidCallback onCreated) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "playlist_dialogs.create_title".tr(),
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.white),
          decoration: InputDecoration(
            hintText: "playlist_dialogs.enter_name".tr(),
            hintStyle: TextStyle(
              color: AppColors.white.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "common.cancel".tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _playlistService.createPlaylist(controller.text.trim());
                Navigator.pop(context);
                onCreated();
              }
            },
            child: Text("common.create".tr()),
          ),
        ],
      ),
    );
  }

  static void showRenameDialog(
    BuildContext context,
    PlaylistModels playlist,
    VoidCallback onRenamed,
  ) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "playlist_dialogs.rename_title".tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.white),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.black26,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("common.cancel".tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              await _playlistService.renamePlaylist(
                playlist.id!,
                controller.text.trim(),
              );
              Navigator.pop(context);
              onRenamed();
            },
            child: Text("common.save".tr()),
          ),
        ],
      ),
    );
  }

  static void showDeleteDialog(
    BuildContext context,
    PlaylistModels playlist,
    VoidCallback onDeleted,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: Text(
          "playlist_dialogs.delete_title".tr(),
          style: const TextStyle(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("common.cancel".tr()),
          ),
          TextButton(
            onPressed: () async {
              await _playlistService.deletePlaylist(playlist.id!);
              Navigator.pop(context);
              onDeleted();
            },
            child: Text(
              "options.delete".tr(),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
