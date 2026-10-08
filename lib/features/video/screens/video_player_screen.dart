import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/video_player_manager.dart';
import '../widgets/video_player_controls.dart';
import '../widgets/video_player_progress.dart';
import '../widgets/video_player_settings.dart';

class VideoPlayerScreen extends StatefulWidget {
  final AssetEntity asset;

  const VideoPlayerScreen({super.key, required this.asset});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = VideoPlayerManager(widget.asset);
    _manager.initialize();
  }

  Future<void> _showSpeed() async {
    _manager.showControls();
    await VideoPlayerSettings.showSpeed(context, _manager.player);
    _manager.showControls();
  }

  Future<void> _showAspect() async {
    _manager.showControls();
    await VideoPlayerSettings.showAspect(
      context,
      _manager.aspectRatio,
      _manager.videoFit,
      (selection) => _manager.setAspectRatio(
        selection.ratio,
        selection.fit,
      ),
    );
    _manager.showControls();
  }

  void _handleVerticalSwipe(DragUpdateDetails details, double width) {
    if (_manager.locked) return;

    final isRightHalf = details.localPosition.dx >= width / 2;
    final delta = -details.delta.dy;

    if (isRightHalf) {
      _manager.adjustVolume(delta * 0.5);
    } else {
      _manager.adjustBrightness(delta * 0.005);
    }
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _manager,
      builder: (context, _) => PopScope(
        onPopInvokedWithResult: (_, _) => _manager.resetSystemUi(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _manager.loadFailed
              ? const _VideoError()
              : FutureBuilder<void>(
                  future: _manager.loadFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const _VideoError();
                    return _buildPlayer();
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _manager.toggleControls,
          onVerticalDragUpdate: (details) => _handleVerticalSwipe(
            details,
            MediaQuery.sizeOf(context).width,
          ),
          child: Video(
            controller: _manager.videoController,
            controls: NoVideoControls,
            fit: _manager.videoFit,
            aspectRatio: _manager.aspectRatio,
            fill: Colors.black,
            wakelock: true,
          ),
        ),
        if (_manager.locked)
          VideoPlayerProgress(
            player: _manager.player,
            fullscreen: _manager.fullscreen,
            locked: true,
            onFullscreen: _manager.toggleFullscreen,
            onLock: _manager.unlockPlayer,
            onSeek: _manager.seekBy,
          )
        else if (_manager.controlsVisible)
          VideoPlayerControls(
            asset: _manager.asset,
            player: _manager.player,
            fullscreen: _manager.fullscreen,
            onBack: () => Navigator.of(context).pop(),
            onSpeed: _showSpeed,
            onAspect: _showAspect,
            onLock: _manager.lockPlayer,
            onFullscreen: _manager.toggleFullscreen,
            onSeek: _manager.seekBy,
          ),
      ],
    );
  }
}

class _VideoError extends StatelessWidget {
  const _VideoError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Unable to play this video',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
