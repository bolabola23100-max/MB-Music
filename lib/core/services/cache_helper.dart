import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences _prefs;

  static String reviewActionCountKey = 'review_action_count';
  static String appVersionKey = 'app_version';
  static const String equalizerEnabledKey = 'equalizer_enabled';
  static const String equalizerGainsKey = 'equalizer_gains';
  static const String notificationMessageIndexKey = 'notification_message_index';


  /// يجب استدعاء هذه الدالة في main قبل تشغيل التطبيق
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // =========================================================
  // ONBOARDING
  // =========================================================

  static bool get onboardingSeen => _prefs.getBool('onboarding_seen') ?? false;

  static set onboardingSeen(bool value) =>
      _prefs.setBool('onboarding_seen', value);


  // =========================================================
  // PLAYER THEME STYLE
  // =========================================================

  static int get playerThemeStyle => _prefs.getInt('player_theme_style') ?? 1;

  static set playerThemeStyle(int value) =>
      _prefs.setInt('player_theme_style', value);

  // =========================================================
  // LANGUAGE
  // =========================================================

  static String get languageCode => _prefs.getString('language_code') ?? 'en';

  static set languageCode(String value) =>
      _prefs.setString('language_code', value);

  // =========================================================
  // THEME
  // =========================================================

  static bool get isDarkMode => _prefs.getBool('is_dark_mode') ?? true;

  static set isDarkMode(bool value) => _prefs.setBool('is_dark_mode', value);

  // =========================================================
  // REVIEW
  // =========================================================

  static int get reviewActionCount => _prefs.getInt(reviewActionCountKey) ?? 0;

  static set reviewActionCount(int value) =>
      _prefs.setInt(reviewActionCountKey, value);

  // =========================================================
  // APP VERSION
  // =========================================================

  static String get appVersion => _prefs.getString(appVersionKey) ?? '';

  static set appVersion(String value) => _prefs.setString(appVersionKey, value);

  // =========================================================
  // PLAYBACK MODE
  // =========================================================

  static const String playbackModeKey = 'playback_mode';

  /// 0 = sequential
  /// 1 = repeatOne
  /// 2 = shuffle

  static int get playbackMode => _prefs.getInt(playbackModeKey) ?? 0;

  static set playbackMode(int value) => _prefs.setInt(playbackModeKey, value);

  // =========================================================
  // SHUFFLE ORDER
  // =========================================================

  static const String shuffledSongIdsKey = 'shuffled_song_ids';

  /// IDs بالترتيب الذي تم عمل Shuffle له
  static List<String> get shuffledSongIds =>
      _prefs.getStringList(shuffledSongIdsKey) ?? [];

  static set shuffledSongIds(List<String> value) =>
      _prefs.setStringList(shuffledSongIdsKey, value);

  /// مسح ترتيب الـ Shuffle
  static Future<void> clearShuffleOrder() async {
    await _prefs.remove(shuffledSongIdsKey);
  }



  static bool get equalizerEnabled => _prefs.getBool(equalizerEnabledKey) ?? true;

  static set equalizerEnabled(bool value) => _prefs.setBool(equalizerEnabledKey, value);

  static List<double> get equalizerGains =>
      (_prefs.getStringList(equalizerGainsKey) ?? []).map(double.parse).toList();

  static set equalizerGains(List<double> value) =>
      _prefs.setStringList(equalizerGainsKey, value.map((e) => e.toString()).toList());

  // =========================================================
  // NOTIFICATIONS

  static int get notificationMessageIndex =>
      _prefs.getInt(notificationMessageIndexKey) ?? 0;

  static set notificationMessageIndex(int value) =>
      _prefs.setInt(notificationMessageIndexKey, value);

  // =========================================================
  // CLEAR ALL
  // =========================================================

  static Future<void> clearAll() async {
    await _prefs.clear();
  }
}
