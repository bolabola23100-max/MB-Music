import 'dart:developer' as developer;

import 'package:package_info_plus/package_info_plus.dart';
import 'package:music/core/services/cache_helper.dart';

class AppVersionService {
  Future<bool> isNewVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final currentVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      final savedVersion = CacheHelper.appVersion;

      // أول تشغيل للتطبيق
      if (savedVersion.isEmpty) {
        await saveCurrentVersion();
        return false;
      }

      return currentVersion != savedVersion;
    } catch (e) {
      developer.log('AppVersionService Error: $e', name: 'AppVersionService');
      return false;
    }
  }

  Future<void> saveCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final currentVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      CacheHelper.appVersion = currentVersion;
    } catch (e) {
      developer.log('saveCurrentVersion Error: $e', name: 'AppVersionService');
    }
  }
}
