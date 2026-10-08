import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/video/video_playlist_service.dart';
import 'package:music/features/video/screens/video_player_screen.dart';
import 'package:music/features/video/widgets/video_thumbnail.dart';
import 'package:music/features/video/widgets/video_options_bottom_sheet.dart';

class VideoPlaylistDetailsScreen extends StatefulWidget {
  final VideoPlaylist playlist;
  const VideoPlaylistDetailsScreen({super.key, required this.playlist});

  @override
  State<VideoPlaylistDetailsScreen> createState() => _VideoPlaylistDetailsScreenState();
}

class _VideoPlaylistDetailsScreenState extends State<VideoPlaylistDetailsScreen> {
  final _service = VideoPlaylistService();
  late Future<List<AssetEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _service.changes.addListener(_onChanged);
  }

  @override
  void dispose() {
    _service.changes.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() => _future = _load());
  }

  Future<List<AssetEntity>> _load() async {
    final current = (await _service.getPlaylists()).firstWhere(
      (p) => p.id == widget.playlist.id,
      orElse: () => widget.playlist,
    );
    final videos = <AssetEntity>[];
    for (final id in current.videoIds) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null && await asset.exists) videos.add(asset);
    }
    videos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return videos;
  }

  Future<void> _removeFromPlaylist(AssetEntity asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('Remove from playlist?', style: TextStyle(color: Colors.white)),
        content: const Text('The video will stay on your device.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Remove')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _service.removeVideo(widget.playlist.id, asset.id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Video removed from playlist')));
  }

  void _showVideoMenu(AssetEntity asset, List<AssetEntity> videos) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.gray,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded, color: AppColors.blue),
              title: const Text('Play', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VideoPlayerScreen(key: ValueKey(asset.id), asset: asset, videos: videos)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.more_horiz_rounded, color: AppColors.blue),
              title: const Text('Video options', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetContext);
                VideoOptionsBottomSheet.show(context, asset: asset);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_remove_rounded, color: Colors.orangeAccent),
              title: const Text('Remove from playlist', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(sheetContext); _removeFromPlaylist(asset); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: FutureBuilder<List<AssetEntity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final videos = snapshot.data ?? const <AssetEntity>[];
          if (videos.isEmpty) return const Center(child: Text('No videos in this playlist'));
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.78,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final asset = videos[index];
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(asset: asset, videos: videos),
                  ),
                ),
                onLongPress: () => _showVideoMenu(asset, videos),
                child: Stack(
                  children: [
                    Positioned.fill(child: VideoThumbnail(asset: asset, width: double.infinity, height: double.infinity)),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IconButton(
                        onPressed: () => _showVideoMenu(asset, videos),
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: FutureBuilder<String>(
                        future: asset.titleAsync,
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
          );
        },
      ),
    );
  }
}
