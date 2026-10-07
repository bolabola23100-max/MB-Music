import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/features/video/screens/video_player_screen.dart';
import 'package:music/features/video/screens/video_multi_select_screen.dart';
import 'package:music/features/video/services/video_library_service.dart';
import 'package:music/features/video/widgets/video_grid_card.dart';

class VideoSearchScreen extends StatefulWidget {
  const VideoSearchScreen({super.key});

  @override
  State<VideoSearchScreen> createState() => _VideoSearchScreenState();
}

class _VideoSearchScreenState extends State<VideoSearchScreen> {
  final _controller = TextEditingController();
  final _service = const VideoLibraryService();
  List<AssetEntity> _allVideos = const [];
  List<AssetEntity> _results = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await _service.getAllVideos();
      if (!mounted) return;
      setState(() {
        _allVideos = videos;
        _results = videos;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _search(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _results = query.isEmpty
          ? _allVideos
          : _allVideos.where((video) {
              final title = video.title?.toLowerCase() ?? '';
              return title.contains(query);
            }).toList();
    });
  }

  Future<void> _openMultiSelect() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoMultiSelectScreen(videos: List<AssetEntity>.from(_results)),
      ),
    );
    if (mounted) _loadVideos();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _controller,
            onChanged: _search,
            style: const TextStyle(color: Colors.white),
            cursorColor: AppColors.blue,
            decoration: InputDecoration(
              hintText: 'Search videos...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: _controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _controller.clear();
                        _search('');
                      },
                      icon: const Icon(Icons.clear, color: Colors.white),
                    ),
              filled: true,
              fillColor: AppColors.gray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? const Center(
                      child: Text(
                        'No videos found',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 110),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final asset = _results[index];
                        return VideoGridCard(
                          asset: asset,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(asset: asset),
                            ),
                          ),
                          onLongPress: _openMultiSelect,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
