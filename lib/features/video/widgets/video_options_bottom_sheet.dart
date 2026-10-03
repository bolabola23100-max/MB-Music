import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/video/video_favorites_service.dart';
import 'package:music/core/services/video/video_playlist_service.dart';

class VideoOptionsBottomSheet {
  static const MethodChannel _videoChannel =
      MethodChannel('com.mbmusic.player/video');

  static Future<void> show(
    BuildContext context, {
    required AssetEntity asset,
  }) async {
    final favorites = VideoFavoritesService();
    final playlists = VideoPlaylistService();
    final isFavorite = favorites.isFavorite(asset.id);
    final title = await asset.titleAsync;
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.gray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? Colors.redAccent : Colors.white,
                ),
                title: Text(
                  isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  await favorites.toggleFavorite(asset.id);
                  if (!sheetContext.mounted || !context.mounted) return;
                  Navigator.pop(sheetContext);
                  _message(
                    context,
                    isFavorite
                        ? 'Video removed from favorites'
                        : 'Video added to favorites',
                  );
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
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.white),
                title: const Text('Rename video', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _renameVideo(context, asset, title);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: Colors.white),
                title: const Text('Video information', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _showInfo(context, asset, title);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Delete video from device', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _deleteVideo(context, asset);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showPlaylistPicker(
    BuildContext context,
    AssetEntity asset,
    VideoPlaylistService service,
  ) async {
    final playlists = await service.getPlaylists();
    if (!context.mounted) return;

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.gray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.blue),
                title: const Text('Create new playlist', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(sheetContext, '__create__'),
              ),
              ...playlists.map(
                (playlist) => ListTile(
                  leading: const Icon(Icons.playlist_play_rounded, color: AppColors.blue),
                  title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    '${playlist.videoIds.length} videos',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  onTap: () => Navigator.pop(sheetContext, playlist.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted || result == null) return;

    if (result == '__create__') {
      final name = await _askPlaylistName(context);
      if (!context.mounted || name == null) return;

      final id = await service.createPlaylist(name);
      final added = await service.addVideo(id, asset.id);
      if (!context.mounted) return;

      _message(
        context,
        added
            ? 'Playlist "$name" created and video added'
            : 'Playlist "$name" created',
      );
      return;
    }

    final added = await service.addVideo(result, asset.id);
    if (!context.mounted) return;

    final updatedPlaylists = await service.getPlaylists();
    final matching = updatedPlaylists.where((p) => p.id == result);
    final playlistName = matching.isEmpty ? 'playlist' : matching.first.name;

    _message(
      context,
      added
          ? 'Video added to $playlistName'
          : 'Video is already in $playlistName',
    );
  }

  static Future<String?> _askPlaylistName(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('New video playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return null;
    return name.trim();
  }

  static Future<void> _renameVideo(
    BuildContext context,
    AssetEntity asset,
    String currentTitle,
  ) async {
    final controller = TextEditingController(text: currentTitle);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('Rename video', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Video name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (!context.mounted || name == null || name.isEmpty) return;

    var finalName = name;
    if (!finalName.contains('.')) finalName = '$finalName.mp4';

    try {
      final success = await _videoChannel.invokeMethod<bool>(
        'renameVideo',
        {'videoId': asset.id, 'newName': finalName},
      );
      if (!context.mounted) return;
      _message(
        context,
        success == true ? 'Video renamed successfully' : 'Could not rename video',
      );
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      _message(context, e.message ?? 'Could not rename video');
    }
  }

  static Future<void> _deleteVideo(
    BuildContext context,
    AssetEntity asset,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('Delete video?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'The video will be deleted from the device.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmed != true) return;

    try {
      final deletedIds = await PhotoManager.editor.deleteWithIds([asset.id]);
      if (!context.mounted) return;
      _message(
        context,
        deletedIds.contains(asset.id)
            ? 'Video deleted from device'
            : 'Video was not deleted',
      );
    } catch (_) {
      if (!context.mounted) return;
      _message(context, 'Could not delete video');
    }
  }

  static Future<void> _showInfo(
    BuildContext context,
    AssetEntity asset,
    String title,
  ) async {
    final file = await asset.file;
    final size = file?.lengthSync() ?? 0;
    final path = await asset.relativePath;
    final mime = await asset.mimeTypeAsync;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('Video information', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow('Name', title),
              _infoRow('Duration', _formatDuration(asset.duration)),
              _infoRow('Resolution', '${asset.width} × ${asset.height}'),
              _infoRow('Format', mime ?? 'Unknown'),
              _infoRow('Size', _formatSize(size)),
              _infoRow('Created', _formatDate(asset.createDateTime)),
              _infoRow('Location', path ?? 'Unknown'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          '$label: $value',
          style: const TextStyle(color: Colors.white70),
        ),
      );

  static String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
