import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/features/video/screens/video_player_screen.dart';
import 'package:music/features/video/screens/video_multi_select_screen.dart';
import 'package:music/core/services/video/video_favorites_service.dart';
import 'package:music/features/video/widgets/video_grid_card.dart';

class VideoFavoritesScreen extends StatefulWidget {
  const VideoFavoritesScreen({super.key});

  @override
  State<VideoFavoritesScreen> createState() => _VideoFavoritesScreenState();
}

class _VideoFavoritesScreenState extends State<VideoFavoritesScreen> {
  final _favorites = VideoFavoritesService();
  late Future<List<AssetEntity>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _favorites.favoriteIdsNotifier.addListener(_onFavoritesChanged);
    _load();
  }

  @override
  void dispose() {
    _favorites.favoriteIdsNotifier.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (!mounted) return;
    setState(_load);
  }

  void _load() {
    _videosFuture = _getVideos();
  }

  Future<List<AssetEntity>> _getVideos() async {
    await _favorites.loadFavorites();
    final ids = _favorites.favoriteIdsNotifier.value.toList();
    final videos = <AssetEntity>[];

    for (final id in ids) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null && await asset.exists) videos.add(asset);
    }

    videos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    return videos;
  }

  Future<void> _refresh() async {
    setState(_load);
    await _videosFuture;
  }

  Future<void> _openMultiSelect(List<AssetEntity> videos) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoMultiSelectScreen(videos: videos)),
    );
    if (mounted) setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AssetEntity>>(
      future: _videosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final videos = snapshot.data ?? const <AssetEntity>[];
        if (videos.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 180),
                Icon(Icons.favorite_border_rounded, size: 64),
                SizedBox(height: 14),
                Center(child: Text('No favorite videos yet')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final asset = videos[index];
              return VideoGridCard(
                asset: asset,
                showFavoriteIcon: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(asset: asset, videos: videos),
                  ),
                ).then((_) {
                  if (mounted) setState(_load);
                }),
                onLongPress: () => _openMultiSelect(videos),
              );
            },
          ),
        );
      },
    );
  }
}
