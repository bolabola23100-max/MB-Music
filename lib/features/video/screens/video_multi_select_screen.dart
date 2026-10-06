import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/video/video_favorites_service.dart';
import 'package:music/core/services/video/video_playlist_service.dart';
import 'package:music/features/video/widgets/video_thumbnail.dart';

class VideoMultiSelectScreen extends StatefulWidget {
  final List<AssetEntity> videos;

  const VideoMultiSelectScreen({super.key, required this.videos});

  @override
  State<VideoMultiSelectScreen> createState() => _VideoMultiSelectScreenState();
}

class _VideoMultiSelectScreenState extends State<VideoMultiSelectScreen> {
  final Set<String> _selected = <String>{};
  final _favorites = VideoFavoritesService();
  final _playlists = VideoPlaylistService();

  List<AssetEntity> get _selectedVideos => widget.videos.where((v) => _selected.contains(v.id)).toList();

  void _toggle(AssetEntity video) {
    setState(() {
      if (!_selected.add(video.id)) _selected.remove(video.id);
    });
  }

  Future<void> _addToPlaylist() async {
    if (_selected.isEmpty) return;
    final playlists = await _playlists.getPlaylists();
    if (!mounted) return;

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
              ...playlists.map((playlist) => ListTile(
                    leading: const Icon(Icons.playlist_play_rounded, color: AppColors.blue),
                    title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${playlist.videoIds.length} videos', style: const TextStyle(color: Colors.white54)),
                    onTap: () => Navigator.pop(sheetContext, playlist.id),
                  )),
            ],
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;

    String playlistId = result;
    String playlistName = 'playlist';
    if (result == '__create__') {
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Create')),
          ],
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
      if (!mounted || name == null || name.isEmpty) return;
      playlistId = await _playlists.createPlaylist(name);
      playlistName = name;
    } else {
      playlistName = playlists.firstWhere((p) => p.id == result).name;
    }

    var added = 0;
    for (final video in _selectedVideos) {
      if (await _playlists.addVideo(playlistId, video.id)) added++;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$added video${added == 1 ? '' : 's'} added to $playlistName')),
    );
    Navigator.pop(context);
  }

  Future<void> _addToFavorites() async {
    if (_selected.isEmpty) return;
    await _favorites.addFavorites(_selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selected.length} videos added to favorites')),
    );
    Navigator.pop(context);
  }

  Future<void> _deleteSelected() async {
    if (_selected.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('Delete selected videos?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete ${_selected.length} selected videos from the device?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      final ids = _selected.toList();
      final deletedIds = await PhotoManager.editor.deleteWithIds(ids);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${deletedIds.length} video${deletedIds.length == 1 ? '' : 's'} deleted')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete selected videos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(count == 0 ? 'Select videos' : '$count selected'),
        actions: [
          if (count > 0)
            IconButton(
              tooltip: 'Select all',
              onPressed: () => setState(() => _selected.addAll(widget.videos.map((v) => v.id))),
              icon: const Icon(Icons.select_all_rounded),
            ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.78,
        ),
        itemCount: widget.videos.length,
        itemBuilder: (context, index) {
          final video = widget.videos[index];
          final selected = _selected.contains(video.id);
          return GestureDetector(
            onTap: () => _toggle(video),
            child: Stack(
              fit: StackFit.expand,
              children: [
                VideoThumbnail(asset: video, width: double.infinity, height: double.infinity),
                if (selected)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.blue, width: 3),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(
                    selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: selected ? AppColors.blue : Colors.white,
                    size: 28,
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: FutureBuilder<String>(
                    future: video.titleAsync,
                    builder: (context, snapshot) => Text(
                      snapshot.data ?? 'Video',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 5, color: Colors.black)]),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(child: FilledButton.icon(onPressed: count == 0 ? null : _addToPlaylist, icon: const Icon(Icons.playlist_add_rounded), label: const Text('Playlist'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: count == 0 ? null : _addToFavorites, icon: const Icon(Icons.favorite_rounded), label: const Text('Favorites'))),
              const SizedBox(width: 8),
              Expanded(child: FilledButton.icon(onPressed: count == 0 ? null : _deleteSelected, icon: const Icon(Icons.delete_outline_rounded), label: const Text('Delete'))),
            ],
          ),
        ),
      ),
    );
  }
}
