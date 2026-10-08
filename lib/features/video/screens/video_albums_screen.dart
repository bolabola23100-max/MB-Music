import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/video_library_service.dart';
import '../widgets/video_thumbnail.dart';
import '../widgets/video_album_video_card.dart';
import 'video_multi_select_screen.dart';

class VideoAlbumsScreen extends StatefulWidget {
  final VideoLibraryService service;
  final bool showAllVideos;
  const VideoAlbumsScreen({super.key, required this.service, this.showAllVideos = false});
  @override State<VideoAlbumsScreen> createState() => _VideoAlbumsScreenState();
}

class _VideoAlbumsScreenState extends State<VideoAlbumsScreen> {
  late Future<List<AssetPathEntity>> _albumsFuture;
  @override void initState() { super.initState(); _albumsFuture = widget.service.getVideoAlbums(); }
  void _refresh() => setState(() => _albumsFuture = widget.service.getVideoAlbums());

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async => _refresh(),
    child: FutureBuilder<List<AssetPathEntity>>(
      future: _albumsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return _Message(icon: Icons.error_outline, text: 'Could not load videos', onRetry: _refresh);
        final albums = snapshot.data ?? const <AssetPathEntity>[];
        if (albums.isEmpty) return const _Message(icon: Icons.video_library_outlined, text: 'No videos found on this device');
        if (widget.showAllVideos) {
          return _AllVideos(service: widget.service);
        }
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
          itemCount: albums.length,
          itemBuilder: (context, index) => _AlbumTile(album: albums[index], service: widget.service),
        );
      },
    ),
  );
}

class _AllVideos extends StatefulWidget {
  final VideoLibraryService service;
  const _AllVideos({required this.service});
  @override State<_AllVideos> createState() => _AllVideosState();
}

class _AllVideosState extends State<_AllVideos> {
  late Future<List<AssetEntity>> _videosFuture;
  @override void initState() { super.initState(); _videosFuture = widget.service.getAllVideos(); }
  Future<void> _refresh() async { setState(() => _videosFuture = widget.service.getAllVideos()); await _videosFuture; }
  Future<void> _select(List<AssetEntity> videos) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoMultiSelectScreen(videos: videos)));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<AssetEntity>>(
    future: _videosFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _Message(icon: Icons.error_outline, text: 'Could not load videos', onRetry: _refresh);
      final videos = snapshot.data ?? const <AssetEntity>[];
      if (videos.isEmpty) return const _Message(icon: Icons.video_library_outlined, text: 'No videos found on this device');
      return RefreshIndicator(
        onRefresh: _refresh,
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.78),
          itemCount: videos.length,
          itemBuilder: (context, index) => VideoAlbumVideoCard(
            asset: videos[index],
            videos: videos,
            onLongPress: () => _select(videos),
          ),
        ),
      );
    },
  );
}

class _AlbumTile extends StatelessWidget {
  final AssetPathEntity album; final VideoLibraryService service;
  const _AlbumTile({required this.album, required this.service});
  @override
  Widget build(BuildContext context) => FutureBuilder<int>(
    future: album.assetCountAsync,
    builder: (context, snapshot) => Card(color: Colors.white10, elevation: 0, child: ListTile(
      leading: FutureBuilder<List<AssetEntity>>(future: service.getAlbumVideos(album, pageSize: 1), builder: (context, snapshot) {
        final first = snapshot.data?.isNotEmpty == true ? snapshot.data!.first : null;
        return first == null ? const SizedBox(width: 58, height: 58, child: Icon(Icons.video_library_outlined)) : VideoThumbnail(asset: first, width: 58, height: 58, borderRadius: const BorderRadius.all(Radius.circular(10)));
      }),
      title: Text(album.name.isEmpty ? 'Videos' : album.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${snapshot.data ?? 0} videos'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _AlbumVideosPage(album: album, service: service))),
    )),
  );
}

class _AlbumVideosPage extends StatelessWidget {
  final AssetPathEntity album; final VideoLibraryService service;
  const _AlbumVideosPage({required this.album, required this.service});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(album.name)),
    body: FutureBuilder<List<AssetEntity>>(
      future: service.getAlbumVideos(album),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        final videos = snapshot.data ?? const <AssetEntity>[];
        if (videos.isEmpty) return const _Message(icon: Icons.video_library_outlined, text: 'No videos in this album');
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.78),
          itemCount: videos.length,
          itemBuilder: (context, index) => VideoAlbumVideoCard(
            asset: videos[index],
            videos: videos,
            onLongPress: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VideoMultiSelectScreen(videos: videos)),
            ),
          ),
        );
      },
    ),
  );
}

class _Message extends StatelessWidget {
  final IconData icon; final String text; final VoidCallback? onRetry;
  const _Message({required this.icon, required this.text, this.onRetry});
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 48), const SizedBox(height: 12), Text(text), if (onRetry != null) ...[const SizedBox(height: 12), OutlinedButton(onPressed: onRetry, child: const Text('Retry'))]]));
}
