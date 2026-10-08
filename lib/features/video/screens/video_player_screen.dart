import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../widgets/video_player_button.dart';
import '../widgets/video_player_controls.dart';
import '../widgets/video_player_settings.dart';

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
  Timer? _hideControlsTimer;

  bool _loadFailed = false;
  bool _controlsVisible = true;
  bool _locked = false;
  bool _isFullscreen = true;
  double _brightness = 1.0;
  BoxFit _videoFit = BoxFit.contain;
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _loadFuture = _loadVideo();
    _enterFullscreen();
    _loadBrightness();
    _scheduleControlsHide();
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
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _loadBrightness() async {
    try {
      final value = await ScreenBrightness.instance.application;
      if (mounted) setState(() => _brightness = value.clamp(0.05, 1.0));
    } catch (_) {}
  }

  Future<void> _enterFullscreen() async {
    _isFullscreen = true;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _exitFullscreen() async {
    _isFullscreen = false;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _toggleFullscreen() async {
    if (_isFullscreen) {
      await _exitFullscreen();
    } else {
      await _enterFullscreen();
    }
    if (mounted) setState(() {});
    _showControls();
  }

  void _scheduleControlsHide() {
    _hideControlsTimer?.cancel();
    if (!_controlsVisible || _locked) return;
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _showControls() {
    if (!mounted) return;
    setState(() => _controlsVisible = true);
    _scheduleControlsHide();
  }

  void _toggleControls() {
    if (_locked) {
      _unlockPlayer();
      return;
    }
    if (_controlsVisible) {
      setState(() => _controlsVisible = false);
      _hideControlsTimer?.cancel();
    } else {
      _showControls();
    }
  }

  void _lockPlayer() {
    _hideControlsTimer?.cancel();
    setState(() {
      _locked = true;
      _controlsVisible = false;
    });
  }

  void _unlockPlayer() {
    setState(() {
      _locked = false;
      _controlsVisible = true;
    });
    _scheduleControlsHide();
  }

  Future<void> _seekBy(int seconds) async {
    final current = _player.state.position;
    final duration = _player.state.duration;
    final target = current + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > duration
            ? duration
            : target;
    await _player.seek(clamped);
    _showControls();
  }

  Future<void> _setBrightness(double value) async {
    final next = value.clamp(0.05, 1.0).toDouble();
    setState(() => _brightness = next);
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(next);
    } catch (_) {}
  }

  Future<void> _showVolume() async {
    _showControls();
    await VideoPlayerSettings.showVolume(context, _player, _showControls);
    _scheduleControlsHide();
  }

  Future<void> _showBrightness() async {
    _showControls();
    await VideoPlayerSettings.showBrightness(
      context,
      _brightness,
      _setBrightness,
    );
    _scheduleControlsHide();
  }

  Future<void> _showSpeed() async {
    _showControls();
    await VideoPlayerSettings.showSpeed(context, _player);
    _scheduleControlsHide();
  }

  Future<void> _showAspect() async {
    _showControls();
    await VideoPlayerSettings.showAspect(
      context,
      _aspectRatio,
      _videoFit,
      (selection) => setState(() {
        _aspectRatio = selection.ratio;
        _videoFit = selection.fit;
      }),
    );
    _scheduleControlsHide();
  }

  void _resetSystemUi() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _player.dispose();
    ScreenBrightness.instance.resetApplicationScreenBrightness();
    _resetSystemUi();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) => _resetSystemUi(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _loadFailed
            ? const _VideoError()
            : FutureBuilder<void>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const _VideoError();
                  return _buildPlayer();
                },
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
          onTap: _toggleControls,
          onDoubleTap: _player.playOrPause,
          onDoubleTapDown: (details) {
            final width = MediaQuery.sizeOf(context).width;
            _seekBy(details.localPosition.dx < width / 2 ? -10 : 10);
          },
          child: Video(
            controller: _videoController,
            controls: NoVideoControls,
            fit: _videoFit,
            aspectRatio: _aspectRatio,
            fill: Colors.black,
            wakelock: true,
          ),
        ),
        if (_locked)
          Positioned(
            right: 18,
            top: 18,
            child: VideoPlayerButton(
              icon: Icons.lock_rounded,
              onTap: _unlockPlayer,
            ),
          )
        else if (_controlsVisible)
          VideoPlayerControls(
            asset: widget.asset,
            player: _player,
            fullscreen: _isFullscreen,
            onBack: () => Navigator.of(context).pop(),
            onBrightness: _showBrightness,
            onVolume: _showVolume,
            onSpeed: _showSpeed,
            onAspect: _showAspect,
            onLock: _lockPlayer,
            onFullscreen: _toggleFullscreen,
            onSeek: _seekBy,
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
