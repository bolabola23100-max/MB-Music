import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/video_player_manager.dart';
import '../widgets/video_player_controls.dart';
import '../widgets/video_player_progress.dart';
import '../widgets/video_player_settings.dart';
import '../widgets/video_gesture_indicator.dart';
import '../widgets/video_player_error.dart';

enum _GestureIndicatorSide { left, right }

class VideoPlayerScreen extends StatefulWidget {
  final AssetEntity asset;
  final List<AssetEntity>? videos;

  const VideoPlayerScreen({
    super.key,
    required this.asset,
    this.videos,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final VideoPlayerManager _manager;
  _GestureIndicatorSide? _gestureIndicatorSide;
  bool _isSpeedLongPressing = false;

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
      _manager.originalAspectRatio,
      (selection) => _manager.setAspectRatio(
        selection.ratio,
        selection.fit,
      ),
    );
    _manager.showControls();
  }

  List<AssetEntity> get _videos {
    final videos = widget.videos;
    if (videos == null || videos.isEmpty) return [widget.asset];
    return videos;
  }

  int get _currentVideoIndex =>
      _videos.indexWhere((video) => video.id == _manager.asset.id);

  Future<void> _playAdjacentVideo(int offset) async {
    final videos = _videos;
    final currentIndex = _currentVideoIndex;
    final nextIndex = currentIndex + offset;
    if (currentIndex < 0 || nextIndex < 0 || nextIndex >= videos.length) return;

    final nextAsset = videos[nextIndex];
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(
          key: ValueKey(nextAsset.id),
          asset: nextAsset,
          videos: videos,
        ),
      ),
    );
  }

  void _handleVerticalDragStart(DragStartDetails details, double width) {
    if (_manager.locked || _isSpeedLongPressing) return;
    setState(() {
      _gestureIndicatorSide = details.localPosition.dx < width / 2
          ? _GestureIndicatorSide.left
          : _GestureIndicatorSide.right;
    });
  }

  void _handleVerticalSwipe(DragUpdateDetails details, double width) {
    if (_manager.locked || _isSpeedLongPressing) return;

    final isRightHalf = details.localPosition.dx >= width / 2;
    final delta = -details.delta.dy;

    if (isRightHalf) {
      _manager.adjustVolume(delta * 0.5);
    } else {
      _manager.adjustBrightness(delta * 0.005);
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (!mounted) return;
    setState(() => _gestureIndicatorSide = null);
  }

  void _handleVerticalDragCancel() {
    if (!mounted) return;
    setState(() => _gestureIndicatorSide = null);
  }

  Future<void> _handleLongPressStart(
    LongPressStartDetails details,
    double width,
  ) async {
    if (_manager.locked) return;

    setState(() {
      _isSpeedLongPressing = true;
      _gestureIndicatorSide = null;
    });
    await _manager.setPlaybackRate(2.0);
  }

  Future<void> _handleLongPressEnd(LongPressEndDetails details) async {
    await _manager.setPlaybackRate(1.0);
    if (!mounted) return;
    setState(() {
      _isSpeedLongPressing = false;
      _gestureIndicatorSide = null;
    });
  }

  void _handleLongPressCancel() {
    _manager.setPlaybackRate(1.0);
    if (!mounted) return;
    setState(() {
      _isSpeedLongPressing = false;
      _gestureIndicatorSide = null;
    });
  }

  Widget _buildGestureIndicator() {
    final isVolume = _gestureIndicatorSide == _GestureIndicatorSide.right;
    final value = isVolume
        ? (playerVolume / 100).clamp(0.0, 1.0)
        : ((_manager.brightness - 0.05) / 0.95).clamp(0.0, 1.0);

    return VideoGestureIndicator(isVolume: isVolume, value: value);
  }

  Widget _buildSpeedIndicator() {
    return IgnorePointer(
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 90),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: const Text(
            'Speed 2x',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  double get playerVolume => _manager.player.state.volume;

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
              ? const VideoPlayerError()
              : FutureBuilder<void>(
                  future: _manager.loadFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return const VideoPlayerError();
                    return _buildPlayer();
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final width = MediaQuery.sizeOf(context).width;
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _manager.toggleControls,
          onLongPressStart: (details) =>
              _handleLongPressStart(details, width),
          onLongPressEnd: _handleLongPressEnd,
          onLongPressCancel: _handleLongPressCancel,
          onVerticalDragStart: (details) =>
              _handleVerticalDragStart(details, width),
          onVerticalDragUpdate: (details) =>
              _handleVerticalSwipe(details, width),
          onVerticalDragEnd: _handleVerticalDragEnd,
          onVerticalDragCancel: _handleVerticalDragCancel,
          child: Video(
            controller: _manager.videoController,
            controls: NoVideoControls,
            fit: _manager.videoFit,
            aspectRatio: _manager.aspectRatio,
            fill: Colors.black,
            wakelock: true,
          ),
        ),
        if (_isSpeedLongPressing)
          _buildSpeedIndicator()
        else if (_gestureIndicatorSide != null)
          _buildGestureIndicator(),
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
            onPrevious: _currentVideoIndex > 0
                ? () => _playAdjacentVideo(-1)
                : null,
            onNext: _currentVideoIndex >= 0 &&
                    _currentVideoIndex < _videos.length - 1
                ? () => _playAdjacentVideo(1)
                : null,
          ),
      ],
    );
  }
}
