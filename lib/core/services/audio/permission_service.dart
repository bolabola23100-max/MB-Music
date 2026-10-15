import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool>? _audioPermissionRequest;
  static Future<bool>? _notificationPermissionRequest;

  static Future<bool> requestAudioPermissions() {
    final pending = _audioPermissionRequest;
    if (pending != null) return pending;

    late final Future<bool> tracked;
    tracked = _requestAudioPermissions().whenComplete(() {
      if (identical(_audioPermissionRequest, tracked)) {
        _audioPermissionRequest = null;
      }
    });
    _audioPermissionRequest = tracked;
    return tracked;
  }

  static Future<bool> _requestAudioPermissions() async {
    // Android 13+
    if (await Permission.audio.isGranted) return true;

    // Android 12 and below
    if (await Permission.storage.isGranted) return true;

    final audio = await Permission.audio.request();
    if (audio.isGranted) return true;

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  static Future<bool> requestNotificationPermission() {
    final pending = _notificationPermissionRequest;
    if (pending != null) return pending;

    late final Future<bool> tracked;
    tracked = _requestNotificationPermission().whenComplete(() {
      if (identical(_notificationPermissionRequest, tracked)) {
        _notificationPermissionRequest = null;
      }
    });
    _notificationPermissionRequest = tracked;
    return tracked;
  }

  static Future<bool> _requestNotificationPermission() async {
    if (await Permission.notification.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }
}
