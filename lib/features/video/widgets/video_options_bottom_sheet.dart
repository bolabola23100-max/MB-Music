import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/video/video_favorites_service.dart';
import 'package:music/core/services/video/video_playlist_service.dart';

class VideoOptionsBottomSheet {
  static Future<void> show(BuildContext context, {required AssetEntity asset}) async {
    final favorites = VideoFavoritesService();
    final playlists = VideoPlaylistService();
    final isFavorite = favorites.isFavorite(asset.id);
    final title = await asset.titleAsync;
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.gray,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(title ?? 'Video', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.redAccent : Colors.white),
              title: Text(isFavorite ? 'Remove from favorites' : 'Add to favorites',
                style: const TextStyle(color: Colors.white)),
              onTap: () async {
                await favorites.toggleFavorite(asset.id);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded, color: Colors.white),
              title: const Text('Add to playlist', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _showPlaylistPicker(context, asset, playlists);
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showPlaylistPicker(BuildContext context, AssetEntity asset, VideoPlaylistService service) async {
    final playlists = await service.getPlaylists();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.gray,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (sheetContext) {
        if (playlists.isEmpty) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text('Create a video playlist first.', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white)),
            ),
          );
        }
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: playlists.map((playlist) => ListTile(
              leading: const Icon(Icons.playlist_play_rounded, color: AppColors.blue),
              title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
              subtitle: Text(playlist.videoIds.length.toString() + ' videos',
                style: const TextStyle(color: Colors.white54)),
              onTap: () async {
                final added = await service.addVideo(playlist.id, asset.id);
                if (!sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(added
                    ? 'Video added to ' + playlist.name
                    : 'Video is already in ' + playlist.name)),
                );
              },
            )).toList(),
          ),
        );
      },
    );
  }
}
