import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/video/video_playlist_service.dart';
import 'package:music/features/video/screens/video_player_screen.dart';
import 'package:music/features/video/widgets/video_thumbnail.dart';

class VideoPlaylistsScreen extends StatefulWidget {
  const VideoPlaylistsScreen({super.key});

  @override
  State<VideoPlaylistsScreen> createState() => _VideoPlaylistsScreenState();
}

class _VideoPlaylistsScreenState extends State<VideoPlaylistsScreen> {
  final _service = VideoPlaylistService();
  late Future<List<VideoPlaylist>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getPlaylists();
  }

  void _reload() => setState(() => _future = _service.getPlaylists());

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('New video playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Create')),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    await _service.createPlaylist(name);
    _reload();
  }

  Future<void> _rename(VideoPlaylist playlist) async {
    final controller = TextEditingController(text: playlist.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('Rename playlist', style: TextStyle(color: Colors.white)),
        content: TextField(controller: controller, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) return;
    await _service.renamePlaylist(playlist.id, name);
    _reload();
  }

  Future<void> _delete(VideoPlaylist playlist) async {
    await _service.deletePlaylist(playlist.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton(
          onPressed: _createPlaylist,
          backgroundColor: AppColors.blue,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
      body: FutureBuilder<List<VideoPlaylist>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final playlists = snapshot.data ?? const <VideoPlaylist>[];
          if (playlists.isEmpty) {
            return const Center(child: Text('No video playlists yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Card(
                color: Colors.white10,
                child: ListTile(
                  leading: const Icon(Icons.playlist_play_rounded, color: AppColors.blue, size: 34),
                  title: Text(playlist.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(playlist.videoIds.length.toString() + ' videos',
                      style: const TextStyle(color: Colors.white54)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') _rename(playlist);
                      if (value == 'delete') _delete(playlist);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => _VideoPlaylistDetails(playlist: playlist)),
                  ).then((_) => _reload()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _VideoPlaylistDetails extends StatefulWidget {
  final VideoPlaylist playlist;
  const _VideoPlaylistDetails({required this.playlist});

  @override
  State<_VideoPlaylistDetails> createState() => _VideoPlaylistDetailsState();
}

class _VideoPlaylistDetailsState extends State<_VideoPlaylistDetails> {
  final _service = VideoPlaylistService();
  late Future<List<AssetEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: FutureBuilder<List<AssetEntity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final videos = snapshot.data ?? const <AssetEntity>[];
          if (videos.isEmpty) {
            return const Center(child: Text('No videos in this playlist'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final asset = videos[index];
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(asset: asset),
                )),
                child: Stack(
                  children: [
                    Positioned.fill(child: VideoThumbnail(
                      asset: asset,
                      width: double.infinity,
                      height: double.infinity,
                    )),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                          ),
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
