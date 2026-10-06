import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';

class VideoPlayerScreen extends StatefulWidget {
  final AssetEntity asset;

  const VideoPlayerScreen({super.key, required this.asset});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  Future<void>? _loadFuture;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _loadFuture = _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      final file = await widget.asset.originFileWithSubtype;
      if (!mounted) return;

      if (file == null) {
        setState(() => _loadFailed = true);
        return;
      }

      await _player.open(Media(file.path));
    } catch (_) {
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: FutureBuilder<String>(
          future: widget.asset.titleAsync,
          builder: (context, snapshot) => Text(
            snapshot.data ?? 'Video',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: _loadFailed
          ? const Center(
              child: Text(
                'Unable to play this video',
                style: TextStyle(color: Colors.white),
              ),
            )
          : FutureBuilder<void>(
              future: _loadFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Unable to play this video',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Video(
                      controller: _videoController,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
