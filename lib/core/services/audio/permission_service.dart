import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestAudioPermissions() async {
    // Android 13+
    if (await Permission.audio.isGranted) return true;

    // Android 12 وأقل
    if (await Permission.storage.isGranted) return true;

    // اطلب الصلاحية
    final audio = await Permission.audio.request();
    if (audio.isGranted) return true;

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  static Future<bool> requestNotificationPermission() async {
    if (await Permission.notification.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }
}
