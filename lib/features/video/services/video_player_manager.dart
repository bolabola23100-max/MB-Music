import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:screen_brightness/screen_brightness.dart';

class VideoPlayerManager extends ChangeNotifier {
  final AssetEntity asset;
  late final Player player;
  late final VideoController videoController;

  Timer? _hideControlsTimer;
  Future<void>? loadFuture;
  bool _disposed = false;

  bool loadFailed = false;
  bool controlsVisible = true;
  bool locked = false;
  bool fullscreen = false;
  double brightness = 1.0;
  BoxFit videoFit = BoxFit.contain;
  double? aspectRatio;

  VideoPlayerManager(this.asset) {
    player = Player();
    videoController = VideoController(player);
  }

  void initialize() {
    loadFuture = _loadVideo();
    unawaited(_setPortraitMode());
    unawaited(_loadBrightness());
    _scheduleControlsHide();
    _notify();
  }

  Future<void> _loadVideo() async {
    try {
      final file = await asset.originFileWithSubtype;
      if (file == null) {
        loadFailed = true;
        _notify();
        return;
      }
      await player.open(Media(file.path));
    } catch (_) {
      loadFailed = true;
      _notify();
    }
  }

  Future<void> _loadBrightness() async {
    try {
      final value = await ScreenBrightness.instance.application;
      brightness = value.clamp(0.05, 1.0);
      _notify();
    } catch (_) {}
  }

  Future<void> _setPortraitMode() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _enterFullscreen() async {
    fullscreen = true;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _notify();
  }

  Future<void> _exitFullscreen() async {
    fullscreen = false;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _notify();
  }

  Future<void> toggleFullscreen() async {
    if (fullscreen) {
      await _exitFullscreen();
    } else {
      await _enterFullscreen();
    }
    showControls();
  }

  void _scheduleControlsHide() {
    _hideControlsTimer?.cancel();
    if (!controlsVisible || locked) return;
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      controlsVisible = false;
      _notify();
    });
  }

  void showControls() {
    if (locked) return;
    controlsVisible = true;
    _notify();
    _scheduleControlsHide();
  }

  void toggleControls() {
    if (locked) return;
    controlsVisible = !controlsVisible;
    if (controlsVisible) {
      _scheduleControlsHide();
    } else {
      _hideControlsTimer?.cancel();
    }
    _notify();
  }

  void lockPlayer() {
    _hideControlsTimer?.cancel();
    locked = true;
    controlsVisible = false;
    _notify();
  }

  void unlockPlayer() {
    locked = false;
    controlsVisible = true;
    _notify();
    _scheduleControlsHide();
  }

  Future<void> seekBy(int seconds) async {
    final current = player.state.position;
    final duration = player.state.duration;
    final target = current + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > duration
            ? duration
            : target;
    await player.seek(clamped);
    if (!locked) showControls();
  }

  Future<void> adjustVolume(double delta) async {
    if (locked) return;
    final next = (player.state.volume + delta).clamp(0.0, 100.0).toDouble();
    await player.setVolume(next);
  }

  Future<void> setBrightness(double value) async {
    brightness = value.clamp(0.05, 1.0).toDouble();
    _notify();
    try {
      await ScreenBrightness.instance
          .setApplicationScreenBrightness(brightness);
    } catch (_) {}
  }

  Future<void> adjustBrightness(double delta) async {
    if (locked) return;
    await setBrightness(brightness + delta);
  }

  void setAspectRatio(double? ratio, BoxFit fit) {
    aspectRatio = ratio;
    videoFit = fit;
    _notify();
  }

  void resetSystemUi() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]));
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _hideControlsTimer?.cancel();
    player.dispose();
    unawaited(ScreenBrightness.instance.resetApplicationScreenBrightness());
    resetSystemUi();
    super.dispose();
  }
}
