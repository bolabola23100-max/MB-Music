import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final AssetEntity asset;

  const VideoPlayerScreen({super.key, required this.asset});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  bool _isFullscreen = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      final file = await widget.asset.originFileWithSubtype;
      if (!mounted) return;
      if (file == null) {
        setState(() => _loadFailed = true);
        return;
      }

      final controller = VideoPlayerController.file(file);
      _controller = controller;
      _initializeFuture = controller.initialize();
      setState(() {});

      await _initializeFuture;
      if (!mounted) return;
      await controller.setLooping(false);
      await controller.play();
      setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    }
  }

  Future<void> _toggleFullscreen() async {
    final next = !_isFullscreen;
    setState(() => _isFullscreen = next);

    if (next) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _isFullscreen
          ? null
          : AppBar(
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
                'Unable to load this video',
                style: TextStyle(color: Colors.white),
              ),
            )
          : controller == null || _initializeFuture == null
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<void>(
                  future: _initializeFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Unable to play this video',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    if (snapshot.connectionState != ConnectionState.done ||
                        !controller.value.isInitialized) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Center(
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          AspectRatio(
                            aspectRatio: controller.value.aspectRatio > 0
                                ? controller.value.aspectRatio
                                : 16 / 9,
                            child: VideoPlayer(controller),
                          ),
                          _Controls(
                            controller: controller,
                            isFullscreen: _isFullscreen,
                            onFullscreen: _toggleFullscreen,
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class _Controls extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isFullscreen;
  final VoidCallback onFullscreen;

  const _Controls({
    required this.controller,
    required this.isFullscreen,
    required this.onFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            padding: EdgeInsets.zero,
          ),
          Row(
            children: [
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, child) => IconButton(
                  color: Colors.white,
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  onPressed: value.isPlaying
                      ? controller.pause
                      : controller.play,
                ),
              ),
              const Spacer(),
              IconButton(
                color: Colors.white,
                icon: Icon(
                  isFullscreen
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                ),
                onPressed: onFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
