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
      print('⚠️ AppVersionService Error: $e');
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
      print('⚠️ saveCurrentVersion Error: $e');
    }
  }
}
