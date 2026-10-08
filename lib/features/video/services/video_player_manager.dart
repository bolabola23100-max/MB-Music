import 'dart:async';

import 'package:flutter/foundation.dart';
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
  bool loadFailed = false;
  bool controlsVisible = true;
  bool locked = false;
  bool fullscreen = true;
  double brightness = 1.0;
  BoxFit videoFit = BoxFit.contain;
  double? aspectRatio;

  VideoPlayerManager(this.asset) {
    player = Player();
    videoController = VideoController(player);
  }

  Future<void> initialize() async {
    loadFuture = _loadVideo();
    _enterFullscreen();
    _loadBrightness();
    _scheduleControlsHide();
    notifyListeners();
  }

  Future<void> _loadVideo() async {
    try {
      final file = await asset.originFileWithSubtype;
      if (file == null) {
        loadFailed = true;
        notifyListeners();
        return;
      }
      await player.open(Media(file.path));
    } catch (_) {
      loadFailed = true;
      notifyListeners();
    }
  }

  Future<void> _loadBrightness() async {
    try {
      final value = await ScreenBrightness.instance.application;
      brightness = value.clamp(0.05, 1.0);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _enterFullscreen() async {
    fullscreen = true;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    notifyListeners();
  }

  Future<void> _exitFullscreen() async {
    fullscreen = false;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    notifyListeners();
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
      notifyListeners();
    });
  }

  void showControls() {
    controlsVisible = true;
    notifyListeners();
    _scheduleControlsHide();
  }

  void toggleControls() {
    if (locked) {
      unlockPlayer();
      return;
    }
    controlsVisible = !controlsVisible;
    if (controlsVisible) {
      _scheduleControlsHide();
    } else {
      _hideControlsTimer?.cancel();
    }
    notifyListeners();
  }

  void lockPlayer() {
    _hideControlsTimer?.cancel();
    locked = true;
    controlsVisible = false;
    notifyListeners();
  }

  void unlockPlayer() {
    locked = false;
    controlsVisible = true;
    notifyListeners();
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
    showControls();
  }

  Future<void> setBrightness(double value) async {
    brightness = value.clamp(0.05, 1.0).toDouble();
    notifyListeners();
    try {
      await ScreenBrightness.instance
          .setApplicationScreenBrightness(brightness);
    } catch (_) {}
  }

  void setAspectRatio(double? ratio, BoxFit fit) {
    aspectRatio = ratio;
    videoFit = fit;
    notifyListeners();
  }

  void resetSystemUi() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    player.dispose();
    ScreenBrightness.instance.resetApplicationScreenBrightness();
    resetSystemUi();
    super.dispose();
  }
}
