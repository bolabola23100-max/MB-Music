import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/services/video/video_playlist_service.dart';
import 'package:music/features/video/screens/video_player_screen.dart';
import 'package:music/features/video/widgets/video_thumbnail.dart';
import 'package:music/features/video/widgets/video_options_bottom_sheet.dart';

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
    _service.changes.addListener(_onPlaylistsChanged);
  }

  @override
  void dispose() {
    _service.changes.removeListener(_onPlaylistsChanged);
    super.dispose();
  }

  void _onPlaylistsChanged() {
    if (!mounted) return;
    setState(() => _future = _service.getPlaylists());
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _future = _service.getPlaylists());
  }

  Future<void> _createPlaylist() async {
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
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Next')),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (!mounted || name == null || name.isEmpty) return;

    final albums = await PhotoManager.getAssetPathList(type: RequestType.video, hasAll: true);
    if (!mounted || albums.isEmpty) return;
    final all = albums.firstWhere((album) => album.isAll, orElse: () => albums.first);
    final count = await all.assetCountAsync;
    final videos = count > 0 ? await all.getAssetListRange(start: 0, end: count) : <AssetEntity>[];
    videos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    if (!mounted || videos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No videos available')));
      }
      return;
    }

    final selectedIds = await _showVideoPicker(videos);
    if (!mounted || selectedIds == null || selectedIds.isEmpty) return;

    final id = await _service.createPlaylist(name);
    var added = 0;
    for (final videoId in selectedIds) {
      if (await _service.addVideo(id, videoId)) added++;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playlist "$name" created with $added video${added == 1 ? '' : 's'}')),
    );
  }

  Future<Set<String>?> _showVideoPicker(List<AssetEntity> videos) async {
    final selected = <String>{};
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: AppColors.gray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * .72,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Choose videos for the playlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Text('Choose at least one video', style: TextStyle(color: Colors.white60)),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: .82,
                    ),
                    itemCount: videos.length,
                    itemBuilder: (_, index) {
                      final video = videos[index];
                      final isSelected = selected.contains(video.id);
                      return GestureDetector(
                        onTap: () => setSheetState(() {
                          if (!selected.add(video.id)) selected.remove(video.id);
                        }),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            VideoThumbnail(asset: video, width: double.infinity, height: double.infinity),
                            if (isSelected)
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
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isSelected ? AppColors.blue : Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selected.isEmpty ? null : () => Navigator.pop(sheetContext, selected),
                      child: Text(selected.isEmpty ? 'Select a video' : 'Add ${selected.length} video${selected.length == 1 ? '' : 's'}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _rename(VideoPlaylist playlist) async {
    final controller = TextEditingController(text: playlist.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('Rename playlist', style: TextStyle(color: Colors.white)),
        content: TextField(controller: controller, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (!mounted || name == null || name.isEmpty) return;
    await _service.renamePlaylist(playlist.id, name);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playlist renamed to "$name"')));
  }

  Future<void> _delete(VideoPlaylist playlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.gray,
        title: const Text('Delete playlist?', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${playlist.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _service.deletePlaylist(playlist.id);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playlist "${playlist.name}" deleted')));
  }

  void _showPlaylistMenu(VideoPlaylist playlist) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.gray,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppColors.blue),
              title: const Text('Rename', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(sheetContext); _rename(playlist); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Delete', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(sheetContext); _delete(playlist); },
            ),
          ],
        ),
      ),
    );
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
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          final playlists = snapshot.data ?? const <VideoPlaylist>[];
          if (playlists.isEmpty) return const Center(child: Text('No video playlists yet'));
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
                  subtitle: Text('${playlist.videoIds.length} videos', style: const TextStyle(color: Colors.white54)),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                    onPressed: () => _showPlaylistMenu(playlist),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => _VideoPlaylistDetails(playlist: playlist)),
                  ).then((_) => _reload()),
                  onLongPress: () => _showPlaylistMenu(playlist),
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

  void _showVideoMenu(AssetEntity asset) {
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
                Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(asset: asset)));
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
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(asset: asset))),
                onLongPress: () => _showVideoMenu(asset),
                child: Stack(
                  children: [
                    Positioned.fill(child: VideoThumbnail(asset: asset, width: double.infinity, height: double.infinity)),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IconButton(
                        onPressed: () => _showVideoMenu(asset),
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
