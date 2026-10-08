import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:screen_brightness/screen_brightness.dart';

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
      if (mounted) {
        setState(() => _loadFailed = true);
      }
    }
  }

  Future<void> _loadBrightness() async {
    try {
      final value = await ScreenBrightness.instance.application;
      if (mounted) {
        setState(() => _brightness = value.clamp(0.05, 1.0));
      }
    } catch (_) {
      // Keep the default value if the device does not expose brightness.
    }
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
        : (target > duration ? duration : target);
    await _player.seek(clamped);
    _showControls();
  }

  Future<void> _setBrightness(double value) async {
    final next = value.clamp(0.05, 1.0).toDouble();
    setState(() => _brightness = next);
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(next);
    } catch (_) {
      // Ignore unsupported brightness changes without breaking playback.
    }
  }

  Future<void> _showVolumeSheet() async {
    _showControls();
    var value = _player.state.volume.clamp(0.0, 100.0).toDouble();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.volume_up_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Volume',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Slider(
                value: value,
                min: 0,
                max: 100,
                onChanged: (next) {
                  setSheetState(() => value = next);
                  _player.setVolume(next);
                },
              ),
              Text(
                '${value.round()}%',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
    _scheduleControlsHide();
  }

  Future<void> _showBrightnessSheet() async {
    _showControls();
    var value = _brightness;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.brightness_6_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Brightness',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Slider(
                value: value,
                min: 0.05,
                max: 1,
                onChanged: (next) {
                  setSheetState(() => value = next);
                  _setBrightness(next);
                },
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
    _scheduleControlsHide();
  }

  Future<void> _showSpeedSheet() async {
    _showControls();
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final current = _player.state.rate;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Playback speed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...speeds.map(
                (speed) => ListTile(
                  leading: Icon(
                    speed == current
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: Colors.white,
                  ),
                  title: Text(
                    speed == 1.0 ? 'Normal' : '${speed}x',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    await _player.setRate(speed);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    _scheduleControlsHide();
  }

  Future<void> _showAspectSheet() async {
    _showControls();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171717),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Aspect ratio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            _aspectOption('Original', null, BoxFit.contain),
            _aspectOption('16:9', 16 / 9, BoxFit.contain),
            _aspectOption('4:3', 4 / 3, BoxFit.contain),
            _aspectOption('Fill screen', null, BoxFit.cover),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    _scheduleControlsHide();
  }

  Widget _aspectOption(String label, double? ratio, BoxFit fit) {
    final selected = _aspectRatio == ratio && _videoFit == fit;
    return ListTile(
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
        color: Colors.white,
      ),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        setState(() {
          _aspectRatio = ratio;
          _videoFit = fit;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _player.dispose();
    ScreenBrightness.instance.resetApplicationScreenBrightness();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
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

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleControls,
                        onDoubleTap: () => _player.playOrPause(),
                        onDoubleTapDown: (details) {
                          final width = MediaQuery.sizeOf(context).width;
                          if (details.localPosition.dx < width / 2) {
                            _seekBy(-10);
                          } else {
                            _seekBy(10);
                          }
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
                          child: _CircleButton(
                            icon: Icons.lock_rounded,
                            onTap: _unlockPlayer,
                          ),
                        )
                      else if (_controlsVisible)
                        _buildControls(),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.62),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0, 0.52, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _CircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<String>(
                    future: widget.asset.titleAsync,
                    builder: (context, snapshot) => Text(
                      snapshot.data ?? 'Video',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _CircleButton(
                  icon: Icons.speed_rounded,
                  onTap: _showSpeedSheet,
                ),
                const SizedBox(width: 8),
                _CircleButton(
                  icon: Icons.aspect_ratio_rounded,
                  onTap: _showAspectSheet,
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: _CircleButton(
                icon: Icons.brightness_6_rounded,
                onTap: _showBrightnessSheet,
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: _CircleButton(
                icon: _player.state.volume <= 0
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                onTap: _showVolumeSheet,
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CircleButton(
                    icon: Icons.replay_10_rounded,
                    size: 58,
                    onTap: () => _seekBy(-10),
                  ),
                  const SizedBox(width: 26),
                  StreamBuilder<bool>(
                    stream: _player.stream.playing,
                    initialData: _player.state.playing,
                    builder: (context, snapshot) => _CircleButton(
                      icon: snapshot.data == true
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 76,
                      iconSize: 42,
                      filled: true,
                      onTap: () => _player.playOrPause(),
                    ),
                  ),
                  const SizedBox(width: 26),
                  _CircleButton(
                    icon: Icons.forward_10_rounded,
                    size: 58,
                    onTap: () => _seekBy(10),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 12,
            child: StreamBuilder<Duration>(
              stream: _player.stream.position,
              initialData: _player.state.position,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: _player.stream.duration,
                  initialData: _player.state.duration,
                  builder: (context, durationSnapshot) {
                    final duration = durationSnapshot.data ?? Duration.zero;
                    final max = duration.inMilliseconds.toDouble();
                    final value = max <= 0
                        ? 0.0
                        : position.inMilliseconds
                            .clamp(0, duration.inMilliseconds)
                            .toDouble();

                    return Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            activeTrackColor: const Color(0xFFE91E63),
                            thumbColor: Colors.white,
                            inactiveTrackColor: Colors.white38,
                            overlayColor: Colors.white24,
                          ),
                          child: Slider(
                            min: 0,
                            max: max > 0 ? max : 1,
                            value: max > 0 ? value : 0,
                            onChanged: max <= 0
                                ? null
                                : (next) => _player.seek(
                                      Duration(milliseconds: next.round()),
                                    ),
                          ),
                        ),
                        Row(
                          children: [
                            _CircleButton(
                              icon: _isFullscreen
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                              onTap: _toggleFullscreen,
                            ),
                            const Spacer(),
                            _CircleButton(
                              icon: Icons.lock_outline_rounded,
                              onTap: _lockPlayer,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final bool filled;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 46,
    this.iconSize = 25,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white.withValues(alpha: 0.95) : Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: filled ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
