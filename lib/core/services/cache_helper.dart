import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences _prefs;

  /// يجب استدعاء هذه الدالة في الـ main قبل تشغيل التطبيق
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Onboarding ---
  static bool get onboardingSeen => _prefs.getBool('onboarding_seen') ?? false;
  static set onboardingSeen(bool value) => _prefs.setBool('onboarding_seen', value);

  // --- Language ---
  static String get languageCode => _prefs.getString('language_code') ?? 'en';
  static set languageCode(String value) => _prefs.setString('language_code', value);

  // --- Theme (مثال) ---
  static bool get isDarkMode => _prefs.getBool('is_dark_mode') ?? true;
  static set isDarkMode(bool value) => _prefs.setBool('is_dark_mode', value);

  // دالة عامة لمسح كل البيانات إذا لزم الأمر
  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}
